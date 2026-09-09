import Foundation

/// Committed positions are integer grid ticks; drag previews may use fractional ticks.
public struct SnapAxis: Equatable, Sendable {
    public static let resolution = 32
    public static let minimumSpan = 2
    public static let supportedCounts = 1...8

    public private(set) var dividers: [Int]
    public var count: Int { dividers.count + 1 }
    public var stops: [Int] { [0] + dividers + [Self.resolution] }

    public init(count: Int) {
        let count = min(Self.supportedCounts.upperBound, max(Self.supportedCounts.lowerBound, count))
        dividers = (1..<count).map { Int((Double($0) * Double(Self.resolution) / Double(count)).rounded()) }
    }

    public init(proportions: [Double]) throws {
        guard Self.supportedCounts.contains(proportions.count),
            proportions.allSatisfy({ $0.isFinite && $0 > 0 }),
            let largest = proportions.max()
        else { throw InfoSpaceError.invalidProportions }
        // Scale first so even very large finite weights cannot overflow their sum.
        let weights = proportions.map { $0 / largest }
        let total = weights.reduce(0, +)
        var cumulative = 0.0
        var stops: [Int] = []
        for index in 1..<weights.count {
            cumulative += weights[index - 1]
            let proposed = Int((cumulative / total * Double(Self.resolution)).rounded())
            let lower = (stops.last ?? 0) + Self.minimumSpan
            let upper = Self.resolution - (weights.count - index) * Self.minimumSpan
            stops.append(min(upper, max(lower, proposed)))
        }
        dividers = stops
    }

    /// Neighbours stay fixed; dividers cannot cross or reduce a track below two ticks.
    @discardableResult
    public mutating func moveDivider(at index: Int, to tick: Int) -> Bool {
        guard let position = clampedTick(at: index, to: Double(tick)) else { return false }
        let next = Int(position)
        guard next != dividers[index] else { return false }
        dividers[index] = next
        return true
    }

    /// Constrain a continuous drag without rounding or moving neighbouring dividers.
    public func clampedTick(at index: Int, to tick: Double) -> Double? {
        guard dividers.indices.contains(index), tick.isFinite else { return nil }
        let lower = (index == 0 ? 0 : dividers[index - 1]) + Self.minimumSpan
        let upper = (index + 1 == dividers.count ? Self.resolution : dividers[index + 1]) - Self.minimumSpan
        return min(Double(upper), max(Double(lower), tick))
    }

    public static func tick(at position: Double, length: Double) -> Int? {
        fractionalTick(at: position, length: length).map { Int($0.rounded()) }
    }

    public static func fractionalTick(at position: Double, length: Double) -> Double? {
        guard position.isFinite, length.isFinite, length > 0 else { return nil }
        // Include mouse positions beyond the window, but keep sub-grid movement intact.
        let normalized = min(1, max(0, position / length))
        return normalized * Double(resolution)
    }
}
