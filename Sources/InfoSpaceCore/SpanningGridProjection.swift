import CoreGraphics

/// Spans share global tracks so row-local reflow can never stretch a panel across its neighbour.
/// A track occupied entirely by minimized panels collapses; empty cells remain available to the host.
struct SpanningGridProjection {
    private(set) var frames: [SpaceID: CGRect] = [:]
    private(set) var emptyCells: [SpaceCell] = []
    private(set) var dividers: [SpaceDivider] = []
    private(set) var intersections: [SpaceIntersection] = []
    private let occupants: [SpacePosition: SpaceID]
    private let minimized: Set<SpaceID>
    private let rows: [Track]
    private let columns: [Track]
    private let gutter: CGFloat

    init(
        layout: SpaceLayout, minimized: Set<SpaceID>, bounds: CGRect,
        preview: DividerPreview?, metrics: SpaceLayoutMetrics
    ) {
        let occupants = Dictionary(
            uniqueKeysWithValues: layout.grid.positions.compactMap { position in
                layout.space(at: position).map { (position, $0) }
            })
        self.occupants = occupants
        self.minimized = minimized
        gutter = min(metrics.gutter, min(bounds.width, bounds.height) / CGFloat(SnapAxis.resolution) * 1.6)
        let available = layout.grid.positions.filter { occupants[$0].map { !minimized.contains($0) } ?? true }
        rows = Self.tracks(
            axis: layout.grid.rows, visible: Set(available.map(\.row)), length: bounds.height,
            previewIndex: preview?.target.row, previewTick: preview?.rowTick)
        columns = Self.tracks(
            axis: layout.grid.columns, visible: Set(available.map(\.column)), length: bounds.width,
            previewIndex: preview?.target.column, previewTick: preview?.columnTick)
        guard bounds.width > 0, bounds.height > 0 else { return }
        for row in rows {
            for column in columns { appendCell(row: row, column: column) }
        }
        appendDividers()
    }

    private mutating func appendCell(row: Track, column: Track) {
        let position = SpacePosition(row: row.index, column: column.index)
        let identity = occupants[position]
        guard identity.map({ !minimized.contains($0) }) ?? true else { return }
        let frame = CGRect(
            x: column.start + (column.first ? 0 : gutter / 2),
            y: row.start + (row.first ? 0 : gutter / 2),
            width: max(0, column.end - column.start - (column.first ? 0 : gutter / 2) - (column.last ? 0 : gutter / 2)),
            height: max(0, row.end - row.start - (row.first ? 0 : gutter / 2) - (row.last ? 0 : gutter / 2)))
        if let identity {
            frames[identity] = frames[identity].map { $0.union(frame) } ?? frame
        } else {
            emptyCells.append(SpaceCell(position: position, frame: frame))
        }
    }

    private mutating func appendDividers() {
        for (rowOffset, row) in rows.enumerated() {
            for (columnOffset, column) in columns.enumerated() {
                let position = SpacePosition(row: row.index, column: column.index)
                let nextColumn = columnOffset + 1 < columns.count ? columns[columnOffset + 1].index : nil
                let right = nextColumn.map { SpacePosition(row: row.index, column: $0) }
                if let right, separates(position, right) {
                    dividers.append(
                        SpaceDivider(
                            id: "column-\(column.index)-row-\(row.index)", target: DividerTarget(column: column.index),
                            frame: CGRect(x: column.end - 6, y: row.start, width: 12, height: row.end - row.start)))
                }
                let nextRow = rowOffset + 1 < rows.count ? rows[rowOffset + 1].index : nil
                let below = nextRow.map { SpacePosition(row: $0, column: column.index) }
                if let below, separates(position, below) {
                    dividers.append(
                        SpaceDivider(
                            id: "row-\(row.index)-column-\(column.index)", target: DividerTarget(row: row.index),
                            frame: CGRect(x: column.start, y: row.end - 6, width: column.end - column.start, height: 12)
                        ))
                }
            }
        }
        for row in rows.dropLast() {
            for column in columns.dropLast() {
                let point = CGPoint(x: column.end, y: row.end)
                let horizontal = dividers.contains { $0.target.row == row.index && $0.frame.contains(point) }
                let vertical = dividers.contains { $0.target.column == column.index && $0.frame.contains(point) }
                if horizontal && vertical {
                    intersections.append(
                        SpaceIntersection(
                            id: "join-\(row.index)-\(column.index)",
                            target: DividerTarget(column: column.index, row: row.index), center: point))
                }
            }
        }
    }

    private func separates(_ first: SpacePosition, _ second: SpacePosition) -> Bool {
        guard let identity = occupants[first] else { return true }
        return identity != occupants[second]
    }

    private static func tracks(
        axis: SnapAxis, visible: Set<Int>, length: CGFloat, previewIndex: Int?, previewTick: Double?
    ) -> [Track] {
        var stops = axis.stops.map(Double.init)
        if let previewIndex, let previewTick, let tick = axis.clampedTick(at: previewIndex, to: previewTick) {
            stops[previewIndex + 1] = tick
        }
        let indices = visible.sorted()
        return indices.enumerated().map { offset, index in
            let start = offset == 0 ? 0 : stops[indices[offset - 1] + 1]
            let end = offset == indices.count - 1 ? Double(SnapAxis.resolution) : stops[index + 1]
            return Track(
                index: index, start: CGFloat(start / Double(SnapAxis.resolution)) * length,
                end: CGFloat(end / Double(SnapAxis.resolution)) * length,
                first: offset == 0, last: offset == indices.count - 1)
        }
    }

    private struct Track {
        let index: Int
        let start: CGFloat
        let end: CGFloat
        let first: Bool
        let last: Bool
    }
}
