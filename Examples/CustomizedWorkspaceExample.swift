import InfoSpaceCore
import InfoSpaceUI
import SwiftUI

/// This target is compiled with the package so API examples cannot silently go stale.
struct CustomizedWorkspaceExample: View {
    @State private var model = InfoSpaceModel()
    @State private var controlsExpanded = true
    @State private var insertionFailed = false

    private var style: InfoSpaceStyle {
        var style = InfoSpaceStyle(theme: .light)
        style.theme.accent = .teal
        style.layout.gutter = 12
        style.panel.cornerRadius = 18
        style.panel.headerHeight = 52
        style.panel.titleFont = .system(size: 18, weight: .semibold)
        style.panel.bannerTitleFont = .system(size: 16, weight: .semibold)
        style.panel.symbolFont = .system(size: 20)
        style.panel.actionFont = .system(size: 16)
        style.panel.controlSide = 40
        style.panel.controlSpacing = 4
        style.panel.controlButtonStyle = SpaceControlButtonStyle(ExampleControlStyle())
        style.panel.contentHeaderOverlap = 0
        return style
    }

    var body: some View {
        InfoSpaceWorkspace(canvas: canvas, regions: regions)
            .infoSpaceLocalization(
                InfoSpaceLocalization { text in
                    // A real host resolves these typed cases through its own catalog.
                    switch text {
                    case .restoreSpace: "Reopen panel"
                    case .minimizeSpace: "Hide panel"
                    default: text.defaultText
                    }
                }
            )
            .alert("Space limit reached", isPresented: $insertionFailed) { Button("OK", role: .cancel) {} }
    }

    private var canvas: InfoSpaceCanvas<ExampleEditor> {
        InfoSpaceCanvas(model: model, style: style, appearance: appearance, actions: actions) { identity in
            ExampleEditor(space: identity)
        }
        .banner { context in
            Button(action: context.restore) {
                Label(context.appearance.title, systemImage: context.appearance.symbol)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(context.appearance.color)
            }
            .buttonStyle(.plain)
        }
        .emptyCell { position in
            Button {
                do { try model.insertSpace(at: position, collision: .reject) } catch { insertionFailed = true }
            } label: {
                Image(systemName: "plus").frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add a space at row \(position.row + 1), column \(position.column + 1)")
        }
        .emptyState { Color.clear }
        .resizeHandle { context in
            RoundedRectangle(cornerRadius: 5)
                .fill(
                    context.isActive || context.isHovered || context.isKeyboardFocused ? Color.teal : .gray.opacity(0.3)
                )
                .frame(width: context.target.column == nil ? 28 : 6, height: context.target.row == nil ? 28 : 6)
        }
        .panelOverlay { context in
            if !context.isBanner {
                Image(systemName: "lock.shield")
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .allowsHitTesting(false)
            }
        }
    }

    private var regions: InfoSpaceRegions {
        InfoSpaceRegions {
            HStack {
                Label("Research", systemImage: "books.vertical")
                Spacer()
                InfoSpaceLayoutControls(model: model, style: style, isExpanded: $controlsExpanded)
            }
        } bottom: {
            InfoSpaceFooter(style: style) {
                Text("\(model.spaces.count) sources")
            } trailing: {
                Button("Equal proportions") { model.balance() }
            }
        } leading: {
            VStack {
                Image(systemName: "sidebar.left")
                Spacer()
            }
            .frame(width: 40)
        } trailing: {
            VStack {
                Text("Library")
                Spacer()
            }
            .frame(width: 100)
        }
    }

    private func appearance(_ identity: SpaceID) -> SpaceAppearance {
        var appearance = SpaceAppearance(title: identity.rawValue, symbol: "doc.richtext", color: .teal)
        appearance.usesGradient = false
        appearance.headerBackground = .black.opacity(0.08)
        appearance.controlBackground = .white.opacity(0.16)
        appearance.borderColor = .white.opacity(0.3)
        return appearance
    }

    private func actions(_: SpaceID) -> [SpaceAction] {
        let insertion = SpaceAction(
            id: "insert", title: "Insert here", systemImage: "plus", isEnabled: model.spaces.count < 64
        ) {
            guard let position = model.position(of: $0) else { return }
            do { try model.insertSpace(at: position) } catch { insertionFailed = true }
        }
        return [insertion]
    }
}

private struct ExampleEditor: View {
    let space: SpaceID
    @State private var text = ""

    var body: some View {
        TextField("Notes", text: $text, axis: .vertical)
            .textFieldStyle(.plain)
            .accessibilityLabel("Notes for \(space.rawValue)")
    }
}

private struct ExampleControlStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background(
                isEnabled && (hovered || configuration.isPressed) ? Color.teal.opacity(0.15) : .clear,
                in: .rect(cornerRadius: 8)
            )
            .contentShape(.rect(cornerRadius: 8))
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
            .onHover { hovered = $0 }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: hovered)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
