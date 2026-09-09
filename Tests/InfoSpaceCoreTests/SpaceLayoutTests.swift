import InfoSpaceCore
import Testing

struct SpaceLayoutTests {
    @Test func aLayoutAcceptsCustomStableIDsAndUnassignedCells() throws {
        let entry = SpaceEntry(id: SpaceID("mail"), position: SpacePosition(row: 1, column: 2))
        let layout = try SpaceLayout(grid: SpaceGrid(rows: 2, columns: 3), entries: [entry])
        #expect(layout.space(at: entry.position) == entry.id)
        #expect(layout.position(of: entry.id) == entry.position)
        #expect(layout.space(at: SpacePosition(row: 0, column: 0)) == nil)
        #expect(layout.position(of: SpaceID("absent")) == nil)
    }

    @Test func aLayoutRejectsConflictingIdentitiesPositionsAndOutOfBoundsEntries() {
        let first = SpaceEntry(id: SpaceID("first"), position: SpacePosition(row: 0, column: 0))
        let duplicateID = SpaceEntry(id: first.id, position: SpacePosition(row: 1, column: 1))
        let duplicatePosition = SpaceEntry(id: SpaceID("second"), position: first.position)
        let outside = SpaceEntry(id: SpaceID("outside"), position: SpacePosition(row: 2, column: 0))
        #expect(throws: InfoSpaceError.duplicateID(first.id)) {
            try SpaceLayout(grid: SpaceGrid(), entries: [first, duplicateID])
        }
        #expect(throws: InfoSpaceError.occupiedPosition(first.position)) {
            try SpaceLayout(grid: SpaceGrid(), entries: [first, duplicatePosition])
        }
        #expect(throws: InfoSpaceError.invalidPosition(outside.position)) {
            try SpaceLayout(grid: SpaceGrid(), entries: [outside])
        }
    }
}
