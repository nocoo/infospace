import CoreGraphics

/// Geometry settings shared by standalone and embedded workspaces.
public struct SpaceLayoutMetrics: Equatable, Sendable {
    public var gutter: CGFloat
    public var bannerHeight: CGFloat
    public var shelfSpacing: CGFloat
    public var preferredBannerWidth: CGFloat
    public var minimumBannerWidth: CGFloat

    public init(
        gutter: CGFloat = 8,
        bannerHeight: CGFloat = 36,
        shelfSpacing: CGFloat = 18,
        preferredBannerWidth: CGFloat = 168,
        minimumBannerWidth: CGFloat = 88
    ) {
        self.gutter = Self.finite(gutter, fallback: 8)
        self.bannerHeight = max(1, Self.finite(bannerHeight, fallback: 36))
        self.shelfSpacing = Self.finite(shelfSpacing, fallback: 18)
        self.preferredBannerWidth = max(1, Self.finite(preferredBannerWidth, fallback: 168))
        self.minimumBannerWidth = max(1, Self.finite(minimumBannerWidth, fallback: 88))
    }

    var validated: Self {
        Self(
            gutter: gutter, bannerHeight: bannerHeight, shelfSpacing: shelfSpacing,
            preferredBannerWidth: preferredBannerWidth, minimumBannerWidth: minimumBannerWidth)
    }

    private static func finite(_ value: CGFloat, fallback: CGFloat) -> CGFloat {
        value.isFinite ? max(0, value) : fallback
    }
}
