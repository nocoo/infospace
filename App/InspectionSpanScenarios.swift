#if DEBUG
import AppKit
import InfoSpaceCore

extension InspectionSession {
    func inspectProtectedSpan() async throws {
        let identity = SpaceID(row: 0, column: 0)
        let layout = try SpaceLayout(
            grid: SpaceGrid(rows: 2, columns: 2),
            entries: [
                SpaceEntry(
                    id: identity, position: .init(row: 0, column: 0), span: .fullHeight(columns: 1),
                    allowsMove: false, allowsRemoval: false),
                SpaceEntry(id: SpaceID(row: 0, column: 1), position: .init(row: 0, column: 1)),
                SpaceEntry(id: SpaceID(row: 1, column: 1), position: .init(row: 1, column: 1)),
            ])
        try model.request(.restoreSnapshot(SpaceSnapshot(layout: layout)))
        await settle(400)
        let projection = geometry(model)
        let editor = projection.placements.first { $0.space == identity }?.frame ?? .zero
        checks["protected-span-fills-height"] = editor.height == projection.gridFrame.height
        await snapshot("11-protected-span")
        await panelAction(identity, maximize: false, model: model, window: window)
        checks["native-protected-span-minimizes"] = model.minimized.contains(identity)
        await clickBanner(identity, model: model, window: window)
        checks["native-protected-span-restores"] = model.minimized.isEmpty && model.layout == layout
        await panelAction(identity, maximize: true, model: model, window: window)
        checks["native-protected-span-maximizes"] = model.maximized == identity
        await clickBanner(SpaceID(row: 0, column: 1), model: model, window: window)
        checks["native-protected-span-unfocuses"] = model.maximized == nil
        let current = geometry(model)
        if let divider = current.dividers.first(where: { $0.target.column == 0 }) {
            let trace = await drag(
                from: CGPoint(x: divider.frame.midX, y: divider.frame.midY),
                to: CGPoint(x: current.gridFrame.width * 18.2 / 32, y: divider.frame.midY),
                in: window, model: model)
            checks["native-protected-span-drag"] = trace.isContinuous && model.grid.columns.dividers == [18]
        } else {
            checks["native-protected-span-drag"] = false
        }
        checks["protected-span-keeps-note-state"] = notes["r0c1"] == noteText
        await snapshot("12-protected-resized")
    }
}
#endif
