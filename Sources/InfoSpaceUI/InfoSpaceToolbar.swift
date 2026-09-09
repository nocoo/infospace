import SwiftUI

/// An action or link displayed immediately after the window's brand. A toolbar displays up to three.
@MainActor
public struct InfoSpaceHeaderAction: Identifiable {
    public let id: String
    public var title: String
    public var systemImage: String
    public var isEnabled: Bool
    let destination: Destination

    enum Destination {
        case action(() -> Void)
        case link(URL)
    }

    public init(
        id: String, title: String, systemImage: String, isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        destination = .action(action)
    }

    public init(id: String, title: String, systemImage: String, url: URL, isEnabled: Bool = true) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        destination = .link(url)
    }
}

/// A native unified header with a customizable brand, up to three adjacent actions and trailing controls.
/// Actions beyond the first three are omitted. Standard SwiftUI `openURL` handles link destinations.
@MainActor
public struct InfoSpaceToolbar<Brand: View, Controls: View>: ToolbarContent {
    private let style: InfoSpaceStyle
    private let actions: [InfoSpaceHeaderAction]
    private let brand: Brand
    private let controls: Controls

    public init(
        style: InfoSpaceStyle = .init(), leadingActions: [InfoSpaceHeaderAction] = [],
        @ViewBuilder brand: () -> Brand, @ViewBuilder controls: () -> Controls
    ) {
        self.style = style
        actions = Array(leadingActions.prefix(3))
        self.brand = brand()
        self.controls = controls()
    }

    public var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack(spacing: 14) {
                brand
                if !actions.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(actions) { action in
                            headerAction(action)
                        }
                    }
                }
            }
            .fixedSize()
        }
        .sharedBackgroundVisibility(.hidden)

        ToolbarSpacer(.flexible, placement: .primaryAction)

        ToolbarItem(placement: .primaryAction) { controls }
            .sharedBackgroundVisibility(.hidden)
    }

    private func headerAction(_ action: InfoSpaceHeaderAction) -> some View {
        Group {
            switch action.destination {
            case .action(let perform):
                Button(action: perform) { actionLabel(action) }
            case .link(let url):
                Link(destination: url) { actionLabel(action) }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(style.theme.foreground)
        .disabled(!action.isEnabled)
        .help(action.title)
        .accessibilityLabel(action.title)
        .accessibilityIdentifier("header-action-\(action.id)")
    }

    private func actionLabel(_ action: InfoSpaceHeaderAction) -> some View {
        Image(systemName: action.systemImage)
            .font(.system(size: 13, weight: .medium))
            .frame(width: 30, height: 30)
            .background(style.theme.controlBackground, in: RoundedRectangle(cornerRadius: 8))
            .contentShape(.rect)
    }
}
