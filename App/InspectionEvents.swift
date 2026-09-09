#if DEBUG
import AppKit
import InfoSpaceCore

extension InspectionSession {
    func geometry(_ model: InfoSpaceModel) -> SpaceGeometry {
        SpaceGeometry(
            layout: model.layout, minimized: model.minimized, maximized: model.maximized,
            size: frames["canvas"]?.size ?? .zero, dragPreview: model.dragPreview)
    }

    func panelAction(_ space: SpaceID, maximize: Bool, model: InfoSpaceModel, window: NSWindow) async {
        guard let frame = geometry(model).placements.first(where: { $0.space == space })?.frame else { return }
        await clickCanvas(CGPoint(x: frame.maxX - (maximize ? 29 : 58), y: frame.minY + 24), in: window)
    }

    func clickBanner(_ space: SpaceID, model: InfoSpaceModel, window: NSWindow) async {
        guard let placement = geometry(model).placements.first(where: { $0.space == space && $0.isBanner }) else {
            return
        }
        await clickCanvas(CGPoint(x: placement.frame.midX, y: placement.frame.midY), in: window)
    }

    func clickCanvas(_ point: CGPoint, in window: NSWindow) async {
        let canvas = frames["canvas"] ?? .zero
        await clickWorkspace(CGPoint(x: canvas.minX + point.x, y: canvas.minY + point.y), in: window)
    }

    func clickWorkspace(_ point: CGPoint, in window: NSWindow) async {
        await activate(window)
        let location = windowPoint(point, in: window)
        post(.leftMouseDown, at: location, in: window)
        post(.leftMouseUp, at: location, in: window)
        await settle(750)
    }

    func clickToolbar(_ id: String, in window: NSWindow) async {
        await activate(window)
        guard let anchor = toolbarMarkers["layout-controls"]?.view, anchor.window === window else { return }
        // Native toolbar items have separate hosting views. Use the live hosting anchor and
        // centers inside the SDK's fixed-size controls, just as panel-button checks use header bounds.
        let horizontal: CGFloat
        switch id {
        case "toggle-layout-controls": horizontal = anchor.bounds.maxX - 15
        case "preset-2x4": horizontal = 112
        case "preset-3x4": horizontal = 186
        default: return
        }
        let location = anchor.convert(CGPoint(x: horizontal, y: anchor.bounds.midY), to: nil)
        post(.leftMouseDown, at: location, in: window)
        post(.leftMouseUp, at: location, in: window)
        await settle(750)
    }

    func drag(
        from: CGPoint, to destination: CGPoint, in window: NSWindow, model: InfoSpaceModel
    ) async -> DragTrace {
        await activate(window)
        let trace = DragTrace(grid: model.grid)
        // Inspect the previous event's live preview before the next event (including mouse-up) is handled.
        let monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { event in
            MainActor.assumeIsolated {
                if event.window === window { trace.sample(model) }
            }
            return event
        }
        defer { if let monitor { NSEvent.removeMonitor(monitor) } }
        let canvas = frames["canvas"] ?? .zero
        func point(_ value: CGPoint) -> CGPoint {
            windowPoint(CGPoint(x: canvas.minX + value.x, y: canvas.minY + value.y), in: window)
        }
        post(.leftMouseDown, at: point(from), in: window)
        // Queue a complete gesture before yielding, so AppKit's tracking loop always has its mouse-up.
        // Intentionally stop short: release must commit the mouse-up's newer position.
        for step in 1..<24 {
            let progress = CGFloat(step) / 24
            post(
                .leftMouseDragged,
                at: point(
                    CGPoint(
                        x: from.x + (destination.x - from.x) * progress,
                        y: from.y + (destination.y - from.y) * progress)), in: window)
        }
        post(.leftMouseUp, at: point(destination), in: window)
        await settle(350)
        return trace
    }

    func windowPoint(_ point: CGPoint, in window: NSWindow) -> CGPoint {
        guard let view = window.contentView else { return point }
        let local = CGPoint(x: point.x, y: view.isFlipped ? point.y : view.bounds.height - point.y)
        return view.convert(local, to: nil)
    }

    func activate(_ window: NSWindow) async {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        await settle(80)
    }

    func post(_ type: NSEvent.EventType, at point: CGPoint, in window: NSWindow) {
        guard
            let event = NSEvent.mouseEvent(
                with: type, location: point, modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                context: nil, eventNumber: 0, clickCount: 1, pressure: type == .leftMouseUp ? 0 : 1)
        else { return }
        NSApp.postEvent(event, atStart: false)
    }

    func settle(_ milliseconds: Int) async {
        try? await Task.sleep(for: .milliseconds(milliseconds))
    }

}
#endif
