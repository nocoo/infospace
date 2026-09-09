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

public struct SpaceEntry: Identifiable, Equatable, Sendable {
    public let id: SpaceID
    public internal(set) var position: SpacePosition

    public init(id: SpaceID, position: SpacePosition) {
        self.id = id
        self.position = position
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
}

/// A value snapshot of the committed grid and the identities assigned to its cells.
public struct SpaceLayout: Equatable, Sendable {
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
            guard positions.insert(entry.position).inserted else {
                throw InfoSpaceError.occupiedPosition(entry.position)
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
        entries.first { $0.position == position }?.id
    }

    public func position(of space: SpaceID) -> SpacePosition? {
        entries.first { $0.id == space }?.position
    }

    private static func denseEntries(in grid: SpaceGrid) -> [SpaceEntry] {
        grid.positions.map {
            SpaceEntry(id: SpaceID(row: $0.row, column: $0.column), position: $0)
        }
    }
}
