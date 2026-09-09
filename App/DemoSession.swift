#if DEBUG
import AppKit
import InfoSpaceCore
import SwiftUI

private enum DemoTiming {
    static let recordingPause = 10_000
    static let pointer = 160
    static let hold = 1_100
    static let layout = 780
    static let snap = 420
    static let dragStep = 40
    static let dragSteps = 20
    static let type = 48
    static let baseline = 2_000
    static let finale = 2_800
}

extension InspectionSession {
    func runDemo() async {
        await prepareForRecording()
        await showBaseline()
        await editNote()
        await dragDividers()
        await focusAndRestore()
        await customizePanel()
        await showPresets()
        await showDenseGrid()
        await returnHome()
    }

    private func prepareForRecording() async {
        window.styleMask.remove(.resizable)
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        for _ in 0..<40 {
            if let canvas = frames["canvas"], canvas.width > 100 { break }
            await settle(50)
        }
        await settle(DemoTiming.recordingPause)
        window.isMovable = false
    }

    private func showBaseline() async {
        await settle(DemoTiming.baseline)
    }

    private func editNote() async {
        guard let noteFrame = frames[noteID], noteFrame.height > 10 else { return }
        await demoTapWorkspace(CGPoint(x: noteFrame.midX, y: noteFrame.midY))
        guard let editor = window.firstResponder as? NSTextView else { return }
        editor.selectAll(nil)
        await settle(120)
        for character in Array("把新的想法留在这里。") {
            editor.insertText(String(character), replacementRange: editor.selectedRange())
            await settle(DemoTiming.type)
        }
        await settle(DemoTiming.hold)
    }

    private func dragDividers() async {
        let size = geometry(model).gridFrame.size
        await demonstrateDrag(
            target: DividerTarget(column: 0),
            from: CGPoint(x: size.width / 2, y: size.height / 4),
            destination: CGPoint(x: size.width * 12.2 / 32, y: size.height / 4))
        await demonstrateDrag(
            target: DividerTarget(row: 0),
            from: CGPoint(x: size.width * 0.8, y: size.height / 2),
            destination: CGPoint(x: size.width * 0.8, y: size.height * 20.2 / 32))
        if let intersection = geometry(model).intersections.first {
            await demonstrateDrag(
                target: intersection.target, from: intersection.center,
                destination: CGPoint(x: size.width * 21.2 / 32, y: size.height * 12.2 / 32))
        }
    }

    private func focusAndRestore() async {
        let first = SpaceID(row: 0, column: 0)
        let note = SpaceID(row: 0, column: 1)
        await demoPanelAction(first, maximize: true)
        await demoTapBanner(note)
        await demoPanelAction(first, maximize: false)
        if let button = frames["footer-trailing"] {
            await demoTapWorkspace(CGPoint(x: button.midX, y: button.midY))
        }
    }

    private func customizePanel() async {
        let first = SpaceID(row: 0, column: 0)
        guard let frame = geometry(model).placements.first(where: { $0.space == first })?.frame else { return }
        await demoTapCanvas(CGPoint(x: frame.maxX - 87, y: frame.minY + 24))
        await demoTapCanvas(CGPoint(x: frame.maxX - 116, y: frame.minY + 24))
    }

    private func showPresets() async {
        await demoTapToolbar("preset-2x4")
        await demoTapToolbar("preset-3x4")
        let projection = geometry(model)
        if let intersection = projection.intersections.first(where: {
            $0.target == DividerTarget(column: 1, row: 0)
        }) {
            await demonstrateDrag(
                target: intersection.target, from: intersection.center,
                destination: CGPoint(
                    x: projection.gridFrame.width * 18.2 / 32,
                    y: projection.gridFrame.height * 8.2 / 32))
        }
    }

    private func showDenseGrid() async {
        model.setDimensions(rows: 8, columns: 8)
        await settle(DemoTiming.layout)
        await settle(DemoTiming.hold)
        let first = SpaceID(row: 0, column: 0)
        if let frame = geometry(model).placements.first(where: { $0.space == first })?.frame {
            movePointerOnCanvas(CGPoint(x: frame.midX, y: frame.midY))
            await settle(DemoTiming.pointer)
        }
        model.maximize(first)
        await settle(DemoTiming.hold)
        await settle(DemoTiming.hold)
    }

