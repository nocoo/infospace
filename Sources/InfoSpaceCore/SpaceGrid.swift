import Foundation

public struct DividerTarget: Hashable, Sendable {
    public let column: Int?
    public let row: Int?
    public var isIntersection: Bool { column != nil && row != nil }

    public init(column: Int? = nil, row: Int? = nil) {
        self.column = column
        self.row = row
    }
}

/// Temporary geometry while the pointer is down. Both axes update together.
public struct DividerPreview: Equatable, Sendable {
    public let target: DividerTarget
    public let columnTick: Double?
    public let rowTick: Double?
}

public struct SpaceGrid: Equatable, Sendable {
    public var rows: SnapAxis
    public var columns: SnapAxis

    public init(rows: Int = 2, columns: Int = 2) {
        self.rows = SnapAxis(count: rows)
        self.columns = SnapAxis(count: columns)
    }

    public var positions: [SpacePosition] {
        (0..<rows.count).flatMap { row in
            (0..<columns.count).map { SpacePosition(row: row, column: $0) }
        }
    }

    /// The deterministic IDs created by the dense-grid convenience initializer.
    public var spaces: [SpaceID] {
        positions.map { SpaceID(row: $0.row, column: $0.column) }
    }

    public func contains(_ position: SpacePosition) -> Bool {
        (0..<rows.count).contains(position.row) && (0..<columns.count).contains(position.column)
    }
}
