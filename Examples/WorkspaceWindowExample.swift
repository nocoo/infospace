import InfoSpaceUI
import SwiftUI

/// Use this scene from an App, or put InfoSpaceWorkspace in an existing WindowGroup.
struct WorkspaceWindowExample: Scene {
    var body: some Scene {
        InfoSpaceWindow("Research", id: "research", configuration: .init(background: InfoSpaceTheme.light.background)) {
            CustomizedWorkspaceExample()
                .toolbar {
                    InfoSpaceToolbar(style: .init(theme: .light), leadingActions: headerActions) {
                        Label("Research", systemImage: "books.vertical")
                    } controls: {
                        EmptyView()
                    }
                }
        }
    }

    private var headerActions: [InfoSpaceHeaderAction] {
        guard let url = URL(string: "https://github.com/nocoo/infospace") else { return [] }
        let github = InfoSpaceHeaderAction(id: "github", title: "GitHub", systemImage: "link", url: url)
        return [github]
    }
}
