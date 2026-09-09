import InfoSpaceCore
import SwiftUI

/// Workspace and control colors. Panel colors are supplied separately through `SpaceAppearance`.
public struct InfoSpaceTheme {
    public var background: Color
    public var foreground: Color
    public var secondaryForeground: Color
    public var accent: Color
    public var onAccent: Color
    public var controlBackground: Color
    public var selectedControlBackground: Color
    public var border: Color
    public var grid: Color
    public var handle: Color
    public var hoveredHandle: Color

    public init(
        background: Color = .clear, foreground: Color = .primary,
        secondaryForeground: Color = .secondary, accent: Color = .accentColor,
        onAccent: Color = .white, controlBackground: Color = .primary.opacity(0.05),
        selectedControlBackground: Color = .primary.opacity(0.12), border: Color = .primary.opacity(0.15),
        grid: Color = .primary.opacity(0.12), handle: Color = .primary.opacity(0.25),
        hoveredHandle: Color = .primary.opacity(0.65)
    ) {
        self.background = background
        self.foreground = foreground
        self.secondaryForeground = secondaryForeground
        self.accent = accent
        self.onAccent = onAccent
        self.controlBackground = controlBackground
        self.selectedControlBackground = selectedControlBackground
        self.border = border
        self.grid = grid
        self.handle = handle
        self.hoveredHandle = hoveredHandle
    }

    public static var dark: Self {
        Self(
            background: Color(red: 0.075, green: 0.085, blue: 0.11), foreground: .white,
            secondaryForeground: .white.opacity(0.55), accent: .white, onAccent: .black,
            controlBackground: .white.opacity(0.05), selectedControlBackground: .white.opacity(0.12),
            border: .white.opacity(0.15), grid: .white.opacity(0.12), handle: .white.opacity(0.25),
            hoveredHandle: .white.opacity(0.65))
    }

    public static var light: Self {
        Self(
            background: Color(red: 0.96, green: 0.97, blue: 0.98), foreground: .black.opacity(0.85),
            secondaryForeground: .black.opacity(0.55), accent: .indigo, onAccent: .white,
            controlBackground: .black.opacity(0.05), selectedControlBackground: .black.opacity(0.12),
            border: .black.opacity(0.15), grid: .black.opacity(0.12), handle: .black.opacity(0.25),
            hoveredHandle: .black.opacity(0.65))
    }
}

public struct InfoSpaceMotion {
    public var layout: Animation?
    public var snapping: Animation?
    public var controls: Animation?

    public init(
        layout: Animation? = .spring(response: 0.42, dampingFraction: 0.86),
        snapping: Animation? = .easeOut(duration: 0.14),
        controls: Animation? = .spring(response: 0.28, dampingFraction: 0.95)
    ) {
        self.layout = layout
        self.snapping = snapping
        self.controls = controls
    }

    public static var none: Self { Self(layout: nil, snapping: nil, controls: nil) }
}

public struct SpacePanelStyle {
    public var headerHeight: CGFloat = 48
    public var cornerRadius: CGFloat = 13
    public var bannerCornerRadius: CGFloat = 8
    public var contentPadding: CGFloat = 26
    public var compactContentPadding: CGFloat = 14
    public var minimumContentSize = CGSize(width: 100, height: 100)
    public var borderWidth: CGFloat = 1

    public init() {}
}

/// Shared styling for a canvas, its surrounding regions and the optional layout controls.
public struct InfoSpaceStyle {
    public var theme: InfoSpaceTheme
    public var layout: SpaceLayoutMetrics
    public var panel: SpacePanelStyle
    public var motion: InfoSpaceMotion

    public init(
        theme: InfoSpaceTheme = .init(), layout: SpaceLayoutMetrics = .init(),
        panel: SpacePanelStyle = .init(), motion: InfoSpaceMotion = .init()
    ) {
        self.theme = theme
        self.layout = layout
        self.panel = panel
        self.motion = motion
    }
}
