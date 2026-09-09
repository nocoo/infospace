import InfoSpaceCore
import Testing

@MainActor
struct SpaceMutationTests {
    @Test func movingToAnOccupiedCellSwapsIdentitiesAndPreservesMinimizedState() throws {
        let model = InfoSpaceModel()
        let first = model.spaces[0]
        let last = model.spaces[3]
        model.minimize(first)
        try model.moveSpace(first, to: SpacePosition(row: 1, column: 1))
        #expect(model.position(of: first) == SpacePosition(row: 1, column: 1))
        #expect(model.position(of: last) == SpacePosition(row: 0, column: 0))
        #expect(model.spaces.count == 4)
        #expect(model.minimized == [first])
    }

    @Test func movingCanGrowTheGridWithoutChangingTheOtherPositions() throws {
        let model = InfoSpaceModel()
        let first = model.spaces[0]
        let unchanged = Array(model.layout.entries.dropFirst())
        try model.moveSpace(first, to: SpacePosition(row: 3, column: 4))
        #expect(model.grid == SpaceGrid(rows: 4, columns: 5))
        #expect(model.space(at: SpacePosition(row: 0, column: 0)) == nil)
        #expect(model.position(of: first) == SpacePosition(row: 3, column: 4))
        #expect(Array(model.layout.entries.dropFirst()) == unchanged)
    }

    @Test func rejectedMovesDoNotMutateAnything() {
        let model = InfoSpaceModel()
        let first = model.spaces[0]
        let occupied = SpacePosition(row: 1, column: 1)
        let invalid = SpacePosition(row: 8, column: 1)
        let before = model.layout
        #expect(throws: InfoSpaceError.occupiedPosition(occupied)) {
            try model.moveSpace(first, to: occupied, collision: .reject)
        }
        #expect(throws: InfoSpaceError.invalidPosition(invalid)) { try model.moveSpace(first, to: invalid) }
        #expect(throws: InfoSpaceError.unknownSpace(SpaceID("missing"))) {
            try model.moveSpace(SpaceID("missing"), to: occupied)
        }
        #expect(model.layout == before)
        #expect(model.presentationRevision == 0)
    }

    @Test func removalCleansPresentationStateAndCanLeaveAnEmptyWorkspace() throws {
        let model = InfoSpaceModel(rows: 1, columns: 2)
        let first = model.spaces[0]
        let second = model.spaces[1]
        model.minimize(first)
        try model.removeSpace(first)
        #expect(model.minimized.isEmpty)
        model.maximize(second)
        try model.removeSpace(second)
        #expect(model.spaces.isEmpty)
        #expect(model.visibleCount == 0)
        #expect(model.maximized == nil)
        #expect(throws: InfoSpaceError.unknownSpace(first)) { try model.removeSpace(first) }
        try model.insertSpace(first, at: SpacePosition(row: 0, column: 1))
        #expect(model.visibleCount == 1)
    }

    @Test func resizingPreservesEverySpaceAndOnlyRelocatesOutOfBoundsEntries() throws {
        let model = InfoSpaceModel(rows: 2, columns: 3)
        let original = model.spaces
        model.minimize(original[2])
        try model.resizeGrid(rows: 3, columns: 2)
        #expect(model.spaces == original)
        #expect(model.position(of: original[0]) == SpacePosition(row: 0, column: 0))
        #expect(model.position(of: original[1]) == SpacePosition(row: 0, column: 1))
        #expect(model.position(of: original[3]) == SpacePosition(row: 1, column: 0))
        #expect(model.position(of: original[4]) == SpacePosition(row: 1, column: 1))
        #expect(model.position(of: original[2]) == SpacePosition(row: 2, column: 0))
        #expect(model.position(of: original[5]) == SpacePosition(row: 2, column: 1))
        #expect(model.minimized == [original[2]])
    }

    @Test func safeResizeExpansionLeavesVacanciesAndPreservesAnUnchangedAxis() throws {
        let model = InfoSpaceModel()
        try model.setProportions(rows: [1, 3])
        let original = model.layout.entries
        try model.resizeGrid(rows: 2, columns: 4)
        #expect(model.layout.entries == original)
        #expect(model.spaces.count == 4)
        #expect(model.space(at: SpacePosition(row: 0, column: 3)) == nil)
        #expect(model.grid.rows.dividers == [8])
    }

    @Test func invalidOrUndersizedResizeCannotDeleteUserData() {
        let model = InfoSpaceModel()
        let before = model.layout
        #expect(throws: InfoSpaceError.capacityExceeded) { try model.resizeGrid(rows: 1, columns: 3) }
        #expect(throws: InfoSpaceError.invalidDimensions) { try model.resizeGrid(rows: 0, columns: 3) }
        #expect(throws: InfoSpaceError.invalidDimensions) { try model.resizeGrid(rows: .max, columns: .max) }
        #expect(model.layout == before)
    }

    @Test func ratioUpdatesAreAtomicAndDoNotMoveIdentities() throws {
        let model = InfoSpaceModel()
        let entries = model.layout.entries
        try model.setProportions(rows: [1, 3], columns: [3, 1])
        #expect(model.grid.rows.dividers == [8])
        #expect(model.grid.columns.dividers == [24])
        #expect(model.layout.entries == entries)
        let before = model.layout
        #expect(throws: InfoSpaceError.invalidProportions) {
            try model.setProportions(rows: [1, 1], columns: [0, 1])
        }
        #expect(throws: InfoSpaceError.invalidProportions) { try model.setProportions(rows: [1, 1, 1]) }
        #expect(model.layout == before)
    }

    @Test func noOpMutationsDoNotRestartLayoutAnimations() throws {
        let model = InfoSpaceModel()
        let revision = model.presentationRevision
        try model.moveSpace(model.spaces[0], to: SpacePosition(row: 0, column: 0))
        try model.resizeGrid(rows: 2, columns: 2)
        try model.setProportions(rows: [1, 1], columns: [1, 1])
        #expect(model.presentationRevision == revision)
    }

    @Test func committedDividerMovementDoesNotTriggerTheStructuralAnimation() {
        let model = InfoSpaceModel()
        let revision = model.presentationRevision
        model.beginDrag(DividerTarget(column: 0))
        model.updateDrag(DividerTarget(column: 0), columnTick: 12.4, rowTick: nil)
        model.endDrag()
        #expect(model.grid.columns.dividers == [12])
        #expect(model.presentationRevision == revision)
    }
}
