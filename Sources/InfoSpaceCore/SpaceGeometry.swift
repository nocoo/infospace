import CoreGraphics

public struct SpacePlacement: Equatable, Sendable {
    public let space: SpaceID
    public let frame: CGRect
    public let isBanner: Bool
}

public struct SpaceCell: Equatable, Sendable {
    public let position: SpacePosition
    public let frame: CGRect
}

public struct SpaceDivider: Identifiable, Equatable, Sendable {
    public let id: String
    public let target: DividerTarget
    public let frame: CGRect
}

public struct SpaceIntersection: Identifiable, Equatable, Sendable {
    public let id: String
    public let target: DividerTarget
    public let center: CGPoint
}

/// One geometry projection for the whole canvas, relative to its own bounds.
public struct SpaceGeometry: Sendable {
    public let placements: [SpacePlacement]
    public let emptyCells: [SpaceCell]
    public let dividers: [SpaceDivider]
    public let intersections: [SpaceIntersection]
    public let gridFrame: CGRect
    public let shelfFrame: CGRect?

    public init(
        grid: SpaceGrid, minimized: Set<SpaceID>, maximized: SpaceID?, size: CGSize,
        dragPreview: DividerPreview? = nil, metrics: SpaceLayoutMetrics = .init()
    ) {
        self.init(
            layout: SpaceLayout(denseGrid: grid), minimized: minimized, maximized: maximized,
            size: size, dragPreview: dragPreview, metrics: metrics)
    }

    public init(
        layout: SpaceLayout, minimized: Set<SpaceID>, maximized: SpaceID?, size: CGSize,
        dragPreview: DividerPreview? = nil, metrics: SpaceLayoutMetrics = .init()
    ) {
        let size = CGSize(
            width: max(0, size.width.isFinite ? size.width : 0),
            height: max(0, size.height.isFinite ? size.height : 0))
        let metrics = metrics.validated
        let spaces = layout.entries.map(\.id)
        let focus = maximized.flatMap { spaces.contains($0) ? $0 : nil }
        let banners = spaces.filter { $0 != focus && (minimized.contains($0) || focus != nil) }
        let bannerIndices = Dictionary(uniqueKeysWithValues: banners.enumerated().map { ($0.element, $0.offset) })
        let shelf = BannerShelfLayout(size: size, count: banners.count, metrics: metrics)
        gridFrame = shelf.gridFrame
        shelfFrame = shelf.shelfFrame
        let projection = GridProjection(
            layout: layout, minimized: minimized, bounds: shelf.gridFrame,
            preview: dragPreview, metrics: metrics)
        placements = spaces.map { space in
            if let index = bannerIndices[space] {
                return SpacePlacement(space: space, frame: shelf.frame(at: index), isBanner: true)
            }
            let frame = focus == space ? shelf.gridFrame : projection.frames[space] ?? .zero
            return SpacePlacement(space: space, frame: frame, isBanner: false)
        }
        emptyCells = focus == nil ? projection.emptyCells : []
        dividers = focus == nil ? projection.dividers : []
        intersections = focus == nil ? projection.intersections : []
    }
}
