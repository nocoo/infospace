import InfoSpaceCore
import SwiftUI

/// An embeddable grid with stable content identities and no surrounding window chrome.
@MainActor
public struct InfoSpaceCanvas<Content: View>: View {
    private let model: InfoSpaceModel
    let style: InfoSpaceStyle
    private let appearance: (SpaceID) -> SpaceAppearance
    private let actions: (SpaceID) -> [SpaceAction]
    private let content: (SpaceID) -> Content
    private var bannerContent: ((SpaceBannerContext) -> AnyView)?
    private var emptyContent: (() -> AnyView)?
    private var emptyCellContent: ((SpacePosition) -> AnyView)?
    private var handleContent: ((SpaceHandleContext) -> AnyView)?
    private var overlayContent: ((SpacePanelContext) -> AnyView)?
    @Namespace private var coordinateSpace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        model: InfoSpaceModel, style: InfoSpaceStyle = .init(),
        appearance: @escaping (SpaceID) -> SpaceAppearance,
        actions: @escaping (SpaceID) -> [SpaceAction] = { _ in [] },
        @ViewBuilder content: @escaping (SpaceID) -> Content
    ) {
        self.model = model
        self.style = style
        self.appearance = appearance
        self.actions = actions
        self.content = content
    }

    public var body: some View {
        GeometryReader { proxy in
            let geometry = SpaceGeometry(
                layout: model.layout, minimized: model.minimized,
                maximized: model.maximized, size: proxy.size,
                dragPreview: model.dragPreview, metrics: style.layout)
            ZStack(alignment: .topLeading) {
                if model.visibleCount == 0, let emptyContent {
                    emptyContent().frame(width: geometry.gridFrame.width, height: geometry.gridFrame.height)
                }
                if let emptyCellContent {
                    ForEach(geometry.emptyCells, id: \.position) { cell in
                        emptyCellContent(cell.position)
                            .frame(width: cell.frame.width, height: cell.frame.height)
                            .position(x: cell.frame.midX, y: cell.frame.midY)
                    }
                }
                if let shelf = geometry.shelfFrame {
                    Rectangle().fill(style.theme.border)
                        .frame(width: shelf.width, height: 1)
                        .position(x: shelf.midX, y: shelf.minY - min(9, style.layout.shelfSpacing / 2))
                        .allowsHitTesting(false)
                }
                ForEach(geometry.placements, id: \.space) { placement in
                    panel(placement)
                }
                SnapGridOverlay(color: style.theme.grid)
                    .frame(width: geometry.gridFrame.width, height: geometry.gridFrame.height)
                    .opacity((model.showsGrid || model.activeDivider != nil) && model.maximized == nil ? 1 : 0)
                    .animation(.easeOut(duration: reduceMotion ? 0 : 0.15), value: model.activeDivider != nil)
                    .allowsHitTesting(false).accessibilityHidden(true)
                    .zIndex(2)
                ForEach(geometry.dividers) { divider in
                    handle(divider.target, gridSize: geometry.gridFrame.size)
                        .frame(width: divider.frame.width, height: divider.frame.height)
                        .position(x: divider.frame.midX, y: divider.frame.midY)
                        .accessibilityIdentifier(divider.id)
                        .zIndex(3)
                }
                ForEach(geometry.intersections) { intersection in
                    handle(intersection.target, gridSize: geometry.gridFrame.size)
                        .frame(width: 26, height: 26)
                        .position(intersection.center)
                        .accessibilityIdentifier(intersection.id)
                        .zIndex(4)
                }
            }
            .coordinateSpace(name: coordinateSpace)
            .animation(reduceMotion ? nil : style.motion.layout, value: model.presentationRevision)
            .clipped()
        }
        .background(style.theme.background)
        .accessibilityIdentifier("infospace-canvas")
    }

    /// Replace the edge banner. The context provides the restore action.
    public func banner<Banner: View>(@ViewBuilder _ builder: @escaping (SpaceBannerContext) -> Banner) -> Self {
        var copy = self
        copy.bannerContent = { AnyView(builder($0)) }
        return copy
    }

    public func emptyState<Empty: View>(@ViewBuilder _ builder: @escaping () -> Empty) -> Self {
        var copy = self
        copy.emptyContent = { AnyView(builder()) }
        return copy
    }

    public func emptyCell<Cell: View>(@ViewBuilder _ builder: @escaping (SpacePosition) -> Cell) -> Self {
        var copy = self
        copy.emptyCellContent = { AnyView(builder($0)) }
        return copy
    }

    /// Replace handle visuals while preserving native dragging, keyboard access and grid constraints.
    public func resizeHandle<Handle: View>(@ViewBuilder _ builder: @escaping (SpaceHandleContext) -> Handle) -> Self {
        var copy = self
        copy.handleContent = { AnyView(builder($0)) }
        return copy
    }

    public func panelOverlay<Overlay: View>(@ViewBuilder _ builder: @escaping (SpacePanelContext) -> Overlay) -> Self {
        var copy = self
        copy.overlayContent = { AnyView(builder($0)) }
        return copy
    }

    private func panel(_ placement: SpacePlacement) -> some View {
        SpacePanel(
            space: placement.space, appearance: appearance(placement.space), style: style.panel,
            actions: actions(placement.space), isBanner: placement.isBanner,
            isMaximized: model.maximized == placement.space, size: placement.frame.size,
            restore: { model.restore(placement.space) }, maximize: { model.maximize(placement.space) },
            minimize: { model.minimize(placement.space) }, content: content(placement.space),
            bannerContent: bannerContent, overlayContent: overlayContent
        )
        .frame(width: placement.frame.width, height: placement.frame.height)
        .position(x: placement.frame.midX, y: placement.frame.midY)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
        .zIndex(placement.isBanner ? 1 : 0)
    }

    private func handle(_ target: DividerTarget, gridSize: CGSize) -> some View {
        SpaceResizeHandle(
            model: model, target: target, gridSize: gridSize, coordinateSpace: coordinateSpace,
            style: style, customContent: handleContent)
    }
}

private struct SnapGridOverlay: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            var path = Path()
            for step in 1..<SnapAxis.resolution {
                let x = size.width * CGFloat(step) / CGFloat(SnapAxis.resolution)
                let y = size.height * CGFloat(step) / CGFloat(SnapAxis.resolution)
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
        }
    }
}
