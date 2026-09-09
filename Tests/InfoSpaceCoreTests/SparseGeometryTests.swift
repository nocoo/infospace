import CoreGraphics
import InfoSpaceCore
import Testing

struct SparseGeometryTests {
    @Test func anIsolatedSpaceRetainsItsRequestedCellAndTheOtherCellsRemainVacant() throws {
        let position = SpacePosition(row: 1, column: 3)
        let identity = SpaceID("corner")
        let layout = try SpaceLayout(
            grid: SpaceGrid(rows: 2, columns: 4),
            entries: [SpaceEntry(id: identity, position: position)])
        let geometry = SpaceGeometry(
            layout: layout, minimized: [], maximized: nil,
            size: CGSize(width: 800, height: 600))
        let panel = try #require(geometry.placements.first)
        #expect(panel.space == identity)
        #expect(panel.frame == CGRect(x: 604, y: 304, width: 196, height: 296))
        #expect(geometry.emptyCells.count == 7)
        #expect(!geometry.emptyCells.contains { $0.position == position })
        #expect(geometry.intersections.count == 3)
    }

    @Test func arbitraryIDsCanFocusAndMinimizeWithoutDependingOnTheirNames() throws {
        let first = SpaceID("document/α")
        let second = SpaceID("mail")
        let layout = try SpaceLayout(
            grid: SpaceGrid(rows: 1, columns: 2),
            entries: [
                SpaceEntry(id: first, position: SpacePosition(row: 0, column: 0)),
                SpaceEntry(id: second, position: SpacePosition(row: 0, column: 1)),
            ])
        let size = CGSize(width: 640, height: 480)
        let geometry = SpaceGeometry(layout: layout, minimized: [], maximized: second, size: size)
        #expect(geometry.placements.first { $0.space == first }?.isBanner == true)
        #expect(geometry.placements.first { $0.space == second }?.frame == geometry.gridFrame)
        #expect(geometry.emptyCells.isEmpty)
        #expect(geometry.intersections.isEmpty)
    }

    @Test func customGuttersAndBannersAreAppliedByTheGeometryLayer() throws {
        var metrics = SpaceLayoutMetrics()
        metrics.gutter = 16
        metrics.bannerHeight = 48
        metrics.shelfSpacing = 24
        let grid = SpaceGrid()
        let geometry = SpaceGeometry(
            grid: grid, minimized: [grid.spaces[0]], maximized: nil,
            size: CGSize(width: 1000, height: 800), metrics: metrics)
        let banner = try #require(geometry.placements.first { $0.isBanner })
        #expect(banner.frame.height == 48)
        #expect(banner.frame.minY - geometry.gridFrame.maxY == 24)
        let lowerLeft = try #require(geometry.placements.first { $0.space == grid.spaces[2] })
        #expect(lowerLeft.frame.width == 492)
    }

    @Test(arguments: [
        CGSize(width: 10, height: 8), CGSize(width: 1, height: 1), .zero,
        CGSize(width: CGFloat.infinity, height: CGFloat.nan),
    ])
    func tinyOrInvalidHostSizesNeverProduceNegativeOrNonfiniteFrames(size: CGSize) {
        var metrics = SpaceLayoutMetrics()
        metrics.gutter = .infinity
        metrics.bannerHeight = -10
        metrics.shelfSpacing = .nan
        let grid = SpaceGrid(rows: 8, columns: 8)
        let geometry = SpaceGeometry(grid: grid, minimized: [], maximized: grid.spaces[0], size: size, metrics: metrics)
        for placement in geometry.placements {
            #expect(placement.frame.width.isFinite && placement.frame.height.isFinite)
            #expect(placement.frame.width >= 0 && placement.frame.height >= 0)
            #expect(placement.frame.minX.isFinite && placement.frame.minY.isFinite)
        }
    }
}
