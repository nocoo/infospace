import InfoSpaceCore
import InfoSpaceUI
import SwiftUI

/// SwiftUI's native window toolbar shares one row with the system traffic lights.
struct WorkspaceToolbar: ToolbarContent {
    let model: InfoSpaceModel

    var body: some ToolbarContent {
        InfoSpaceToolbar(style: WorkspaceStyle.components, leadingActions: headerActions) {
            HStack(spacing: 8) {
                SpaceMark().frame(width: 22, height: 22)
                Text("Info Space")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .tracking(-0.3)
            }
            .foregroundStyle(.white.opacity(0.92))
            .padding(.leading, 6)
            .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Info Space")
            .modifier(InspectionMarker(id: "toolbar-brand", inToolbar: true))
        } controls: {
            InfoSpaceLayoutControls(model: model, style: WorkspaceStyle.components) { rows, columns in
                model.setDimensions(rows: rows, columns: columns)
            }
            .modifier(InspectionMarker(id: "layout-controls", inToolbar: true))
        }
    }

    private var headerActions: [InfoSpaceHeaderAction] {
        guard let url = URL(string: "https://github.com/nocoo/infospace") else { return [] }
        let github = InfoSpaceHeaderAction(
            id: "github", title: "GitHub",
            systemImage: "chevron.left.forwardslash.chevron.right", url: url)
        return [github]
    }
}

private struct SpaceMark: View {
    var body: some View {
        if let image = AppResources.toolbarMark {
            Image(nsImage: image)
                .renderingMode(.original)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .accessibilityHidden(true)
        }
    }
}
