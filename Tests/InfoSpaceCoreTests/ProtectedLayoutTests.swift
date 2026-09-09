import Foundation
import InfoSpaceCore
import Testing

struct ProtectedLayoutTests {
    let anchor = SpaceID("anchor")

    func layout() throws -> SpaceLayout {
        try SpaceLayout(
            grid: SpaceGrid(rows: 2, columns: 2),
            entries: [
                SpaceEntry(
                    id: anchor, position: .init(row: 0, column: 0), span: .fullHeight(columns: 1),
                    allowsMove: false, allowsRemoval: false),
                SpaceEntry(id: SpaceID("a"), position: .init(row: 0, column: 1)),
                SpaceEntry(id: SpaceID("b"), position: .init(row: 1, column: 1)),
            ])
    }

    @Test func insertionSkipsEveryCellOfProtectedSpanAndGrows() throws {
        let original = try layout()
        let next = try original.applying(
            .insert(
                SpaceEntry(id: SpaceID("new"), position: .init(row: 0, column: 1)), collision: .shiftForward))
        #expect(next.grid.rows.count == 3)
        #expect(next.space(at: .init(row: 2, column: 0)) == anchor)
        #expect(next.position(of: SpaceID("a")) == .init(row: 1, column: 1))
        #expect(next.position(of: SpaceID("b")) == .init(row: 2, column: 1))
        #expect(original.grid.rows.count == 2)
    }

    @Test func protectedEntriesCannotBeRemovedMovedOrWeakened() throws {
        let original = try layout()
        #expect(throws: InfoSpaceError.protectedSpace(anchor)) { try original.applying(.remove(anchor)) }
        #expect(throws: InfoSpaceError.protectedSpace(anchor)) {
            try original.applying(.move(anchor, destination: .init(row: 0, column: 1), collision: .swap))
        }
        #expect(throws: InfoSpaceError.protectedSpace(anchor)) {
            try original.applying(
                .insert(
                    SpaceEntry(id: SpaceID("new"), position: .init(row: 1, column: 0)),
                    collision: .shiftForward))
        }
        let weakened = try SpaceLayout(
            grid: original.grid,
            entries: [
                SpaceEntry(id: anchor, position: .init(row: 0, column: 0))
            ])
        #expect(throws: InfoSpaceError.protectedSpace(anchor)) {
            try weakened.validatePreservingConstraints(of: original)
        }
        #expect(throws: InfoSpaceError.capacityExceeded) { try original.applying(.resize(rows: 3, columns: 1)) }
    }

    @Test func resizePreservesActualOccupancyAndRejectsOverlap() throws {
        let next = try layout().applying(.resize(rows: 1, columns: 3))
        #expect(next.entries.count == 3)
        #expect(next.space(at: .init(row: 0, column: 0)) == anchor)
        #expect(next.position(of: SpaceID("b")) == .init(row: 0, column: 2))
        #expect(throws: InfoSpaceError.occupiedPosition(.init(row: 1, column: 0))) {
            try SpaceLayout(
                grid: SpaceGrid(),
                entries: [
                    SpaceEntry(id: anchor, position: .init(row: 0, column: 0), span: .fullHeight(columns: 1)),
                    SpaceEntry(id: SpaceID("overlap"), position: .init(row: 1, column: 0)),
                ])
        }
        #expect(throws: InfoSpaceError.invalidSpan) {
            try SpaceLayout(
                grid: SpaceGrid(),
                entries: [
                    SpaceEntry(id: anchor, position: .init(row: 1, column: 0), span: .fullHeight(columns: 1))
                ])
        }
    }

    @Test func snapshotRoundTripsAndRejectsStaleRevisionAndCorruption() throws {
        let original = try SpaceSnapshot(layout: layout())
        let next = try original.applying(.minimize(anchor), expectedRevision: 0)
        #expect(next.revision == 1)
        let data = try JSONEncoder().encode(next)
        #expect(try JSONDecoder().decode(SpaceSnapshot.self, from: data) == next)
        #expect(throws: InfoSpaceError.revisionConflict) { try next.applying(.restoreAll, expectedRevision: 0) }
        #expect(throws: InfoSpaceError.invalidSnapshot) {
            try SpaceSnapshot(layout: layout(), minimized: [SpaceID("missing")])
        }
        let corrupt = Data(#"{"dividers":[-1,33]}"#.utf8)
        #expect(throws: InfoSpaceError.invalidProportions) { try JSONDecoder().decode(SnapAxis.self, from: corrupt) }
        let undone = try next.applying(.restoreSnapshot(original), expectedRevision: 1)
        #expect(undone.revision == 2)
        #expect(undone.layout == original.layout)
        #expect(undone.minimized.isEmpty)
    }

    @MainActor @Test func batchesAndHostCommitsAreAtomic() throws {
        let model = InfoSpaceModel(layout: try layout())
        let initial = try model.snapshot
        model.beginDrag(DividerTarget(column: 0))
        #expect(throws: InfoSpaceError.protectedSpace(anchor)) {
            try model.apply([.remove(SpaceID("a")), .remove(anchor)])
        }
        #expect(try model.snapshot == initial)
        #expect(model.dragPreview != nil)
        var proposals: [(SpaceCommand, UInt64)] = []
        model.commandHandler = { proposals.append(($0, $1)) }
        model.minimize(anchor)
        #expect(try model.snapshot == initial)
        #expect(proposals.count == 1)
        let accepted = try initial.applying(proposals[0].0, expectedRevision: proposals[0].1)
        try model.install(accepted)
        #expect(model.minimized == [anchor])
        #expect(throws: InfoSpaceError.revisionConflict) { try model.install(initial) }
        #expect(try model.snapshot == accepted)
        model.setDimensions(rows: 1, columns: 1)
        #expect(proposals.count == 2)
        #expect(model.layout == initial.layout)
    }

    @Test func fullHeightGeometryHasNoDividerThroughPanelAndMinimizesWithoutOverlap() throws {
        let layout = try layout()
        let geometry = SpaceGeometry(
            layout: layout, minimized: [], maximized: nil, size: .init(width: 1200, height: 800))
        let panel = try #require(geometry.placements.first { $0.space == anchor })
        #expect(panel.frame.height == 800)
        #expect(geometry.emptyCells.isEmpty)
        #expect(geometry.dividers.filter { $0.target.row != nil }.allSatisfy { $0.frame.minX >= panel.frame.maxX })
        let minimized = SpaceGeometry(
            layout: layout, minimized: [anchor], maximized: nil, size: .init(width: 1200, height: 800))
        #expect(minimized.placements.first { $0.space == anchor }?.isBanner == true)
        #expect(minimized.placements.filter { $0.space != anchor }.allSatisfy { $0.frame.width == 1200 })
        for first in geometry.placements {
            for second in geometry.placements where first.space != second.space {
                #expect(!first.frame.intersects(second.frame))
            }
        }
    }
}
