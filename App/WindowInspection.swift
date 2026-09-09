#if DEBUG
import AppKit
import InfoSpaceCore

/// Opt-in checks drive this process's own window. They are not system Accessibility E2E tests.
@MainActor
enum WindowInspection {
    static let isEnabled = ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("--inspect=") }
    static var frames: [String: CGRect] = [:]
    static var notes: [String: String] = [:]
    static var colorChanges = 0
    static var openedURLs: [URL] = []
    static var toolbarMarkers: [String: WeakToolbarMarker] = [:]

    struct WeakToolbarMarker { weak var view: NSView? }

    static func runIfRequested(model: InfoSpaceModel) async {
        guard let argument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--inspect=") }) else {
            return
        }
        let directory = URL(fileURLWithPath: String(argument.dropFirst("--inspect=".count)), isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try await Task.sleep(for: .milliseconds(800))
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }) else {
                throw InspectionError.missingWindow
            }
            try await InspectionSession(model: model, window: window, directory: directory).run()
        } catch {
            try? String(describing: error).write(
                to: directory.appending(path: "error.txt"), atomically: true, encoding: .utf8)
        }
    }

    private enum InspectionError: Error { case missingWindow }
}
#endif
