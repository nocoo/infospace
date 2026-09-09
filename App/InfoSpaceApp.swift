import InfoSpaceCore
import InfoSpaceUI
import SwiftUI

@main
struct InfoSpaceApp: App {
    @NSApplicationDelegateAdaptor(ApplicationLifecycle.self) private var lifecycle
    @State private var model = InfoSpaceModel()

    var body: some Scene {
        InfoSpaceWindow(configuration: .init(background: WorkspaceStyle.background)) {
            WorkspaceView(model: model)
                .preferredColorScheme(.dark)
                .task {
                    #if DEBUG
                    await WindowInspection.runIfRequested(model: model)
                    #endif
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("空间") {
                Toggle("显示网格", isOn: $model.showsGrid).keyboardShortcut("g")
                Button("均分行列") { animate { model.balance() } }.keyboardShortcut("0")
                Button("恢复所有空间") { animate { model.restoreAll() } }
                    .keyboardShortcut("0", modifiers: [.command, .shift])
                Divider()
                Button("四个空间 · 2 × 2") { layout(rows: 2, columns: 2) }.keyboardShortcut("1")
                Button("八个空间 · 2 × 4") { layout(rows: 2, columns: 4) }.keyboardShortcut("2")
                Button("十二个空间 · 3 × 4") { layout(rows: 3, columns: 4) }.keyboardShortcut("3")
                Divider()
                Button("退出最大化") { animate { model.restoreLayout() } }.keyboardShortcut(.escape, modifiers: [])
                    .disabled(model.maximized == nil)
            }
        }
    }

    private func layout(rows: Int, columns: Int) {
        animate { model.setDimensions(rows: rows, columns: columns) }
    }

    private func animate(_ action: () -> Void) {
        let reduced = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        withAnimation(reduced ? nil : .spring(response: 0.42, dampingFraction: 0.86), action)
    }
}

@MainActor
final class ApplicationLifecycle: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
