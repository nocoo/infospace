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
        // Only this geometry layer observes pointer positions. The content value
        // is built outside it, so a drag never invokes the host's Panel factory.
        InfoSpaceCanvasGeometry(
            model: model, style: style, coordinateSpace: coordinateSpace,
            panels: panels, emptyContent: emptyContent, emptyCellContent: emptyCellContent,
            handleContent: handleContent
        )
        .background(style.theme.background)
        .accessibilityIdentifier("infospace-canvas")
    }

    private var panels: some View {
        ForEach(model.spaces, id: \.self) { space in
            let isBanner = model.maximized.map { $0 != space } ?? model.minimized.contains(space)
            InfoSpaceCanvasPanel(
                space: space, appearance: appearance(space), style: style.panel,
                actions: actions(space), isBanner: isBanner, isMaximized: model.maximized == space,
                restore: { model.restore(space) }, maximize: { model.maximize(space) },
                minimize: { model.minimize(space) }, content: content(space),
                bannerContent: bannerContent, overlayContent: overlayContent
            )
            .layoutValue(key: InfoSpacePlacementKey.self, value: space)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
            .zIndex(isBanner ? 1 : 0)
        }
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

}
