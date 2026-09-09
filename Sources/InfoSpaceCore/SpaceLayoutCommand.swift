import Foundation

public enum SpaceInsertionPolicy: String, Codable, Sendable {
    case shiftForward
    case reject
}

public enum SpaceMovePolicy: String, Codable, Sendable {
    case swap
    case reject
}

/// Value commands share validation in UI, persistence adapters and headless tools.
public enum SpaceLayoutCommand: Codable, Equatable, Sendable {
    case insert(SpaceEntry, collision: SpaceInsertionPolicy)
    case remove(SpaceID)
    case move(SpaceID, destination: SpacePosition, collision: SpaceMovePolicy)
    case resize(rows: Int, columns: Int)
    case proportions(rows: [Double]?, columns: [Double]?)
    case divider(DividerTarget, columnTick: Int?, rowTick: Int?)
    case balance
}

extension SpaceLayout {
    public func applying(_ commands: [SpaceLayoutCommand]) throws -> SpaceLayout {
        try commands.reduce(self) { try $0.applying($1) }
    }

    public func applying(_ command: SpaceLayoutCommand) throws -> SpaceLayout {
        var next = self
        switch command {
        case .insert(let entry, let collision): try next.insert(entry, collision: collision)
        case .remove(let identity):
            guard let entry = entries.first(where: { $0.id == identity }) else {
                throw InfoSpaceError.unknownSpace(identity)
            }
            guard entry.allowsRemoval else { throw InfoSpaceError.protectedSpace(identity) }
            next.entries.removeAll { $0.id == identity }
        case .move(let identity, let position, let collision):
            try next.relocate(identity, to: position, collision: collision)
        case .resize(let rows, let columns): try next.resize(rows: rows, columns: columns)
        case .proportions(let rows, let columns): try next.updateProportions(rows: rows, columns: columns)
        case .divider(let target, let columnTick, let rowTick):
            next.updateDivider(target, columnTick: columnTick, rowTick: rowTick)
        case .balance: next.grid = SpaceGrid(rows: grid.rows.count, columns: grid.columns.count)
        }
        let validated = try SpaceLayout(grid: next.grid, entries: next.entries)
        try validated.validatePreservingConstraints(of: self)
        return validated
    }

    private mutating func updateProportions(rows: [Double]?, columns: [Double]?) throws {
        if let rows {
            guard rows.count == grid.rows.count else { throw InfoSpaceError.invalidProportions }
            grid.rows = try SnapAxis(proportions: rows)
        }
        if let columns {
            guard columns.count == grid.columns.count else { throw InfoSpaceError.invalidProportions }
            grid.columns = try SnapAxis(proportions: columns)
        }
    }

    private mutating func updateDivider(_ target: DividerTarget, columnTick: Int?, rowTick: Int?) {
        if let index = target.column, let columnTick { grid.columns.moveDivider(at: index, to: columnTick) }
        if let index = target.row, let rowTick { grid.rows.moveDivider(at: index, to: rowTick) }
    }

    private mutating func insert(_ entry: SpaceEntry, collision: SpaceInsertionPolicy) throws {
        guard !entries.contains(where: { $0.id == entry.id }) else { throw InfoSpaceError.duplicateID(entry.id) }
        try expand(to: entry.position)
        if entry.span != .cell {
            entries.append(entry)
            return
        }
        if let occupant = space(at: entry.position) {
            guard collision != .reject else { throw InfoSpaceError.occupiedPosition(entry.position) }
            if let blocked = entries.first(where: { $0.id == occupant }), !blocked.allowsMove {
                throw InfoSpaceError.protectedSpace(occupant)
            }
            guard entries.first(where: { $0.id == occupant })?.span == .cell else {
                throw InfoSpaceError.occupiedPosition(entry.position)
            }
        }
        try reserveCell()
        let immobile = try Set(
            entries.filter { !$0.allowsMove || $0.span != .cell }
                .flatMap { try $0.occupiedPositions(in: grid) })
        let positions = grid.positions.filter { !immobile.contains($0) }
        guard var index = positions.firstIndex(of: entry.position) else {
            throw InfoSpaceError.occupiedPosition(entry.position)
        }
        var occupants = Dictionary(
            uniqueKeysWithValues: entries.filter { $0.allowsMove && $0.span == .cell }
                .map { ($0.position, $0.id) })
        var carried = entry.id
        while let displaced = occupants.updateValue(carried, forKey: positions[index]) {
            carried = displaced
            index = (index + 1) % positions.count
        }
        let locations = Dictionary(uniqueKeysWithValues: occupants.map { ($0.value, $0.key) })
        for index in entries.indices {
            if let position = locations[entries[index].id] { entries[index].position = position }
        }
        entries.append(entry)
    }

