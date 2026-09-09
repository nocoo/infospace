import SwiftUI

public struct SpaceAppearance {
    public var title: String
    public var symbol: String
    public var color: Color
    public var foregroundColor: Color
    public var headerBackground: Color = .clear
    public var controlBackground: Color?
    public var borderColor: Color?
    public var usesGradient = true
    public var customBackground: AnyShapeStyle?

    public init(title: String, symbol: String = "square.grid.2x2", color: Color, foregroundColor: Color = .white) {
        self.title = title
        self.symbol = symbol
        self.color = color
        self.foregroundColor = foregroundColor
    }

    var background: AnyShapeStyle {
        customBackground ?? (usesGradient ? AnyShapeStyle(color.gradient) : AnyShapeStyle(color))
    }
}
