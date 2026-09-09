import InfoSpaceCore
import SwiftUI

struct SpacePanel<Content: View>: View {
    let space: SpaceID
    let appearance: SpaceAppearance
    let style: SpacePanelStyle
    let actions: [SpaceAction]
    let isBanner: Bool
    let isMaximized: Bool
    let size: CGSize
    let restore: () -> Void
    let maximize: () -> Void
    let minimize: () -> Void
    let content: Content
    let bannerContent: ((SpaceBannerContext) -> AnyView)?
    let overlayContent: ((SpacePanelContext) -> AnyView)?
    @State private var hovered = false

    private var cornerRadius: CGFloat { isBanner ? style.bannerCornerRadius : style.cornerRadius }
    private var showsContent: Bool {
        !isBanner && size.width >= style.minimumContentSize.width && size.height >= style.minimumContentSize.height
    }
    private var usesCompactMenu: Bool { size.width < 130 || size.height < 40 }
    private var showsInlineActions: Bool { size.width >= 220 + CGFloat(actions.count) * 29 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cornerRadius).fill(appearance.background)
            // Always mounted: local editors and scroll state survive moves and presentation changes.
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(size.width < 220 ? style.compactContentPadding : style.contentPadding)
                .padding(.top, max(0, style.headerHeight - 6))
                .opacity(showsContent ? 1 : 0)
                .allowsHitTesting(showsContent)
                .disabled(!showsContent)
                .accessibilityHidden(!showsContent)
            if isBanner, let bannerContent {
                bannerContent(SpaceBannerContext(space: space, appearance: appearance, restore: restore))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                header
                    .padding(.horizontal, isBanner ? 12 : size.width < 130 ? 8 : 16)
                    .frame(height: isBanner ? size.height : min(style.headerHeight, size.height))
                    .background(appearance.headerBackground)
                if isBanner { bannerButton }
            }
            if let overlayContent {
                overlayContent(
                    SpacePanelContext(
                        space: space, appearance: appearance, size: size,
                        isBanner: isBanner, isMaximized: isMaximized))
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .contentShape(.rect)
        .foregroundStyle(appearance.foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    appearance.borderColor ?? appearance.foregroundColor.opacity(hovered ? 0.26 : 0.12),
                    lineWidth: style.borderWidth
                )
                .allowsHitTesting(false)
        }
        .onHover { hovered = $0 }
        .contextMenu {
            if isBanner {
                Button("Restore space", systemImage: "arrow.uturn.backward", action: restore)
            } else {
                customMenuActions
                if !actions.isEmpty { Divider() }
                builtInMenuActions
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(appearance.title)
        .accessibilityIdentifier("space-\(space.id)")
    }

    private var header: some View {
        HStack(spacing: 9) {
            HStack(spacing: 9) {
                Image(systemName: appearance.symbol)
                    .font(.system(size: isBanner ? 12 : 14, weight: .medium))
                    .foregroundStyle(appearance.foregroundColor.opacity(0.8))
                Text(appearance.title)
                    .font(.system(size: isBanner ? 12 : 13, weight: .semibold))
                    .lineLimit(1).truncationMode(.tail)
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
            .onTapGesture(count: 2) { if !isBanner { maximize() } }
            if isBanner {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 11, weight: .medium)).opacity(hovered ? 1 : 0.55)
            } else if usesCompactMenu {
                compactMenu
            } else {
                HStack(spacing: 3) {
                    additionalButtons
                    panelButton("minus", title: "Minimize \(appearance.title)", id: "minimize", action: minimize)
                    panelButton(
                        isMaximized ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                        title: isMaximized ? "Restore layout" : "Maximize \(appearance.title)",
                        id: "maximize", action: maximize)
                }
            }
        }
    }

    @ViewBuilder private var additionalButtons: some View {
        if showsInlineActions {
            ForEach(actions) { action in
                panelButton(action.systemImage, title: action.title, id: "action-\(action.id)", role: action.role) {
                    action.perform(space)
                }
                .disabled(!action.isEnabled)
            }
        } else if !actions.isEmpty {
            Menu {
                customMenuActions
            } label: {
                actionIcon("ellipsis")
            }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
            .accessibilityLabel("Additional actions for \(appearance.title)")
        }
    }

    private var compactMenu: some View {
        Menu {
            customMenuActions
            if !actions.isEmpty { Divider() }
            builtInMenuActions
        } label: {
            Image(systemName: "ellipsis").font(.system(size: 12, weight: .semibold))
                .frame(width: 22, height: min(26, max(16, size.height - 4)))
                .background(
                    appearance.controlBackground ?? appearance.foregroundColor.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 5))
        }
        .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
        .accessibilityLabel("Actions for \(appearance.title)")
    }

    private var customMenuActions: some View {
        ForEach(actions) { action in
            Button(action.title, systemImage: action.systemImage, role: action.role) { action.perform(space) }
                .disabled(!action.isEnabled)
        }
    }

    private var builtInMenuActions: some View {
        Group {
            Button(
                isMaximized ? "Restore layout" : "Maximize space",
                systemImage: isMaximized ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                action: maximize)
            Button("Minimize space", systemImage: "minus", action: minimize)
        }
    }

    private var bannerButton: some View {
        Button(action: restore) {
            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Restore \(appearance.title)")
        .accessibilityIdentifier("restore-\(space.id)")
    }

    private func actionIcon(_ symbol: String) -> some View {
        Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
            .frame(width: 26, height: 26)
            .background(
                appearance.controlBackground ?? appearance.foregroundColor.opacity(hovered ? 0.14 : 0.075),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .contentShape(.rect)
    }

    private func panelButton(
        _ symbol: String, title: String, id: String, role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) { actionIcon(symbol) }
            .buttonStyle(.plain).help(title).accessibilityLabel(title)
            .accessibilityIdentifier("\(id)-\(space.id)")
    }
}
