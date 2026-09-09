import Foundation

/// A stable identity, independent of a space's current grid position.
public struct SpaceID: Hashable, Codable, Identifiable, Sendable {
    public let rawValue: String
    public var id: String { rawValue }

    public init(_ rawValue: String = UUID().uuidString) {
        self.rawValue = rawValue
    }

    /// A convenient deterministic ID for an initially dense grid. Moving it does not change its ID.
    public init(row: Int, column: Int) {
        rawValue = "r\(row)c\(column)"
    }
}

/// Zero-based row and column in a grid of up to eight tracks per axis.
public struct SpacePosition: Hashable, Codable, Sendable {
    public let row: Int
    public let column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}

public struct SpaceEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: SpaceID
    public internal(set) var position: SpacePosition
    public let span: SpaceSpan
    public let allowsMove: Bool
    public let allowsRemoval: Bool

    public init(
        id: SpaceID, position: SpacePosition, span: SpaceSpan = .cell,
        allowsMove: Bool = true, allowsRemoval: Bool = true
    ) {
        self.id = id
        self.position = position
        self.span = span
        self.allowsMove = allowsMove
        self.allowsRemoval = allowsRemoval
    }
}

public enum InfoSpaceError: Error, Equatable, Sendable {
    case duplicateID(SpaceID)
    case unknownSpace(SpaceID)
    case invalidPosition(SpacePosition)
    case occupiedPosition(SpacePosition)
    case invalidDimensions
    case capacityExceeded
    case invalidProportions
    case invalidSpan
    case protectedSpace(SpaceID)
    case invalidSnapshot
    case unsupportedSnapshotVersion
    case revisionConflict
}

/// A value snapshot of the committed grid and the identities assigned to its cells.
public struct SpaceLayout: Codable, Equatable, Sendable {
    public internal(set) var grid: SpaceGrid
    public internal(set) var entries: [SpaceEntry]

    public init(rows: Int = 2, columns: Int = 2, fillEmptyCells: Bool = true) {
        grid = SpaceGrid(rows: rows, columns: columns)
        entries = fillEmptyCells ? Self.denseEntries(in: grid) : []
    }

    public init(grid: SpaceGrid, entries: [SpaceEntry]) throws {
        var identities: Set<SpaceID> = []
        var positions: Set<SpacePosition> = []
        for entry in entries {
            guard grid.contains(entry.position) else { throw InfoSpaceError.invalidPosition(entry.position) }
            guard identities.insert(entry.id).inserted else { throw InfoSpaceError.duplicateID(entry.id) }
            for position in try entry.occupiedPositions(in: grid) where !positions.insert(position).inserted {
                throw InfoSpaceError.occupiedPosition(position)
            }
        }
        self.grid = grid
        self.entries = entries
    }

    init(denseGrid: SpaceGrid) {
        grid = denseGrid
        entries = Self.denseEntries(in: denseGrid)
    }

    public func space(at position: SpacePosition) -> SpaceID? {
        entries.first { (try? $0.occupiedPositions(in: grid).contains(position)) == true }?.id
    }

    public func position(of space: SpaceID) -> SpacePosition? {
        entries.first { $0.id == space }?.position
    }

    public var hasSpans: Bool { entries.contains { $0.span != .cell } }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            grid: values.decode(SpaceGrid.self, forKey: .grid),
            entries: values.decode([SpaceEntry].self, forKey: .entries))
    }

    /// A restored state cannot remove, relocate or weaken an existing protected entry.
    public func validatePreservingConstraints(of original: SpaceLayout) throws {
        for entry in original.entries where !entry.allowsMove || !entry.allowsRemoval {
            guard let replacement = entries.first(where: { $0.id == entry.id }) else {
                if !entry.allowsRemoval { throw InfoSpaceError.protectedSpace(entry.id) }
                continue
            }
            guard replacement.allowsMove == entry.allowsMove,
                replacement.allowsRemoval == entry.allowsRemoval,
                replacement.span == entry.span,
                entry.allowsMove || replacement.position == entry.position
            else { throw InfoSpaceError.protectedSpace(entry.id) }
        }
    }

    private static func denseEntries(in grid: SpaceGrid) -> [SpaceEntry] {
        grid.positions.map {
            SpaceEntry(id: SpaceID(row: $0.row, column: $0.column), position: $0)
        }
    }
}
