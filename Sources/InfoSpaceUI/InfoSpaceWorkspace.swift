import InfoSpaceCore
import SwiftUI

/// Optional surrounding views. Empty regions occupy no space.
@MainActor
public struct InfoSpaceRegions {
    let top: AnyView
    let bottom: AnyView
    let leading: AnyView
    let trailing: AnyView

    public init(
        @ViewBuilder top: () -> some View = { EmptyView() },
        @ViewBuilder bottom: () -> some View = { EmptyView() },
        @ViewBuilder leading: () -> some View = { EmptyView() },
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) {
        self.top = AnyView(top())
        self.bottom = AnyView(bottom())
        self.leading = AnyView(leading())
        self.trailing = AnyView(trailing())
    }
}

/// A complete workspace view. For a small embedded grid, use `InfoSpaceCanvas` directly.
@MainActor
public struct InfoSpaceWorkspace<Canvas: View>: View {
    private let canvas: Canvas
    private let style: InfoSpaceStyle
    private let regions: InfoSpaceRegions
    private let padding: CGFloat
    private let spacing: CGFloat

    public init<Content: View>(
        canvas: InfoSpaceCanvas<Content>, regions: InfoSpaceRegions = .init(),
        padding: CGFloat = 18, spacing: CGFloat = 12
    ) where Canvas == InfoSpaceCanvas<Content> {
        self.canvas = canvas
        style = canvas.style
        self.regions = regions
        self.padding = padding
        self.spacing = spacing
    }

    public init<Content: View>(
        model: InfoSpaceModel, style: InfoSpaceStyle = .init(), regions: InfoSpaceRegions = .init(),
        padding: CGFloat = 18, spacing: CGFloat = 12,
        appearance: @escaping (SpaceID) -> SpaceAppearance,
        actions: @escaping (SpaceID) -> [SpaceAction] = { _ in [] },
        @ViewBuilder content: @escaping (SpaceID) -> Content
    ) where Canvas == InfoSpaceCanvas<Content> {
        canvas = InfoSpaceCanvas(model: model, style: style, appearance: appearance, actions: actions, content: content)
        self.style = style
        self.regions = regions
        self.padding = padding
        self.spacing = spacing
    }

    /// A general canvas slot, allowing host modifiers and wrappers around the grid.
    public init(
        style: InfoSpaceStyle = .init(), regions: InfoSpaceRegions = .init(),
        padding: CGFloat = 18, spacing: CGFloat = 12, @ViewBuilder canvas: () -> Canvas
    ) {
        self.canvas = canvas()
        self.style = style
        self.regions = regions
        self.padding = padding
        self.spacing = spacing
    }

    public var body: some View {
        VStack(spacing: spacing) {
            regions.top
            HStack(spacing: spacing) {
                regions.leading
                canvas
                regions.trailing
            }
            regions.bottom
        }
        .padding(padding)
        .background(style.theme.background)
    }
}
