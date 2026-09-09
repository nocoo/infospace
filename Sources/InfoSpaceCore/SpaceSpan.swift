import Foundation

/// A panel's occupied cells. Full-axis spans grow with the grid and start at its edge.
public enum SpaceSpan: Codable, Equatable, Sendable {
    case cell
    case rectangle(rows: Int, columns: Int)
    case fullHeight(columns: Int)
    case fullWidth(rows: Int)

    func dimensions(in grid: SpaceGrid, at position: SpacePosition) throws -> (rows: Int, columns: Int) {
        let dimensions: (rows: Int, columns: Int)
        switch self {
        case .cell: dimensions = (1, 1)
        case .rectangle(let rows, let columns): dimensions = (rows, columns)
        case .fullHeight(let columns):
            guard position.row == 0 else { throw InfoSpaceError.invalidSpan }
            dimensions = (grid.rows.count, columns)
        case .fullWidth(let rows):
            guard position.column == 0 else { throw InfoSpaceError.invalidSpan }
            dimensions = (rows, grid.columns.count)
        }
        guard grid.contains(position), dimensions.rows > 0, dimensions.columns > 0,
            dimensions.rows <= grid.rows.count - position.row,
            dimensions.columns <= grid.columns.count - position.column
        else { throw InfoSpaceError.invalidSpan }
        return dimensions
    }
}

extension SpaceEntry {
    public func occupiedPositions(in grid: SpaceGrid) throws -> [SpacePosition] {
        let dimensions = try span.dimensions(in: grid, at: position)
        return (position.row..<(position.row + dimensions.rows)).flatMap { row in
            (position.column..<(position.column + dimensions.columns)).map {
                SpacePosition(row: row, column: $0)
            }
        }
    }
}
