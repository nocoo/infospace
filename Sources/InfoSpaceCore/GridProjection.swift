import CoreGraphics

/// Compute the grid once, including sparse cells and cells vacated by minimized panels.
struct GridProjection {
    private(set) var frames: [SpaceID: CGRect] = [:]
    private(set) var emptyCells: [SpaceCell] = []
    private(set) var dividers: [SpaceDivider] = []
    private(set) var intersections: [SpaceIntersection] = []
    private var verticalIndicesByRow: [Int: Set<Int>] = [:]
    private var visibleRows: [Int] = []
    private let layout: SpaceLayout
    private let minimized: Set<SpaceID>
    private let occupants: [SpacePosition: SpaceID]
    private let bounds: CGRect
    private let rowStops: [Double]
    private let columnStops: [Double]
    private let gutter: CGFloat

    init(
        layout: SpaceLayout, minimized: Set<SpaceID>, bounds: CGRect,
        preview: DividerPreview?, metrics: SpaceLayoutMetrics
    ) {
        self.layout = layout
        self.minimized = minimized
        self.bounds = bounds
        occupants = Dictionary(uniqueKeysWithValues: layout.entries.map { ($0.position, $0.id) })
        rowStops = Self.stops(layout.grid.rows, index: preview?.target.row, tick: preview?.rowTick)
        columnStops = Self.stops(layout.grid.columns, index: preview?.target.column, tick: preview?.columnTick)
        gutter = min(metrics.gutter, min(bounds.width, bounds.height) / CGFloat(SnapAxis.resolution) * 1.6)
        guard bounds.width > 0, bounds.height > 0 else { return }
        visibleRows = (0..<layout.grid.rows.count).filter { !availableColumns(in: $0).isEmpty }
        for (position, row) in visibleRows.enumerated() { appendRow(row, at: position) }
        appendIntersections()
    }

    private func availableColumns(in row: Int) -> [Int] {
        (0..<layout.grid.columns.count).filter { column in
            guard let space = occupants[SpacePosition(row: row, column: column)] else { return true }
            return !minimized.contains(space)
        }
    }

    private mutating func appendRow(_ row: Int, at position: Int) {
        let topTick = position == 0 ? 0 : rowStops[visibleRows[position - 1] + 1]
        let bottomTick = position == visibleRows.count - 1 ? Double(SnapAxis.resolution) : rowStops[row + 1]
        let band = RowBand(
            row: row, top: CGFloat(topTick) * unitY, bottom: CGFloat(bottomTick) * unitY,
            isFirst: position == 0, isLast: position == visibleRows.count - 1)
        let columns = availableColumns(in: row)
        for (index, column) in columns.enumerated() { appendCell(column, at: index, columns: columns, band: band) }
        if !band.isLast {
            dividers.append(
                SpaceDivider(
                    id: "row-\(row)", target: DividerTarget(row: row),
                    frame: CGRect(x: 0, y: band.bottom - 6, width: bounds.width, height: 12)))
        }
    }

    private mutating func appendCell(_ column: Int, at index: Int, columns: [Int], band: RowBand) {
        let leftTick = index == 0 ? 0 : columnStops[columns[index - 1] + 1]
        let rightTick = index == columns.count - 1 ? Double(SnapAxis.resolution) : columnStops[column + 1]
        let left = CGFloat(leftTick) * unitX
        let right = CGFloat(rightTick) * unitX
        let insetLeft = index == 0 ? 0 : gutter / 2
        let insetRight = index == columns.count - 1 ? 0 : gutter / 2
        let insetTop = band.isFirst ? 0 : gutter / 2
        let insetBottom = band.isLast ? 0 : gutter / 2
        let position = SpacePosition(row: band.row, column: column)
        let frame = CGRect(
            x: left + insetLeft, y: band.top + insetTop,
            width: max(0, right - left - insetLeft - insetRight),
            height: max(0, band.bottom - band.top - insetTop - insetBottom))
        if let space = occupants[position] {
            frames[space] = frame
        } else {
            emptyCells.append(SpaceCell(position: position, frame: frame))
        }
        if index < columns.count - 1 {
            verticalIndicesByRow[band.row, default: []].insert(column)
            dividers.append(
                SpaceDivider(
                    id: "column-\(column)-row-\(band.row)", target: DividerTarget(column: column),
                    frame: CGRect(x: right - 6, y: band.top, width: 12, height: band.bottom - band.top)))
        }
    }

    private mutating func appendIntersections() {
        for position in 0..<max(0, visibleRows.count - 1) {
            let row = visibleRows[position]
            let nextRow = visibleRows[position + 1]
            let columns = (verticalIndicesByRow[row] ?? []).union(verticalIndicesByRow[nextRow] ?? [])
            for column in columns.sorted() {
                intersections.append(
                    SpaceIntersection(
                        id: "join-\(row)-\(column)",
                        target: DividerTarget(column: column, row: row),
                        center: CGPoint(
                            x: CGFloat(columnStops[column + 1]) * unitX, y: CGFloat(rowStops[row + 1]) * unitY)))
            }
        }
    }

    private static func stops(_ axis: SnapAxis, index: Int?, tick: Double?) -> [Double] {
        var stops = axis.stops.map(Double.init)
        if let index, let tick, let clamped = axis.clampedTick(at: index, to: tick) { stops[index + 1] = clamped }
        return stops
    }

    private var unitX: CGFloat { bounds.width / CGFloat(SnapAxis.resolution) }
    private var unitY: CGFloat { bounds.height / CGFloat(SnapAxis.resolution) }

    private struct RowBand {
        let row: Int
        let top: CGFloat
        let bottom: CGFloat
        let isFirst: Bool
        let isLast: Bool
    }
}
