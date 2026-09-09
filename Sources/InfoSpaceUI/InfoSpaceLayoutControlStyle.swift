import SwiftUI

/// Host-resolved metrics for the reusable layout dock. Defaults preserve the demo's compact controls.
public struct InfoSpaceLayoutControlStyle {
    public var font: Font = .system(size: 11)
    public var valueFont: Font = .system(size: 12, weight: .medium, design: .monospaced)
    public var symbolFont: Font = .system(size: 13)
    public var dimensionSymbolFont: Font = .system(size: 9, weight: .semibold)
    public var presetFont: Font = .system(size: 11, weight: .medium, design: .monospaced)
    public var groupSpacing: CGFloat = 14
    public var spacing: CGFloat = 5
    public var controlSpacing: CGFloat = 6
    public var controlSide: CGFloat = 30
    public var dimensionSize = CGSize(width: 18, height: 24)
    public var valueWidth: CGFloat = 12
    public var cornerRadius: CGFloat = 8
    public var presetHeight: CGFloat = 28
    public var presetInset: CGFloat = 8
    public var presetPadding: CGFloat = 3
    public var glyphSize = CGSize(width: 17, height: 13)
    public var buttonStyle: SpaceControlButtonStyle?

    public init() {}
}

/// Choose which SDK controls belong in a particular host region, without copying their implementation.
public struct InfoSpaceLayoutControlOptions {
    public var allowsCollapse: Bool
    public var showsPresets: Bool
    public var showsGrid: Bool
    public var showsBalance: Bool
    public var showsRestoreAll: Bool
    public var canChangeDimensions: (@MainActor (Int, Int) -> Bool)?

    public init(
        allowsCollapse: Bool = true, showsPresets: Bool = true, showsGrid: Bool = true,
        showsBalance: Bool = true, showsRestoreAll: Bool = true,
        canChangeDimensions: (@MainActor (Int, Int) -> Bool)? = nil
    ) {
        self.allowsCollapse = allowsCollapse
        self.showsPresets = showsPresets
        self.showsGrid = showsGrid
        self.showsBalance = showsBalance
        self.showsRestoreAll = showsRestoreAll
        self.canChangeDimensions = canChangeDimensions
    }
}
