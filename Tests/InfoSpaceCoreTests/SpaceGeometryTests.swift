import CoreGraphics
import Foundation
import InfoSpaceCore
import Testing

struct SpaceGeometryTests {
    @MainActor @Test func panelsLinesAndIntersectionsShareContinuousGeometryUntilRelease() throws {
        let model = InfoSpaceModel()
        let target = DividerTarget(column: 0, row: 0)
        let size = CGSize(width: 320, height: 320)
        model.beginDrag(target)
        model.updateDrag(target, columnTick: 12.25, rowTick: 19.75)
        let moving = SpaceGeometry(
            grid: model.grid, minimized: [], maximized: nil,
            size: size, dragPreview: model.dragPreview)
        let first = try #require(moving.placements.first { $0.space == SpaceID(row: 0, column: 0) })
        #expect(first.frame.size == CGSize(width: 118.5, height: 193.5))
        #expect(moving.dividers.filter { $0.target.column != nil }.allSatisfy { $0.frame.midX == 122.5 })
        #expect(moving.dividers.first { $0.target.row != nil }?.frame.midY == 197.5)
        #expect(moving.intersections.first?.center == CGPoint(x: 122.5, y: 197.5))

        model.endDrag()
        let released = SpaceGeometry(
            grid: model.grid, minimized: [], maximized: nil,
            size: size, dragPreview: model.dragPreview)
        #expect(released.intersections.first?.center == CGPoint(x: 120, y: 200))
        #expect(released.placements.first { $0.space == first.space }?.frame.size == CGSize(width: 116, height: 196))
    }

    @Test func baselineIsFourEqualPanelsWithOneIntersection() {
        let geometry = SpaceGeometry(
            grid: SpaceGrid(), minimized: [], maximized: nil, size: CGSize(width: 1000, height: 800))
        #expect(geometry.placements.count == 4)
        #expect(geometry.placements.allSatisfy { $0.frame.size == CGSize(width: 496, height: 396) })
        #expect(geometry.intersections.count == 1)
        #expect(geometry.intersections.first?.center == CGPoint(x: 500, y: 400))
        #expect(geometry.shelfFrame == nil)
    }

    @Test func minimizingAPanelExpandsItsNeighbourAndKeepsABanner() throws {
        let first = SpaceID(row: 0, column: 0)
        let geometry = SpaceGeometry(
            grid: SpaceGrid(), minimized: [first], maximized: nil, size: CGSize(width: 1000, height: 800))
        let neighbour = try #require(geometry.placements.first { $0.space == SpaceID(row: 0, column: 1) })
        #expect(neighbour.frame.minX == 0)
        #expect(neighbour.frame.width == 1000)
        #expect(geometry.placements.first { $0.space == first }?.isBanner == true)
        #expect(geometry.dividers.filter { $0.target.column != nil }.count == 1)
    }

    @Test func minimizingAnEntireRowFillsTheHeight() throws {
        let minimized: Set<SpaceID> = [SpaceID(row: 0, column: 0), SpaceID(row: 0, column: 1)]
        let geometry = SpaceGeometry(
            grid: SpaceGrid(), minimized: minimized, maximized: nil, size: CGSize(width: 1000, height: 800))
        let panel = try #require(geometry.placements.first { !$0.isBanner })
        #expect(panel.frame.minY == 0)
        #expect(panel.frame.height == geometry.gridFrame.height)
        #expect(!geometry.dividers.contains { $0.target.row != nil })
    }

    @Test func maximizingKeepsEveryOtherPanelAtTheEdge() {
        let grid = SpaceGrid(rows: 3, columns: 4)
        let focus = SpaceID(row: 1, column: 2)
        let geometry = SpaceGeometry(
            grid: grid, minimized: [], maximized: focus, size: CGSize(width: 1400, height: 900))
        #expect(geometry.placements.count == 12)
        #expect(geometry.placements.filter(\.isBanner).count == 11)
        #expect(geometry.placements.first { $0.space == focus }?.frame == geometry.gridFrame)
        #expect(geometry.dividers.isEmpty)
        #expect(geometry.intersections.isEmpty)
        #expect(geometry.placements.filter(\.isBanner).allSatisfy { $0.frame.minY > geometry.gridFrame.maxY })
    }

    @Test func allMinimizationPatternsKeepPanelsDisjointAndReachable() {
        let grid = SpaceGrid(rows: 3, columns: 4)
        let spaces = grid.spaces
        let bounds = CGRect(x: 0, y: 0, width: 980, height: 640)
        for mask in 0..<(1 << spaces.count) {
            let minimized = Set(spaces.enumerated().filter { mask & (1 << $0.offset) != 0 }.map(\.element))
            let geometry = SpaceGeometry(grid: grid, minimized: minimized, maximized: nil, size: bounds.size)
            #expect(geometry.placements.count == spaces.count)
            #expect(geometry.placements.filter(\.isBanner).count == minimized.count)
            for (index, placement) in geometry.placements.enumerated() {
                #expect(placement.frame.width > 0 && placement.frame.height > 0)
                #expect(bounds.insetBy(dx: -0.001, dy: -0.001).contains(placement.frame))
                for other in geometry.placements.dropFirst(index + 1) {
                    #expect(!placement.frame.intersects(other.frame))
                }
            }
        }
    }

    @Test(arguments: [CGSize(width: 744, height: 390), CGSize(width: 1800, height: 1100), .zero])
    func denseLayoutsStayInsideTheWindow(size: CGSize) {
        let grid = SpaceGrid(rows: 8, columns: 8)
        let geometry = SpaceGeometry(grid: grid, minimized: [], maximized: grid.spaces[0], size: size)
        #expect(geometry.placements.count == 64)
        for placement in geometry.placements {
            #expect(placement.frame.width >= 0 && placement.frame.height >= 0)
            #expect(placement.frame.maxX <= size.width + 0.001)
            #expect(placement.frame.maxY <= size.height + 0.001)
        }
    }
}
