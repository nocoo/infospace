import Foundation
import InfoSpaceCore
import Observation
import Synchronization
import Testing

@MainActor
struct InfoSpaceModelTests {
    @Test func pointerTicksDoNotInvalidateGestureTargetObservers() {
        let model = InfoSpaceModel()
        let target = DividerTarget(column: 0)
        model.beginDrag(target)
        let changes = Mutex(0)
        withObservationTracking {
            _ = model.activeDivider
        } onChange: {
            changes.withLock { $0 += 1 }
        }
        for step in 1...30 {
            model.updateDrag(target, columnTick: 12 + Double(step) / 10, rowTick: nil)
            #expect(model.activeDivider == target)
        }
        #expect(changes.withLock { $0 } == 0)
        model.cancelDrag()
        #expect(changes.withLock { $0 } == 1)
        #expect(model.activeDivider == nil && model.dragPreview == nil)
    }

    @Test func anIntersectionUpdatesBothAxesAndIgnoresRepeatedTicks() {
        let model = InfoSpaceModel()
        let target = DividerTarget(column: 0, row: 0)
        #expect(model.move(target, columnTick: 11, rowTick: 22))
        #expect(model.grid.columns.dividers == [11])
        #expect(model.grid.rows.dividers == [22])
        #expect(!model.move(target, columnTick: 11, rowTick: 22))
        #expect(model.activeDivider == nil)
    }

    @Test func intersectionMovesFreelyAndOnlySnapsOnRelease() {
        let model = InfoSpaceModel()
        let original = model.grid
        let target = DividerTarget(column: 0, row: 0)
        model.beginDrag(target)
        #expect(model.activeDivider == target)
        #expect(model.updateDrag(target, columnTick: 11.1, rowTick: 22.9))
        #expect(model.dragPreview?.columnTick == 11.1)
        #expect(model.dragPreview?.rowTick == 22.9)
        #expect(model.grid == original)

        // Movement inside the same grid cell must still change the displayed position.
        #expect(model.updateDrag(target, columnTick: 11.4, rowTick: 22.6))
        #expect(model.dragPreview?.columnTick == 11.4)
        #expect(model.dragPreview?.rowTick == 22.6)
        #expect(!model.updateDrag(target, columnTick: 11.4, rowTick: 22.6))
        #expect(model.grid == original)
        model.endDrag()
        #expect(model.grid.columns.dividers == [11])
        #expect(model.grid.rows.dividers == [23])
        #expect(model.dragPreview == nil)
        #expect(model.activeDivider == nil)
    }

    @Test(arguments: [DividerTarget(column: 1), DividerTarget(row: 0)])
    func continuousLineDragsOnlyChangeTheirOwnAxis(target: DividerTarget) {
        let model = InfoSpaceModel(rows: 3, columns: 4)
        let original = model.grid
        model.beginDrag(target)
        model.updateDrag(target, columnTick: 18.7, rowTick: 9.3)
        #expect(model.grid == original)
        #expect(model.dragPreview?.columnTick == (target.column == nil ? nil : 18.7))
        #expect(model.dragPreview?.rowTick == (target.row == nil ? nil : 9.3))
        model.endDrag()
        #expect(model.grid.columns.dividers == (target.column == nil ? [8, 16, 24] : [8, 19, 24]))
        #expect(model.grid.rows.dividers == (target.row == nil ? [11, 21] : [9, 21]))
    }

    @Test func continuousPreviewCannotCrossNeighboursOrShrinkBelowMinimum() {
        let model = InfoSpaceModel(rows: 3, columns: 4)
        let target = DividerTarget(column: 1, row: 0)
        model.beginDrag(target)
        model.updateDrag(target, columnTick: -100, rowTick: 100)
        #expect(model.dragPreview?.columnTick == 10)
        #expect(model.dragPreview?.rowTick == 19)
        model.updateDrag(target, columnTick: 100, rowTick: -100)
        #expect(model.dragPreview?.columnTick == 22)
        #expect(model.dragPreview?.rowTick == 2)
        model.endDrag()
        #expect(model.grid.columns.dividers == [8, 22, 24])
        #expect(model.grid.rows.dividers == [2, 21])
    }

