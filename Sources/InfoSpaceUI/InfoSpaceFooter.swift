import SwiftUI

/// Optional footer content, independently aligned to the leading and trailing edges of the workspace.
@MainActor
public struct InfoSpaceFooter: View {
    private let style: InfoSpaceStyle
    private let spacing: CGFloat
    private let minimumHeight: CGFloat
    private let leading: AnyView
    private let trailing: AnyView

    public init(
        style: InfoSpaceStyle = .init(), spacing: CGFloat = 12, minimumHeight: CGFloat = 24,
        @ViewBuilder leading: () -> some View = { EmptyView() },
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) {
        self.style = style
        self.spacing = spacing
        self.minimumHeight = minimumHeight
        self.leading = AnyView(leading())
        self.trailing = AnyView(trailing())
    }

    public var body: some View {
        HStack(spacing: 0) {
            leading
            Spacer(minLength: spacing)
            trailing
        }
        .font(.system(size: 11))
        .foregroundStyle(style.theme.secondaryForeground)
        .frame(maxWidth: .infinity, minHeight: minimumHeight)
    }
}
