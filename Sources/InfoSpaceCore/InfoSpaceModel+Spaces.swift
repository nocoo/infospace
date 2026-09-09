import Foundation

extension InfoSpaceModel {
    @discardableResult
    public func insertSpace(
        _ identity: SpaceID = SpaceID(), at position: SpacePosition,
        collision: SpaceInsertionPolicy = .shiftForward
    ) throws -> SpaceID {
        try apply(.insert(SpaceEntry(id: identity, position: position), collision: collision))
        return identity
    }

    public func removeSpace(_ identity: SpaceID) throws { try apply(.remove(identity)) }

    public func moveSpace(
        _ identity: SpaceID, to position: SpacePosition, collision: SpaceMovePolicy = .swap
    ) throws {
        try apply(.move(identity, destination: position, collision: collision))
    }

    public func resizeGrid(rows: Int, columns: Int) throws { try apply(.resize(rows: rows, columns: columns)) }

    public func setProportions(rows: [Double]? = nil, columns: [Double]? = nil) throws {
        try apply(.proportions(rows: rows, columns: columns))
    }

    public func apply(_ command: SpaceLayoutCommand) throws { try apply([command]) }

    /// Validate all commands before publishing; a failed batch preserves drag and presentation.
    public func apply(_ commands: [SpaceLayoutCommand]) throws {
        try request(.layout(commands))
    }
}
