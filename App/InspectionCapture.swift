#if DEBUG
import AppKit
import InfoSpaceCore
@preconcurrency import ScreenCaptureKit

extension InspectionSession {
    func benchmarkGeometry() -> Double {
        var grid = SpaceGrid(rows: 8, columns: 8)
        let start = ContinuousClock.now
        var consumed = 0
        for index in 0..<3000 {
            grid.columns.moveDivider(at: index % 7, to: (index * 7) % 32)
            let projection = SpaceGeometry(
                grid: grid, minimized: [], maximized: nil, size: CGSize(width: 1800, height: 1100))
            consumed += projection.placements.count + projection.intersections.count
        }
        let elapsed = start.duration(to: .now).components
        let microseconds = Double(elapsed.seconds) * 1_000_000 + Double(elapsed.attoseconds) / 1_000_000_000_000
        return consumed > 0 ? microseconds / 3000 : -1
    }

    func capture(_ window: NSWindow, to file: URL) async -> String {
        do {
            let content = try await SCShareableContent.currentProcess
            guard let ownWindow = content.windows.first(where: { $0.windowID == CGWindowID(window.windowNumber) })
            else {
                return "window-unavailable"
            }
            let filter = SCContentFilter(desktopIndependentWindow: ownWindow)
            let configuration = SCStreamConfiguration()
            configuration.width = Int(window.frame.width * window.backingScaleFactor)
            configuration.height = Int(window.frame.height * window.backingScaleFactor)
            configuration.showsCursor = false
            configuration.ignoreShadowsSingleWindow = true
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter, configuration: configuration)
            let bitmap = NSBitmapImageRep(cgImage: image)
            guard let data = bitmap.representation(using: .png, properties: [:]) else { return "encoding-failed" }
            try data.write(to: file, options: .atomic)
            return "ok"
        } catch { return String(describing: error) }
    }

}
#endif
