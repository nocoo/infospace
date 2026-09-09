import InfoSpaceCore
import SwiftUI

/// Pointer observation ends here. `panels` is a stable value supplied by the
/// parent; positioning it must not rebuild the consumer's content tree.
struct InfoSpaceCanvasGeometry<Panels: View>: View {
    let model: InfoSpaceModel
    let style: InfoSpaceStyle
    let coordinateSpace: Namespace.ID
    let panels: Panels
    let emptyContent: (() -> AnyView)?
    let emptyCellContent: ((SpacePosition) -> AnyView)?
    let handleContent: ((SpaceHandleContext) -> AnyView)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
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
                InfoSpacePlacementLayout(placements: geometry.placements) { panels }
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
    }

    private func handle(_ target: DividerTarget, gridSize: CGSize) -> some View {
        SpaceResizeHandle(
            model: model, target: target, gridSize: gridSize, coordinateSpace: coordinateSpace,
            style: style, customContent: handleContent)
    }
}

struct InfoSpacePlacementKey: LayoutValueKey {
    static let defaultValue: SpaceID? = nil
}

private struct InfoSpacePlacementLayout: Layout {
    let placements: [SpacePlacement]

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = Dictionary(uniqueKeysWithValues: placements.map { ($0.space, $0.frame) })
        for subview in subviews {
            guard let id = subview[InfoSpacePlacementKey.self], let frame = frames[id] else { continue }
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), anchor: .topLeading,
                proposal: ProposedViewSize(frame.size))
        }
    }
}

/// Size-dependent panel chrome observes its proposal, while the consumer's
/// content value and its local state remain outside that observation boundary.
struct InfoSpaceCanvasPanel<Content: View>: View {
    let space: SpaceID
    let appearance: SpaceAppearance
    let style: SpacePanelStyle
    let actions: [SpaceAction]
    let isBanner: Bool
    let isMaximized: Bool
    let restore: () -> Void
    let maximize: () -> Void
    let minimize: () -> Void
    let content: Content
    let bannerContent: ((SpaceBannerContext) -> AnyView)?
    let overlayContent: ((SpacePanelContext) -> AnyView)?

    var body: some View {
        GeometryReader { proxy in
            SpacePanel(
                space: space, appearance: appearance, style: style, actions: actions,
                isBanner: isBanner, isMaximized: isMaximized, size: proxy.size,
                restore: restore, maximize: maximize, minimize: minimize, content: content,
                bannerContent: bannerContent, overlayContent: overlayContent)
        }
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
