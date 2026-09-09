import Foundation
import Observation

@MainActor @Observable
public final class InfoSpaceModel {
    public private(set) var layout: SpaceLayout
    public private(set) var presentationRevision = 0
    public var grid: SpaceGrid { layout.grid }
    public private(set) var minimized: Set<SpaceID> = []
    public private(set) var maximized: SpaceID?
    public var showsGrid = false
    public private(set) var dragPreview: DividerPreview?
    public var activeDivider: DividerTarget? { dragPreview?.target }

    public init(rows: Int = 2, columns: Int = 2, fillEmptyCells: Bool = true) {
        layout = SpaceLayout(rows: rows, columns: columns, fillEmptyCells: fillEmptyCells)
    }

    public init(layout: SpaceLayout) { self.layout = layout }

    public var spaces: [SpaceID] { layout.entries.map(\.id) }

    public func space(at position: SpacePosition) -> SpaceID? { layout.space(at: position) }
    public func position(of space: SpaceID) -> SpacePosition? { layout.position(of: space) }
    public var visibleCount: Int { maximized == nil ? spaces.count - minimized.count : 1 }

    /// Rebuild a dense grid, retaining IDs at surviving positions and filling vacant cells.
    /// Cells outside the new dimensions are removed. Use `resizeGrid` to preserve all spaces.
    public func setDimensions(rows: Int, columns: Int) {
        var next = layout
        if next.grid.rows.count != min(8, max(1, rows)) { next.grid.rows = SnapAxis(count: rows) }
        if next.grid.columns.count != min(8, max(1, columns)) { next.grid.columns = SnapAxis(count: columns) }
        next.entries.removeAll { !next.grid.contains($0.position) }
        var identities = Set(next.entries.map(\.id))
        for position in next.grid.positions where next.space(at: position) == nil {
            let seeded = SpaceID(row: position.row, column: position.column)
            let identity = identities.contains(seeded) ? SpaceID() : seeded
            identities.insert(identity)
            next.entries.append(SpaceEntry(id: identity, position: position))
        }
        guard next != layout else { return }
        applyLayout(next)
    }

    public func balance() {
        cancelDrag()
        layout.grid = SpaceGrid(rows: grid.rows.count, columns: grid.columns.count)
        presentationRevision &+= 1
    }

    func applyLayout(_ next: SpaceLayout) {
        cancelDrag()
        maximized = nil
        minimized.formIntersection(Set(next.entries.map(\.id)))
        layout = next
        presentationRevision &+= 1
    }

    public func beginDrag(_ target: DividerTarget) {
        guard maximized == nil, target.column != nil || target.row != nil,
            target.column.map({ grid.columns.dividers.indices.contains($0) }) ?? true,
            target.row.map({ grid.rows.dividers.indices.contains($0) }) ?? true
        else { return }
        dragPreview = DividerPreview(
            target: target,
            columnTick: target.column.map { Double(grid.columns.dividers[$0]) },
            rowTick: target.row.map { Double(grid.rows.dividers[$0]) })
    }

    /// Follow the pointer continuously; the committed grid stays unchanged until release.
    @discardableResult
    public func updateDrag(_ target: DividerTarget, columnTick: Double?, rowTick: Double?) -> Bool {
        guard let preview = dragPreview, preview.target == target, maximized == nil else { return false }
        let column =
            target.column.flatMap { index in
                columnTick.flatMap { grid.columns.clampedTick(at: index, to: $0) }
            } ?? preview.columnTick
        let row =
            target.row.flatMap { index in
                rowTick.flatMap { grid.rows.clampedTick(at: index, to: $0) }
            } ?? preview.rowTick
        let next = DividerPreview(target: target, columnTick: column, rowTick: row)
        guard next != preview else { return false }
        dragPreview = next
        return true
    }

    /// Apply both axes in one observation update so intersections never tear.
    @discardableResult
    public func move(_ target: DividerTarget, columnTick: Int?, rowTick: Int?) -> Bool {
        guard maximized == nil else { return false }
        cancelDrag()
        var next = grid
        if let index = target.column, let columnTick { next.columns.moveDivider(at: index, to: columnTick) }
        if let index = target.row, let rowTick { next.rows.moveDivider(at: index, to: rowTick) }
        guard next != grid else { return false }
        layout.grid = next
        return true
    }

    /// Snap once, after the final mouse-up position has been included in the preview.
    public func endDrag() {
        guard let preview = dragPreview else { return }
        move(
            preview.target, columnTick: preview.columnTick.map { Int($0.rounded()) },
            rowTick: preview.rowTick.map { Int($0.rounded()) })
    }

    public func cancelDrag() { dragPreview = nil }

    public func maximize(_ space: SpaceID) {
        guard spaces.contains(space) else { return }
        cancelDrag()
        minimized.remove(space)
        maximized = maximized == space ? nil : space
        presentationRevision &+= 1
    }

    public func minimize(_ space: SpaceID) {
        guard spaces.contains(space) else { return }
        cancelDrag()
        minimized.insert(space)
        if maximized == space { maximized = nil }
        presentationRevision &+= 1
    }

    /// Any edge banner exits focus mode; explicitly minimized panels restore individually.
    public func restore(_ space: SpaceID) {
        guard spaces.contains(space) else { return }
        cancelDrag()
        minimized.remove(space)
        maximized = nil
        presentationRevision &+= 1
    }

    public func restoreLayout() {
        cancelDrag()
        maximized = nil
        presentationRevision &+= 1
    }

    public func restoreAll() {
        cancelDrag()
        minimized.removeAll()
        maximized = nil
        presentationRevision &+= 1
    }
}
