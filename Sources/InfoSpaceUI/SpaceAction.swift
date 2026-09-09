import InfoSpaceCore
import SwiftUI

/// An additional header action, placed before the two built-in window actions.
@MainActor
public struct SpaceAction: Identifiable {
    public let id: String
    public var title: String
    public var systemImage: String
    public var isEnabled: Bool
    public var role: ButtonRole?
    public let perform: (SpaceID) -> Void

    public init(
        id: String, title: String, systemImage: String, isEnabled: Bool = true,
        role: ButtonRole? = nil, perform: @escaping (SpaceID) -> Void
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.role = role
        self.perform = perform
    }
}

@MainActor
public struct SpaceBannerContext {
    public let space: SpaceID
    public let appearance: SpaceAppearance
    public let restore: () -> Void
}

public struct SpaceHandleContext {
    public let target: DividerTarget
    public let isActive: Bool
    public let isHovered: Bool
    public let isKeyboardFocused: Bool
}

public struct SpacePanelContext {
    public let space: SpaceID
    public let appearance: SpaceAppearance
    public let size: CGSize
    public let isBanner: Bool
    public let isMaximized: Bool
}