    @Test func cancellingOrChangingLayoutDiscardsThePreview() {
        let model = InfoSpaceModel()
        let target = DividerTarget(column: 0, row: 0)
        let original = model.grid
        let actions: [(InfoSpaceModel) -> Void] = [
            { $0.cancelDrag() }, { $0.balance() },
            { $0.maximize(SpaceID(row: 0, column: 0)) },
            { $0.minimize(SpaceID(row: 0, column: 0)) },
            { $0.restore(SpaceID(row: 0, column: 0)) },
            { $0.restoreLayout() }, { $0.restoreAll() },
        ]
        for action in actions {
            model.restoreAll()
            model.beginDrag(target)
            model.updateDrag(target, columnTick: 11.4, rowTick: 22.6)
            action(model)
            #expect(model.dragPreview == nil)
            model.endDrag()
            #expect(model.grid == original)
        }
        model.beginDrag(target)
        model.updateDrag(target, columnTick: 11.4, rowTick: 22.6)
        model.setDimensions(rows: 3, columns: 4)
        #expect(model.dragPreview == nil)
        model.endDrag()
        #expect(model.grid == SpaceGrid(rows: 3, columns: 4))
    }

    @Test func staleOrInvalidDragEventsDoNotChangeTheLayout() {
        let model = InfoSpaceModel()
        let target = DividerTarget(column: 0)
        model.beginDrag(DividerTarget(column: 9))
        #expect(model.dragPreview == nil)
        model.beginDrag(target)
        #expect(!model.updateDrag(target, columnTick: .nan, rowTick: nil))
        #expect(!model.updateDrag(DividerTarget(row: 0), columnTick: nil, rowTick: 12.3))
        #expect(model.dragPreview?.columnTick == 16)
        model.updateDrag(target, columnTick: 12.5, rowTick: nil)
        model.endDrag()
        #expect(model.grid.columns.dividers == [13])
        #expect(!model.updateDrag(target, columnTick: 20.2, rowTick: nil))
        #expect(model.grid.columns.dividers == [13])
    }

    @Test func lineDragsOnlyChangeTheirOwnAxis() {
        let model = InfoSpaceModel(rows: 3, columns: 4)
        let rows = model.grid.rows
        model.move(DividerTarget(column: 1), columnTick: 19, rowTick: 3)
        #expect(model.grid.columns.dividers == [8, 19, 24])
        #expect(model.grid.rows == rows)
    }

    @Test func focusAndMinimizePreserveCustomProportions() {
        let model = InfoSpaceModel()
        let first = SpaceID(row: 0, column: 0)
        let second = SpaceID(row: 0, column: 1)
        let third = SpaceID(row: 1, column: 0)
        model.move(DividerTarget(column: 0, row: 0), columnTick: 11, rowTick: 23)
        let original = model.grid
        model.minimize(third)
        model.maximize(first)
        #expect(model.maximized == first)
        #expect(model.minimized == [third])
        #expect(!model.move(DividerTarget(column: 0), columnTick: 20, rowTick: nil))
        model.restore(second)
        #expect(model.maximized == nil)
        #expect(model.minimized == [third])
        #expect(model.grid == original)
        model.restore(third)
        #expect(model.minimized.isEmpty)
        #expect(model.grid == original)
    }

    @Test func minimizeFocusedPanelReturnsToOtherPanels() {
        let model = InfoSpaceModel()
        let first = model.spaces[0]
        model.maximize(first)
        model.minimize(first)
        #expect(model.maximized == nil)
        #expect(model.minimized == [first])
        #expect(model.visibleCount == 3)
        model.restoreAll()
        #expect(model.visibleCount == 4)
    }

    @Test func resizingDimensionsRetainsCoordinatesAndUnchangedAxis() {
        let model = InfoSpaceModel()
        let identities = Set(model.spaces)
        model.move(DividerTarget(row: 0), columnTick: nil, rowTick: 12)
        model.setDimensions(rows: 2, columns: 4)
        #expect(model.spaces.count == 8)
        #expect(identities.isSubset(of: Set(model.spaces)))
        #expect(model.grid.rows.dividers == [12])
        model.setDimensions(rows: 3, columns: 4)
        #expect(model.spaces.count == 12)
        model.minimize(SpaceID(row: 2, column: 3))
        model.setDimensions(rows: 1, columns: 1)
        #expect(model.minimized.isEmpty)
        #expect(model.spaces == [SpaceID(row: 0, column: 0)])
    }

    @Test func emptyWorkspaceCanAlwaysRecover() {
        let model = InfoSpaceModel(rows: 1, columns: 1)
        model.minimize(model.spaces[0])
        #expect(model.visibleCount == 0)
        model.restoreAll()
        #expect(model.visibleCount == 1)
        model.setDimensions(rows: 100, columns: -5)
        #expect(model.grid.rows.count == 8)
        #expect(model.grid.columns.count == 1)
    }
}
