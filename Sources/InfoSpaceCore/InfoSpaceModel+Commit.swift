import Foundation

extension InfoSpaceModel {
    /// With a handler installed, the host owns commits. The canvas stays at its last accepted revision
    /// until the host validates/persists the command and calls `install`. A preview is never persisted.
    public func request(_ command: SpaceCommand) throws {
        let current = try snapshot
        let proposed = try current.applying(command, expectedRevision: revision)
        guard proposed != current else { return }
        cancelDrag()
        if let commandHandler {
            commandHandler(command, revision)
        } else {
            try install(proposed)
        }
    }

    /// Install only accepted state. A failed or late host commit cannot replace newer state.
    public func install(_ accepted: SpaceSnapshot) throws {
        try accepted.validate()
        try accepted.layout.validatePreservingConstraints(of: layout)
        guard accepted.revision >= revision else { throw InfoSpaceError.revisionConflict }
        if accepted.revision == revision {
            guard accepted == (try snapshot) else { throw InfoSpaceError.revisionConflict }
            return
        }
        let structural =
            accepted.layout.entries != layout.entries
            || accepted.layout.grid.rows.count != grid.rows.count
            || accepted.layout.grid.columns.count != grid.columns.count
            || accepted.minimized != minimized || accepted.maximized != maximized
        cancelDrag()
        layout = accepted.layout
        minimized = accepted.minimized
        maximized = accepted.maximized
        revision = accepted.revision
        lastError = nil
        if structural { presentationRevision &+= 1 }
    }

    func perform(_ command: SpaceCommand) {
        cancelDrag()
        do { try request(command) } catch { lastError = error as? InfoSpaceError ?? .invalidSnapshot }
    }
}
