#if DEBUG
import AppKit
import InfoSpaceCore

@MainActor
final class InspectionSession {
    let model: InfoSpaceModel
    let window: NSWindow
    let directory: URL
    let initialFrame: CGRect
    let noteID = "note-r0c1"
    let noteText = "这条笔记在缩放后仍然保留。"
    var checks: [String: Bool] = [:]
    var captures: [String: String] = [:]
    var diagnostics: [String: String] = [:]

    var frames: [String: CGRect] { WindowInspection.frames }
    var notes: [String: String] { WindowInspection.notes }
    var toolbarMarkers: [String: WindowInspection.WeakToolbarMarker] { WindowInspection.toolbarMarkers }

    init(model: InfoSpaceModel, window: NSWindow, directory: URL) {
        self.model = model
        self.window = window
        self.directory = directory
        initialFrame = window.frame
    }

    func run() async throws {
        await inspectLaunch()
        await inspectHeaderLink()
        await inspectNoteEditing()
        await inspectDividerDrags()
        await inspectPanelActions()
        try await inspectCustomization()
        await inspectFooter()
        await inspectControls()
        await inspectPresets()
        await inspectDenseAndSmallLayouts()
        try await inspectProtectedSpan()
        await inspectControlStyle()
        await inspectCanvasIsolation()
        try writeReport()
    }

    func snapshot(_ name: String) async {
        captures[name] = await capture(window, to: directory.appending(path: "\(name).png"))
    }

    func inspectLaunch() async {
        if let visible = window.screen?.visibleFrame {
            checks["launch-covers-over-three-quarters"] =
                window.frame.width * window.frame.height / (visible.width * visible.height) > 0.75
            checks["launch-centered"] =
                abs(window.frame.midX - visible.midX) < 2 && abs(window.frame.midY - visible.midY) < 2
        }
        window.setContentSize(CGSize(width: 1440, height: 920))
        window.center()
        window.makeKeyAndOrderFront(nil)
        await settle(500)
        await snapshot("01-baseline")
        let toolbarHeight = window.frame.height - window.contentLayoutRect.height
        diagnostics["native-toolbar-height"] = String(describing: toolbarHeight)
        checks["native-header-uses-one-row"] = toolbarHeight <= 60
        let brand = toolbarMarkers["toolbar-brand"]?.view
        let close = window.standardWindowButton(.closeButton)
        if let brand, let close {
            let brandFrame = brand.convert(brand.bounds, to: nil)
            let closeFrame = close.convert(close.bounds, to: nil)
            diagnostics["toolbar-traffic-light-center-offset"] = String(abs(brandFrame.midY - closeFrame.midY))
            checks["traffic-lights-align-with-header"] = abs(brandFrame.midY - closeFrame.midY) < 5
        }
        let canvas = frames["canvas"] ?? .zero
        let footer = frames["footer"] ?? .zero
        checks["workspace-only-reserves-custom-footer"] =
            abs(canvas.height + footer.height + 12 - (window.contentLayoutRect.height - 36)) < 2
        let leading = frames["footer-leading"] ?? .zero
        let trailing = frames["footer-trailing"] ?? .zero
        checks["custom-footer-aligns-both-sides"] =
            abs(leading.minX - canvas.minX) < 2
            && abs(trailing.maxX - canvas.maxX) < 2 && footer.minY > canvas.maxY
    }

    func writeReport() throws {
        let report: [String: Any] = [
            "checks": checks,
            "diagnostics": diagnostics,
            "captures": captures,
            "passed": checks.values.allSatisfy { $0 },
            "geometry_projection_microseconds_64_panels": benchmarkGeometry(),
            "geometry_benchmark_iterations": 3000,
            "event_validation":
                "NSEvents to this app's own window; Unicode through NSTextView.insertText; not system Accessibility E2E",
            "initial_window": [
                initialFrame.origin.x, initialFrame.origin.y, initialFrame.width, initialFrame.height,
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: directory.appending(path: "report.json"), options: .atomic)
    }

    func inspectHeaderLink() async {
        checks["native-github-header-link"] = false
        guard let brand = toolbarMarkers["toolbar-brand"]?.view else { return }
        await activate(window)
        let location = brand.convert(CGPoint(x: brand.bounds.maxX + 29, y: brand.bounds.midY), to: nil)
        post(.leftMouseDown, at: location, in: window)
        post(.leftMouseUp, at: location, in: window)
        await settle(200)
        checks["native-github-header-link"] =
            WindowInspection.openedURLs.last?.absoluteString == "https://github.com/nocoo/infospace"
    }
}
#endif