    private mutating func relocate(_ identity: SpaceID, to position: SpacePosition, collision: SpaceMovePolicy) throws {
        guard let index = entries.firstIndex(where: { $0.id == identity }) else {
            throw InfoSpaceError.unknownSpace(identity)
        }
        let original = entries[index]
        guard original.position != position else { return }
        guard original.allowsMove else { throw InfoSpaceError.protectedSpace(identity) }
        try expand(to: position)
        let displaced = space(at: position)
        if let other = entries.firstIndex(where: { $0.id == displaced && $0.id != identity }) {
            guard collision != .reject else { throw InfoSpaceError.occupiedPosition(position) }
            guard entries[other].allowsMove else { throw InfoSpaceError.protectedSpace(entries[other].id) }
            guard original.span == .cell, entries[other].span == .cell else {
                throw InfoSpaceError.occupiedPosition(position)
            }
            entries[other].position = original.position
        }
        entries[index].position = position
    }

    private mutating func resize(rows: Int, columns: Int) throws {
        guard SnapAxis.supportedCounts.contains(rows), SnapAxis.supportedCounts.contains(columns) else {
            throw InfoSpaceError.invalidDimensions
        }
        guard rows * columns >= entries.count else { throw InfoSpaceError.capacityExceeded }
        if grid.rows.count != rows { grid.rows = SnapAxis(count: rows) }
        if grid.columns.count != columns { grid.columns = SnapAxis(count: columns) }
        var occupied: Set<SpacePosition> = []
        var displaced: [Int] = []
        for index in entries.indices {
            let cells = try? entries[index].occupiedPositions(in: grid)
            if let positions = cells, occupied.isDisjoint(with: positions) {
                occupied.formUnion(positions)
            } else {
                guard entries[index].allowsMove else { throw InfoSpaceError.protectedSpace(entries[index].id) }
                displaced.append(index)
            }
        }
        for index in displaced {
            entries[index] = try fit(entries[index], occupied: &occupied)
        }
    }

    private func fit(_ entry: SpaceEntry, occupied: inout Set<SpacePosition>) throws -> SpaceEntry {
        for position in grid.positions {
            var candidate = entry
            candidate.position = position
            let cells = try? candidate.occupiedPositions(in: grid)
            if let cells, occupied.isDisjoint(with: cells) {
                occupied.formUnion(cells)
                return candidate
            }
        }
        throw InfoSpaceError.capacityExceeded
    }

    private mutating func expand(to position: SpacePosition) throws {
        let indices = 0..<SnapAxis.supportedCounts.upperBound
        guard indices.contains(position.row), indices.contains(position.column) else {
            throw InfoSpaceError.invalidPosition(position)
        }
        if position.row >= grid.rows.count { grid.rows = SnapAxis(count: position.row + 1) }
        if position.column >= grid.columns.count { grid.columns = SnapAxis(count: position.column + 1) }
    }

    private mutating func reserveCell() throws {
        while try Set(entries.flatMap { try $0.occupiedPositions(in: grid) }).count == grid.positions.count {
            let maximum = SnapAxis.supportedCounts.upperBound
            if grid.rows.count < maximum {
                grid.rows = SnapAxis(count: grid.rows.count + 1)
            } else if grid.columns.count < maximum {
                grid.columns = SnapAxis(count: grid.columns.count + 1)
            } else {
                throw InfoSpaceError.capacityExceeded
            }
        }
    }
}