    private func returnHome() async {
        await demoTapToolbar("preset-2x2", hold: DemoTiming.finale)
    }

    private func demonstrateDrag(target: DividerTarget, from: CGPoint, destination: CGPoint) async {
        await activate(window)
        movePointerOnCanvas(from)
        await settle(DemoTiming.pointer)
        model.beginDrag(target)
        let size = geometry(model).gridFrame.size
        for step in 1...DemoTiming.dragSteps {
            let progress = CGFloat(step) / CGFloat(DemoTiming.dragSteps)
            let point = CGPoint(
                x: from.x + (destination.x - from.x) * progress,
                y: from.y + (destination.y - from.y) * progress)
            movePointerOnCanvas(point)
            _ = model.updateDrag(
                target,
                columnTick: SnapAxis.fractionalTick(at: Double(point.x), length: Double(size.width)),
                rowTick: SnapAxis.fractionalTick(at: Double(point.y), length: Double(size.height)))
            await settle(DemoTiming.dragStep)
        }
        // Inspection queues a complete mouse gesture before yielding so tracking cannot stall.
        // Demo advances the model on a timer so the recording can show continuous following.
        withAnimation(.easeOut(duration: 0.14)) { model.endDrag() }
        await settle(DemoTiming.snap)
        await settle(DemoTiming.hold)
    }

    private func demoPanelAction(_ space: SpaceID, maximize: Bool) async {
        guard let frame = geometry(model).placements.first(where: { $0.space == space })?.frame else { return }
        await demoTapCanvas(CGPoint(x: frame.maxX - (maximize ? 29 : 58), y: frame.minY + 24))
    }

    private func demoTapBanner(_ space: SpaceID) async {
        guard let placement = geometry(model).placements.first(where: { $0.space == space && $0.isBanner }) else {
            return
        }
        await demoTapCanvas(CGPoint(x: placement.frame.midX, y: placement.frame.midY))
    }

    private func demoTapCanvas(_ point: CGPoint, hold: Int = DemoTiming.hold) async {
        let canvas = frames["canvas"] ?? .zero
        await demoTapWorkspace(CGPoint(x: canvas.minX + point.x, y: canvas.minY + point.y), hold: hold)
    }

    private func demoTapToolbar(_ id: String, hold: Int = DemoTiming.hold) async {
        await activate(window)
        guard let anchor = toolbarMarkers["layout-controls"]?.view, anchor.window === window else { return }
        let horizontal: CGFloat
        switch id {
        case "preset-2x2": horizontal = 38
        case "preset-2x4": horizontal = 112
        case "preset-3x4": horizontal = 186
        default: return
        }
        let location = anchor.convert(CGPoint(x: horizontal, y: anchor.bounds.midY), to: nil)
        movePointer(toWindow: location)
        await settle(DemoTiming.pointer)
        post(.leftMouseDown, at: location, in: window)
        post(.leftMouseUp, at: location, in: window)
        await settle(hold)
    }

    private func demoTapWorkspace(_ point: CGPoint, hold: Int = DemoTiming.hold) async {
        await activate(window)
        let location = windowPoint(point, in: window)
        movePointer(toWindow: location)
        await settle(DemoTiming.pointer)
        post(.leftMouseDown, at: location, in: window)
        post(.leftMouseUp, at: location, in: window)
        await settle(hold)
    }

    private func movePointerOnCanvas(_ point: CGPoint) {
        let canvas = frames["canvas"] ?? .zero
        movePointer(toWindow: windowPoint(CGPoint(x: canvas.minX + point.x, y: canvas.minY + point.y), in: window))
    }

    private func movePointer(toWindow point: CGPoint) {
        let cocoa = window.convertPoint(toScreen: point)
        let height = NSScreen.screens.first?.frame.maxY ?? cocoa.y
        CGWarpMouseCursorPosition(CGPoint(x: cocoa.x, y: height - cocoa.y))
    }
}
#endif
