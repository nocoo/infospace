#if DEBUG
import AppKit
import InfoSpaceCore

/// Opt-in checks drive this process's own window. They are not system Accessibility E2E tests.
@MainActor
enum WindowInspection {
    static let isEnabled = ProcessInfo.processInfo.arguments.contains { argument in
        argument.hasPrefix("--inspect=") || argument == "--demo"
    }
    static var frames: [String: CGRect] = [:]
    static var notes: [String: String] = [:]
    static var colorChanges = 0
    static var openedURLs: [URL] = []
    static var toolbarMarkers: [String: WeakToolbarMarker] = [:]

    struct WeakToolbarMarker { weak var view: NSView? }

    static func runIfRequested(model: InfoSpaceModel) async {
        let inspect = ProcessInfo.processInfo.arguments.first { $0.hasPrefix("--inspect=") }
        let demo = ProcessInfo.processInfo.arguments.contains("--demo")
        guard inspect != nil || demo else { return }
        let directory = inspect.map {
            URL(fileURLWithPath: String($0.dropFirst("--inspect=".count)), isDirectory: true)
        }
        do {
            if let directory {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            try await Task.sleep(for: .milliseconds(800))
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }) else {
                throw InspectionError.missingWindow
            }
            let session = InspectionSession(
                model: model, window: window,
                directory: directory ?? FileManager.default.temporaryDirectory)
            if inspect != nil {
                try await session.run()
            } else {
                await session.runDemo()
            }
        } catch {
            if let directory {
                try? String(describing: error).write(
                    to: directory.appending(path: "error.txt"), atomically: true, encoding: .utf8)
            }
        }
    }

    private enum InspectionError: Error { case missingWindow }
}
#endif
