import Foundation
import InfoSpaceCore
import Testing

struct SnapAxisTests {
    @Test func proportionsSnapToNearestTicksAndHonorMinimumTrackSizes() throws {
        #expect(try SnapAxis(proportions: [1, 3]).dividers == [8])
        #expect(try SnapAxis(proportions: [1, 1, 1]).dividers == [11, 21])
        let tinyFirst = try SnapAxis(proportions: [0.0001, 1, 0.0001, 0.0001])
        #expect(tinyFirst.dividers == [2, 28, 30])
        let huge = try SnapAxis(proportions: [.greatestFiniteMagnitude, .greatestFiniteMagnitude])
        #expect(huge.dividers == [16])
        let extreme = try SnapAxis(proportions: [.leastNonzeroMagnitude, .greatestFiniteMagnitude])
        #expect(extreme.dividers == [2])
    }

    @Test(arguments: [[], [0.0, 1], [-1, 1], [.nan, 1], [.infinity, 1], Array(repeating: 1.0, count: 9)])
    func proportionsRejectInvalidWeights(proportions: [Double]) {
        #expect(throws: InfoSpaceError.invalidProportions) { try SnapAxis(proportions: proportions) }
    }

    @Test(arguments: Array(SnapAxis.supportedCounts))
    func equalTracksCoverExactlyThirtyTwoTicks(count: Int) {
        let axis = SnapAxis(count: count)
        let spans = zip(axis.stops, axis.stops.dropFirst()).map { $1 - $0 }
        #expect(axis.count == count)
        #expect(spans.reduce(0, +) == 32)
        #expect(spans.allSatisfy { $0 >= SnapAxis.minimumSpan })
        #expect((spans.max() ?? 0) - (spans.min() ?? 0) <= 1)
    }

    @Test func snappingUsesTheNearestTickAndRejectsInvalidSizes() {
        #expect(SnapAxis.tick(at: 159, length: 320) == 16)
        #expect(SnapAxis.tick(at: 164, length: 320) == 16)
        #expect(SnapAxis.tick(at: 165, length: 320) == 17)
        #expect(SnapAxis.tick(at: -500, length: 320) == 0)
        #expect(SnapAxis.tick(at: 50_000, length: 320) == 32)
        #expect(SnapAxis.tick(at: 100, length: 0) == nil)
        #expect(SnapAxis.tick(at: .nan, length: 320) == nil)
        #expect(SnapAxis.tick(at: 100, length: .infinity) == nil)
    }

    @Test func pointerCoordinatesPreserveMovementWithinOneGridCell() {
        #expect(SnapAxis.fractionalTick(at: 161, length: 320) == 16.1)
        #expect(SnapAxis.fractionalTick(at: 164, length: 320) == 16.4)
        #expect(SnapAxis.fractionalTick(at: -500, length: 320) == 0)
        #expect(SnapAxis.fractionalTick(at: 50_000, length: 320) == 32)
        #expect(SnapAxis.fractionalTick(at: 100, length: 0) == nil)
        #expect(SnapAxis.fractionalTick(at: .nan, length: 320) == nil)
        #expect(SnapAxis.fractionalTick(at: .infinity, length: 320) == nil)
    }

    @Test func aDividerNeverMovesItsNeighboursOrCrossesThem() {
        var axis = SnapAxis(count: 4)
        #expect(axis.dividers == [8, 16, 24])
        axis.moveDivider(at: 1, to: -100)
        #expect(axis.dividers == [8, 10, 24])
        axis.moveDivider(at: 1, to: 100)
        #expect(axis.dividers == [8, 22, 24])
        let repeated = axis.moveDivider(at: 1, to: 22)
        let invalidLow = axis.moveDivider(at: -1, to: 15)
        let invalidHigh = axis.moveDivider(at: 3, to: 15)
        #expect(!repeated && !invalidLow && !invalidHigh)
    }

    @Test func longSequencesOfCommittedMovesStayOnTheGrid() {
        var axis = SnapAxis(count: 8)
        for step in 0..<10_000 {
            axis.moveDivider(at: step % 7, to: (step * 13) % 65 - 16)
            #expect(zip(axis.stops, axis.stops.dropFirst()).allSatisfy { $1 - $0 >= 2 })
        }
    }
}
