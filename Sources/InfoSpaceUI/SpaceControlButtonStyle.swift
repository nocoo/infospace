import SwiftUI

/// An optional host button style for panel actions and overflow menus. The SDK
/// still owns button identity, actions, roles, enabled state and layout metrics.
public struct SpaceControlButtonStyle {
    fileprivate let apply: @MainActor (AnyView) -> AnyView

    @MainActor public init<Style: ButtonStyle>(_ style: Style) {
        // Install the concrete style through SwiftUI so its DynamicProperties
        // receive the environment and state storage before makeBody is called.
        apply = { button in AnyView(button.buttonStyle(style)) }
    }
}

struct SpaceControlAppearance: ViewModifier {
    let style: SpaceControlButtonStyle?

    @ViewBuilder func body(content: Content) -> some View {
        if let style {
            style.apply(AnyView(content))
        } else {
            content.buttonStyle(.plain)
        }
    }
}
