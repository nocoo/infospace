#if DEBUG
import AppKit
import InfoSpaceCore

extension InspectionSession {
    func inspectNoteEditing() async {
        checks["native-note-edit"] = false
        if let noteFrame = frames[noteID], noteFrame.height > 10 {
            await clickWorkspace(CGPoint(x: noteFrame.midX, y: noteFrame.midY), in: window)
            // Commit Unicode through the native editor; fabricated key codes are reinterpreted by IMEs.
            if let editor = window.firstResponder as? NSTextView {
                editor.selectAll(nil)
                editor.insertText(noteText, replacementRange: editor.selectedRange())
            }
            await settle(150)
            diagnostics["note-native-text"] = (window.firstResponder as? NSTextView)?.string ?? "not-NSTextView"
            checks["native-note-edit"] = notes["r0c1"] == noteText
        }
        await snapshot("01b-note-edit")
    }

    func inspectDividerDrags() async {
        let size = geometry(model).gridFrame.size
        let vertical = await drag(
            from: CGPoint(x: size.width / 2, y: size.height / 4),
            to: CGPoint(x: size.width * 12.2 / 32, y: size.height / 4), in: window, model: model)
        checks["native-vertical-drag-is-continuous"] = vertical.isContinuous
        checks["native-vertical-drag-snaps"] =
            model.grid.columns.dividers == [12] && model.grid.rows.dividers == [16]
        diagnostics["vertical-drag-trace"] = vertical.summary
        let horizontal = await drag(
            from: CGPoint(x: size.width * 0.8, y: size.height / 2),
            to: CGPoint(x: size.width * 0.8, y: size.height * 20.2 / 32), in: window, model: model)
        checks["native-horizontal-drag-is-continuous"] = horizontal.isContinuous
        checks["native-horizontal-drag-snaps"] =
            model.grid.columns.dividers == [12] && model.grid.rows.dividers == [20]
        diagnostics["horizontal-drag-trace"] = horizontal.summary
        checks["native-intersection-drag-is-continuous"] = false
        if let intersection = geometry(model).intersections.first {
            let trace = await drag(
                from: intersection.center,
                to: CGPoint(x: size.width * 21.2 / 32, y: size.height * 12.2 / 32), in: window, model: model)
            checks["native-intersection-drag-is-continuous"] = trace.isContinuous
            diagnostics["intersection-drag-trace"] = trace.summary
        }
        checks["native-intersection-updates-both-axes"] =
            model.grid.columns.dividers == [21] && model.grid.rows.dividers == [12]
        checks["drag-session-ends"] = model.activeDivider == nil
        await snapshot("02-resized")
    }

    func inspectPanelActions() async {
        let resizedGrid = model.grid
        let first = SpaceID(row: 0, column: 0)
        let note = SpaceID(row: 0, column: 1)
        await panelAction(first, maximize: true, model: model, window: window)
        checks["native-maximize-button"] = model.maximized == first
        checks["maximized-keeps-three-banners"] = geometry(model).placements.filter(\.isBanner).count == 3
        await snapshot("03-maximized")
        await clickBanner(note, model: model, window: window)
        checks["native-banner-restores-proportions"] = model.maximized == nil && model.grid == resizedGrid
        await panelAction(first, maximize: false, model: model, window: window)
        checks["native-minimize-button"] = model.minimized.contains(first)
        await snapshot("04-minimized")
        await clickBanner(first, model: model, window: window)
        checks["native-minimized-banner-restores"] = model.minimized.isEmpty && model.grid == resizedGrid
        diagnostics["after-minimized-banner"] =
            "minimized=\(model.minimized), grid=\(model.grid), expected=\(resizedGrid)"
        await snapshot("04a-restored-banner")
        await panelAction(note, maximize: true, model: model, window: window)
        checks["note-state-survives-resize-and-focus"] = notes["r0c1"] == noteText
        await panelAction(note, maximize: false, model: model, window: window)
        await clickBanner(note, model: model, window: window)
        await panelAction(note, maximize: true, model: model, window: window)
        checks["note-state-survives-minimize"] = notes["r0c1"] == noteText
        await clickBanner(first, model: model, window: window)
    }

    func inspectCustomization() async throws {
        let original = model.layout.entries
        let first = SpaceID(row: 0, column: 0)
        let beforeColors = WindowInspection.colorChanges
        if let frame = geometry(model).placements.first(where: { $0.space == first })?.frame {
            await clickCanvas(CGPoint(x: frame.maxX - 87, y: frame.minY + 24), in: window)
        }
        checks["native-custom-header-action"] = WindowInspection.colorChanges == beforeColors + 1
        let revision = model.presentationRevision
        if let frame = geometry(model).placements.first(where: { $0.space == first })?.frame {
            await clickCanvas(CGPoint(x: frame.maxX - 116, y: frame.minY + 24), in: window)
        }
        let inserted = model.spaces.filter { identity in !original.contains { $0.id == identity } }
        checks["native-insert-at-requested-position"] =
            inserted.count == 1
            && model.space(at: SpacePosition(row: 0, column: 0)) == inserted.first
        checks["insertion-requests-layout-animation"] = model.presentationRevision > revision
        checks["insertion-retains-existing-identities"] = Set(original.map(\.id)).isSubset(of: Set(model.spaces))
        checks["note-state-survives-insertion"] = notes["r0c1"] == noteText
        await snapshot("04b-inserted-space")
        for identity in inserted { try model.removeSpace(identity) }
        for entry in original { try model.moveSpace(entry.id, to: entry.position) }
        try model.resizeGrid(rows: 2, columns: 2)
        await settle(500)
    }
}
#endif
