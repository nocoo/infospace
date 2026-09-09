import SwiftUI

/// Native window configuration, separate from the embeddable canvas and workspace views.
public struct InfoSpaceWindowConfiguration {
    public var minimumSize: CGSize
    public var defaultSize: CGSize
    public var screenWidthFraction: CGFloat
    public var screenHeightFraction: CGFloat
    public var centersOnLaunch: Bool
    public var background: Color

    public init(
        minimumSize: CGSize = CGSize(width: 780, height: 540),
        defaultSize: CGSize = CGSize(width: 1440, height: 960),
        screenWidthFraction: CGFloat = 0.92, screenHeightFraction: CGFloat = 0.90,
        centersOnLaunch: Bool = true, background: Color = Color(nsColor: .windowBackgroundColor)
    ) {
        self.minimumSize = minimumSize
        self.defaultSize = defaultSize
        self.screenWidthFraction = screenWidthFraction
        self.screenHeightFraction = screenHeightFraction
        self.centersOnLaunch = centersOnLaunch
        self.background = background
    }
}

/// A single native window with the traffic lights and caller-supplied toolbar sharing one header.
/// Supply an `InfoSpaceWorkspace` or any other SwiftUI view as the content.
@MainActor
public struct InfoSpaceWindow<Content: View>: Scene {
    private let title: String
    private let id: String
    private let configuration: InfoSpaceWindowConfiguration
    private let content: () -> Content

    public init(
        _ title: String = "Info Space", id: String = "infospace",
        configuration: InfoSpaceWindowConfiguration = .init(), @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.id = id
        self.configuration = configuration
        self.content = content
    }

    public var body: some Scene {
        Window(title, id: id) {
            content()
                .frame(minWidth: configuration.minimumSize.width, minHeight: configuration.minimumSize.height)
                .background(configuration.background)
                .background(NativeWindowAttachment(configuration: configuration))
                .toolbarBackground(configuration.background, for: .windowToolbar)
                .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
        }
        .defaultSize(width: configuration.defaultSize.width, height: configuration.defaultSize.height)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}
