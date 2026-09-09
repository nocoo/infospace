import Foundation
import Observation

@MainActor @Observable
public final class InfoSpaceModel {
    public internal(set) var layout: SpaceLayout
    public internal(set) var presentationRevision = 0
    public internal(set) var revision: UInt64 = 0
    public internal(set) var lastError: InfoSpaceError?
    public var commandHandler: (@MainActor (SpaceCommand, UInt64) -> Void)?
    public var snapshot: SpaceSnapshot {
        // All mutation paths validate before installing these fields.
        get throws { try SpaceSnapshot(layout: layout, revision: revision, minimized: minimized, maximized: maximized) }
    }
    public var grid: SpaceGrid { layout.grid }
    public internal(set) var minimized: Set<SpaceID> = []
    public internal(set) var maximized: SpaceID?
    public var showsGrid = false
    public internal(set) var dragPreview: DividerPreview?
    /// Target changes only at gesture boundaries; chrome need not observe every pointer tick.
    public private(set) var activeDivider: DividerTarget?

    public init(rows: Int = 2, columns: Int = 2, fillEmptyCells: Bool = true) {
        layout = SpaceLayout(rows: rows, columns: columns, fillEmptyCells: fillEmptyCells)
    }

    public init(layout: SpaceLayout) { self.layout = layout }

    public init(snapshot: SpaceSnapshot) throws {
        try snapshot.validate()
        layout = snapshot.layout
        revision = snapshot.revision
        minimized = snapshot.minimized
        maximized = snapshot.maximized
    }

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
        next.entries.removeAll { (try? $0.occupiedPositions(in: next.grid)) == nil }
        var identities = Set(next.entries.map(\.id))
        for position in next.grid.positions where next.space(at: position) == nil {
            let seeded = SpaceID(row: position.row, column: position.column)
            let identity = identities.contains(seeded) ? SpaceID() : seeded
            identities.insert(identity)
            next.entries.append(SpaceEntry(id: identity, position: position))
        }
        guard next != layout else { return }
        do {
            let valid = try SpaceLayout(grid: next.grid, entries: next.entries)
            try valid.validatePreservingConstraints(of: layout)
            try request(.restoreSnapshot(SpaceSnapshot(layout: valid)))
        } catch { lastError = error as? InfoSpaceError ?? .invalidSnapshot }
    }

    public func balance() { perform(.layout([.balance])) }

    public func beginDrag(_ target: DividerTarget) {
        guard maximized == nil, target.column != nil || target.row != nil,
            target.column.map({ grid.columns.dividers.indices.contains($0) }) ?? true,
            target.row.map({ grid.rows.dividers.indices.contains($0) }) ?? true
        else { return }
        activeDivider = target
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
        do {
            let command = SpaceLayoutCommand.divider(target, columnTick: columnTick, rowTick: rowTick)
            guard try layout.applying(command) != layout else { return false }
            try request(.layout([command]))
            return true
        } catch {
            lastError = error as? InfoSpaceError ?? .invalidSnapshot
            return false
        }
    }

    /// Snap once, after the final mouse-up position has been included in the preview.
    public func endDrag() {
        guard let preview = dragPreview else { return }
        move(
            preview.target, columnTick: preview.columnTick.map { Int($0.rounded()) },
            rowTick: preview.rowTick.map { Int($0.rounded()) })
    }

    public func cancelDrag() {
        dragPreview = nil
        activeDivider = nil
    }

    public func maximize(_ space: SpaceID) { perform(.maximize(space)) }
    public func minimize(_ space: SpaceID) { perform(.minimize(space)) }
    public func restore(_ space: SpaceID) { perform(.restore(space)) }
    public func restoreLayout() { perform(.restoreLayout) }
    public func restoreAll() { perform(.restoreAll) }
}
