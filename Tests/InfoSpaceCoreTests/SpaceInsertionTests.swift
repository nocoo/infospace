import InfoSpaceCore
import Testing

@MainActor
struct SpaceInsertionTests {
    @Test func insertionIntoAnEmptyCellKeepsItsExactPosition() throws {
        let model = InfoSpaceModel(rows: 2, columns: 4, fillEmptyCells: false)
        let identity = SpaceID("inbox")
        let position = SpacePosition(row: 1, column: 3)
        let revision = model.presentationRevision
        #expect(try model.insertSpace(identity, at: position) == identity)
        #expect(model.space(at: position) == identity)
        #expect(model.position(of: identity) == position)
        #expect(model.spaces == [identity])
        #expect(model.grid == SpaceGrid(rows: 2, columns: 4))
        #expect(model.presentationRevision > revision)
    }

    @Test func insertionShiftsOccupantsAndRetainsTheirIdentitiesAndState() throws {
        let model = InfoSpaceModel()
        let original = model.spaces
        model.minimize(original[1])
        model.maximize(original[2])
        try model.insertSpace(SpaceID("new"), at: SpacePosition(row: 0, column: 1))
        #expect(model.grid.rows.count == 3)
        #expect(model.space(at: SpacePosition(row: 0, column: 0)) == original[0])
        #expect(model.space(at: SpacePosition(row: 0, column: 1)) == SpaceID("new"))
        #expect(model.space(at: SpacePosition(row: 1, column: 0)) == original[1])
        #expect(model.space(at: SpacePosition(row: 1, column: 1)) == original[2])
        #expect(model.space(at: SpacePosition(row: 2, column: 0)) == original[3])
        #expect(model.spaces.filter { $0 != SpaceID("new") } == original)
        #expect(model.minimized == [original[1]])
        #expect(model.maximized == nil)
    }

    @Test func aShiftWrapsToAnEarlierVacancyBeforeGrowing() throws {
        let model = InfoSpaceModel()
        let first = model.spaces[0]
        let last = model.spaces[3]
        try model.removeSpace(first)
        try model.insertSpace(SpaceID("new"), at: SpacePosition(row: 1, column: 1))
        #expect(model.position(of: last) == SpacePosition(row: 0, column: 0))
        #expect(model.grid == SpaceGrid())
        #expect(model.spaces.count == 4)
    }

    @Test func insertionCanGrowBothAxesToReachTheRequestedCell() throws {
        let model = InfoSpaceModel(rows: 1, columns: 1, fillEmptyCells: false)
        try model.insertSpace(SpaceID("corner"), at: SpacePosition(row: 7, column: 7))
        #expect(model.grid == SpaceGrid(rows: 8, columns: 8))
        #expect(model.position(of: SpaceID("corner")) == SpacePosition(row: 7, column: 7))
        #expect(model.spaces.count == 1)
    }

    @Test func aFullGridAtTheRowLimitGrowsAColumn() throws {
        let model = InfoSpaceModel(rows: 8, columns: 1)
        let original = model.spaces
        try model.insertSpace(SpaceID("new"), at: SpacePosition(row: 7, column: 0))
        #expect(model.grid.rows.count == 8)
        #expect(model.grid.columns.count == 2)
        #expect(model.position(of: original[7]) == SpacePosition(row: 7, column: 1))
        #expect(Set(original).isSubset(of: Set(model.spaces)))
    }

    @Test func rejectingAnOccupiedCellIsAtomicIncludingAnActiveDrag() {
        let model = InfoSpaceModel()
        let target = DividerTarget(column: 0, row: 0)
        model.beginDrag(target)
        model.updateDrag(target, columnTick: 12.3, rowTick: 19.7)
        let before = model.layout
        let preview = model.dragPreview
        let revision = model.presentationRevision
        let position = SpacePosition(row: 0, column: 0)
        #expect(throws: InfoSpaceError.occupiedPosition(position)) {
            try model.insertSpace(at: position, collision: .reject)
        }
        #expect(model.layout == before)
        #expect(model.dragPreview == preview)
        #expect(model.presentationRevision == revision)
    }

    @Test func duplicateIdentityIsRejectedEvenAtAVacantPosition() throws {
        let model = InfoSpaceModel(rows: 2, columns: 2, fillEmptyCells: false)
        let identity = try model.insertSpace(SpaceID("same"), at: SpacePosition(row: 0, column: 0))
        let before = model.layout
        #expect(throws: InfoSpaceError.duplicateID(identity)) {
            try model.insertSpace(identity, at: SpacePosition(row: 1, column: 1))
        }
        #expect(model.layout == before)
    }

    @Test(arguments: [
        SpacePosition(row: -1, column: 0), SpacePosition(row: 8, column: 0),
        SpacePosition(row: 0, column: -1), SpacePosition(row: 0, column: .max),
    ])
    func invalidInsertionCoordinatesCannotChangeTheLayout(position: SpacePosition) {
        let model = InfoSpaceModel()
        let before = model.layout
        #expect(throws: InfoSpaceError.invalidPosition(position)) { try model.insertSpace(at: position) }
        #expect(model.layout == before)
    }

    @Test func capacityFailureDoesNotLoseAnySpaceOrPresentationState() {
        let model = InfoSpaceModel(rows: 8, columns: 8)
        model.minimize(model.spaces[0])
        model.maximize(model.spaces[1])
        let before = model.layout
        let minimized = model.minimized
        let focus = model.maximized
        #expect(throws: InfoSpaceError.capacityExceeded) {
            try model.insertSpace(at: SpacePosition(row: 4, column: 4))
        }
        #expect(model.layout == before)
        #expect(model.minimized == minimized)
        #expect(model.maximized == focus)
    }

    @Test func repeatedInsertionsKeepUniquePositionsThroughAllGrowthBoundaries() throws {
        let model = InfoSpaceModel(rows: 1, columns: 1, fillEmptyCells: false)
        for index in 0..<64 {
            try model.insertSpace(SpaceID("item-\(index)"), at: SpacePosition(row: 0, column: 0))
            #expect(model.spaces.count == index + 1)
            #expect(Set(model.layout.entries.map(\.position)).count == index + 1)
            #expect(model.layout.entries.allSatisfy { model.grid.contains($0.position) })
            #expect(model.space(at: SpacePosition(row: 0, column: 0)) == SpaceID("item-\(index)"))
        }
        #expect(model.grid == SpaceGrid(rows: 8, columns: 8))
    }
}
