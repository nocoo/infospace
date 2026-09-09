#if DEBUG
import AppKit
import InfoSpaceCore

extension InspectionSession {
    func inspectFooter() async {
        let original = model.grid
        model.minimize(SpaceID(row: 0, column: 0))
        await settle(450)
        if let button = frames["footer-trailing"] {
            await clickWorkspace(CGPoint(x: button.midX, y: button.midY), in: window)
        }
        checks["native-custom-footer-action"] =
            model.minimized.isEmpty && model.maximized == nil && model.grid == original
    }

    func inspectControls() async {
        let initialWidth = toolbarMarkers["layout-controls"]?.view?.bounds.width ?? 0
        checks["layout-controls-expanded-by-default"] = initialWidth > 400
        await clickToolbar("toggle-layout-controls", in: window)
        let collapsedWidth = toolbarMarkers["layout-controls"]?.view?.bounds.width ?? 0
        checks["native-layout-controls-collapse"] = collapsedWidth > 0 && collapsedWidth < 60
        await snapshot("04c-collapsed-controls")
        await clickToolbar("toggle-layout-controls", in: window)
        let expandedWidth = toolbarMarkers["layout-controls"]?.view?.bounds.width ?? 0
        checks["native-layout-controls-expand"] = abs(expandedWidth - initialWidth) < 2
        diagnostics["controls-widths"] =
            "expanded=\(initialWidth), collapsed=\(collapsedWidth), reopened=\(expandedWidth)"
    }

    func inspectPresets() async {
        await clickToolbar("preset-2x4", in: window)
        checks["native-eight-space-preset"] = model.spaces.count == 8
        await snapshot("05-eight-spaces")
        await clickToolbar("preset-3x4", in: window)
        checks["native-twelve-space-preset"] = model.spaces.count == 12
        await snapshot("06-twelve-spaces")
        let projection = geometry(model)
        checks["native-twelve-space-drag-is-continuous"] = false
        if let intersection = projection.intersections.first(where: {
            $0.target == DividerTarget(column: 1, row: 0)
        }) {
            let trace = await drag(
                from: intersection.center,
                to: CGPoint(x: projection.gridFrame.width * 18.2 / 32, y: projection.gridFrame.height * 8.2 / 32),
                in: window, model: model)
            checks["native-twelve-space-drag-is-continuous"] = trace.isContinuous
            diagnostics["twelve-space-drag-trace"] = trace.summary
        }
        checks["native-twelve-space-intersection"] =
            model.grid.columns.dividers == [8, 18, 24]
            && model.grid.rows.dividers == [8, 21]
    }

    func inspectDenseAndSmallLayouts() async {
        // These stress fixtures use the model directly, separately from the native-event scenarios.
        model.setDimensions(rows: 8, columns: 8)
        await settle(400)
        await snapshot("07-sixty-four-spaces")
        model.maximize(SpaceID(row: 0, column: 0))
        await settle(400)
        checks["dense-focus-retains-all-banners"] = geometry(model).placements.filter(\.isBanner).count == 63
        await snapshot("08-dense-banners")
        model.restoreAll()
        model.setDimensions(rows: 2, columns: 2)
        model.balance()
        window.setContentSize(CGSize(width: 780, height: 540))
        await settle(500)
        await snapshot("09-small-window")
        model.move(DividerTarget(column: 0, row: 0), columnTick: 2, rowTick: 2)
        await settle(250)
        await snapshot("09b-minimum-tracks")
        model.balance()
        window.setFrame(initialFrame, display: true)
        await settle(500)
        await snapshot("10-final-window")
    }
}
#endif
