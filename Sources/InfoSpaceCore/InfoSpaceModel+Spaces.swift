import Foundation

public enum SpaceInsertionPolicy: Sendable {
    case shiftForward
    case reject
}

public enum SpaceMovePolicy: Sendable {
    case swap
    case reject
}

extension InfoSpaceModel {
    /// Insert at an exact cell. Occupants shift in row-major order, wrapping if needed.
    /// A full grid grows by one row (or column at the row limit). Failures leave it unchanged.
    @discardableResult
    public func insertSpace(
        _ identity: SpaceID = SpaceID(),
        at position: SpacePosition,
        collision: SpaceInsertionPolicy = .shiftForward
    ) throws -> SpaceID {
        guard !spaces.contains(identity) else { throw InfoSpaceError.duplicateID(identity) }
        var next = layout
        next.grid = try gridContaining(position)
        if collision == .reject, next.space(at: position) != nil {
            throw InfoSpaceError.occupiedPosition(position)
        }
        try Self.reserveCell(in: &next)
        var occupants = Dictionary(uniqueKeysWithValues: next.entries.map { ($0.position, $0.id) })
        let positions = next.grid.positions
        var index = position.row * next.grid.columns.count + position.column
        var carried = identity
        while let displaced = occupants.updateValue(carried, forKey: positions[index]) {
            carried = displaced
            index = (index + 1) % positions.count
        }
        let locations = Dictionary(uniqueKeysWithValues: occupants.map { ($0.value, $0.key) })
        next.entries = next.entries.map {
            SpaceEntry(id: $0.id, position: locations[$0.id] ?? $0.position)
        }
        next.entries.append(SpaceEntry(id: identity, position: position))
        applyLayout(next)
        return identity
    }

    /// Remove a space and its presentation state, leaving an empty cell.
    public func removeSpace(_ identity: SpaceID) throws {
        guard spaces.contains(identity) else { throw InfoSpaceError.unknownSpace(identity) }
        var next = layout
        next.entries.removeAll { $0.id == identity }
        applyLayout(next)
    }

    /// Move without changing identity. An occupied destination swaps places by default.
    public func moveSpace(
        _ identity: SpaceID,
        to position: SpacePosition,
        collision: SpaceMovePolicy = .swap
    ) throws {
        guard let original = layout.position(of: identity) else { throw InfoSpaceError.unknownSpace(identity) }
        guard original != position else { return }
        var next = layout
        next.grid = try gridContaining(position)
        let displaced = next.space(at: position)
        if collision == .reject, displaced != nil { throw InfoSpaceError.occupiedPosition(position) }
        next.entries = next.entries.map { entry in
            if entry.id == identity { return SpaceEntry(id: identity, position: position) }
            if entry.id == displaced { return SpaceEntry(id: entry.id, position: original) }
            return entry
        }
        applyLayout(next)
    }

    /// Resize while preserving every space. Out-of-bounds spaces move to the first free cells.
    /// Expanding leaves empty cells; insufficient capacity is an error, never a deletion.
    public func resizeGrid(rows: Int, columns: Int) throws {
        guard SnapAxis.supportedCounts.contains(rows), SnapAxis.supportedCounts.contains(columns) else {
            throw InfoSpaceError.invalidDimensions
        }
        guard rows * columns >= spaces.count else { throw InfoSpaceError.capacityExceeded }
        var next = layout
        if next.grid.rows.count != rows { next.grid.rows = SnapAxis(count: rows) }
        if next.grid.columns.count != columns { next.grid.columns = SnapAxis(count: columns) }
        let occupied = Set(next.entries.filter { next.grid.contains($0.position) }.map(\.position))
        var vacant = next.grid.positions.filter { !occupied.contains($0) }.makeIterator()
        for index in next.entries.indices where !next.grid.contains(next.entries[index].position) {
            guard let position = vacant.next() else { throw InfoSpaceError.capacityExceeded }
            next.entries[index].position = position
        }
        guard next != layout else { return }
        applyLayout(next)
    }

    /// Set relative track sizes. Values are snapped to 32 ticks and constrained to two ticks per track.
    public func setProportions(rows: [Double]? = nil, columns: [Double]? = nil) throws {
        var next = layout
        if let rows {
            guard rows.count == grid.rows.count else { throw InfoSpaceError.invalidProportions }
            next.grid.rows = try SnapAxis(proportions: rows)
        }
        if let columns {
            guard columns.count == grid.columns.count else { throw InfoSpaceError.invalidProportions }
            next.grid.columns = try SnapAxis(proportions: columns)
        }
        guard next != layout else { return }
        applyLayout(next)
    }

    private func gridContaining(_ position: SpacePosition) throws -> SpaceGrid {
        let indices = 0..<SnapAxis.supportedCounts.upperBound
        guard indices.contains(position.row), indices.contains(position.column) else {
            throw InfoSpaceError.invalidPosition(position)
        }
        var next = grid
        if position.row >= next.rows.count { next.rows = SnapAxis(count: position.row + 1) }
        if position.column >= next.columns.count { next.columns = SnapAxis(count: position.column + 1) }
        return next
    }

    private static func reserveCell(in layout: inout SpaceLayout) throws {
        guard layout.entries.count == layout.grid.rows.count * layout.grid.columns.count else { return }
        let maximum = SnapAxis.supportedCounts.upperBound
        if layout.grid.rows.count < maximum {
            layout.grid.rows = SnapAxis(count: layout.grid.rows.count + 1)
        } else if layout.grid.columns.count < maximum {
            layout.grid.columns = SnapAxis(count: layout.grid.columns.count + 1)
        } else {
            throw InfoSpaceError.capacityExceeded
        }
    }
}
