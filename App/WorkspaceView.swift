import InfoSpaceCore
import InfoSpaceUI
import SwiftUI

struct WorkspaceView: View {
    @Bindable var model: InfoSpaceModel
    @State private var colors: [SpaceID: Int] = [:]
    @State private var insertionFailed = false

    var body: some View {
        InfoSpaceWorkspace(style: WorkspaceStyle.components, regions: .init(bottom: { footer }), padding: 0) {
            InfoSpaceCanvas(
                model: model, style: WorkspaceStyle.components, appearance: appearance, actions: actions
            ) { space in
                DemoPanelContent(space: space).equatable()
            }
            .modifier(InspectionMarker(id: "canvas"))
        }
        .padding(18)
        .foregroundStyle(.white)
        .background(WorkspaceStyle.background)
        .toolbar { WorkspaceToolbar(model: model) }
        .modifier(InspectionLinkCapture())
        .tint(.white)
        .coordinateSpace(name: "InfoSpaceWorkspace")
        .alert("无法添加空间", isPresented: $insertionFailed) {
            Button("好", role: .cancel) {}
        } message: {
            Text("当前布局已满，请先移除一个空间。")
        }
    }

    private func appearance(_ space: SpaceID) -> SpaceAppearance {
        var appearance = DemoSpaces.appearance(space)
        if let index = colors[space] { appearance.color = DemoSpaces.colors[index % DemoSpaces.colors.count] }
        return appearance
    }

    private var footer: some View {
        InfoSpaceFooter(style: WorkspaceStyle.components) {
            HStack(spacing: 6) {
                Circle().fill(Color(red: 0.47, green: 0.78, blue: 0.66)).frame(width: 5, height: 5)
                Text("\(model.visibleCount) 个展开")
                if model.spaces.count > model.visibleCount {
                    Text("· \(model.spaces.count - model.visibleCount) 个收起")
                }
            }
            .modifier(InspectionMarker(id: "footer-leading"))
        } trailing: {
            Button("恢复全部", systemImage: "arrow.uturn.backward") { model.restoreAll() }
                .buttonStyle(.plain)
                .disabled(model.maximized == nil && model.minimized.isEmpty)
                .accessibilityIdentifier("footer-restore")
                .modifier(InspectionMarker(id: "footer-trailing"))
        }
        .modifier(InspectionMarker(id: "footer"))
    }

    private func actions(_ space: SpaceID) -> [SpaceAction] {
        [
            SpaceAction(
                id: "insert", title: "在这里添加空间", systemImage: "plus",
                isEnabled: model.spaces.count < 64
            ) { identity in
                guard let position = model.position(of: identity) else { return }
                do { try model.insertSpace(at: position) } catch { insertionFailed = true }
            },
            SpaceAction(id: "color", title: "切换颜色", systemImage: "paintpalette") { identity in
                colors[identity] = ((colors[identity] ?? DemoSpaces.index(identity)) + 1) % DemoSpaces.colors.count
                #if DEBUG
                if WindowInspection.isEnabled { WindowInspection.colorChanges += 1 }
                #endif
            },
        ]
    }
}

enum WorkspaceStyle {
    static let background = InfoSpaceTheme.dark.background
    static var components: InfoSpaceStyle { InfoSpaceStyle(theme: .dark) }
}
