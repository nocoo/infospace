import CoreGraphics

struct BannerShelfLayout {
    let gridFrame: CGRect
    let shelfFrame: CGRect?
    private let count: Int
    private let columns: Int
    private let horizontalGap: CGFloat
    private let verticalGap: CGFloat
    private let cellHeight: CGFloat

    init(size: CGSize, count: Int, metrics: SpaceLayoutMetrics) {
        self.count = count
        let budget = size.height * 0.55
        let preferredColumns = Self.boundedCount(
            (size.width + metrics.gutter) / metrics.preferredBannerWidth, limit: count)
        let comfortableRows = Self.boundedCount(
            (budget + metrics.gutter) / (metrics.bannerHeight + metrics.gutter), limit: count)
        let requiredColumns = count == 0 ? 1 : (count + comfortableRows - 1) / comfortableRows
        let compactColumns = Self.boundedCount((size.width + metrics.gutter) / metrics.minimumBannerWidth, limit: count)
        columns = max(preferredColumns, min(compactColumns, requiredColumns))
        let rows = count == 0 ? 0 : (count + columns - 1) / columns
        horizontalGap = min(metrics.gutter, size.width / CGFloat(max(1, columns * 2)))
        verticalGap = min(metrics.gutter, budget / CGFloat(max(1, rows * 2)))
        cellHeight =
            rows == 0
            ? 0
            : min(
                metrics.bannerHeight,
                max(0, (budget - CGFloat(rows - 1) * verticalGap) / CGFloat(rows)))
        let shelfHeight = rows == 0 ? 0 : CGFloat(rows) * cellHeight + CGFloat(rows - 1) * verticalGap
        let shelfGap = min(metrics.shelfSpacing, size.height * 0.05)
        let gridHeight = max(0, size.height - (rows == 0 ? 0 : shelfHeight + shelfGap))
        gridFrame = CGRect(x: 0, y: 0, width: size.width, height: gridHeight)
        shelfFrame = rows == 0 ? nil : CGRect(x: 0, y: gridHeight + shelfGap, width: size.width, height: shelfHeight)
    }

    func frame(at index: Int) -> CGRect {
        guard let shelfFrame, (0..<count).contains(index) else { return .zero }
        let row = index / columns
        let column = index % columns
        let countInRow = min(columns, count - row * columns)
        let width = max(0, (shelfFrame.width - CGFloat(countInRow - 1) * horizontalGap) / CGFloat(countInRow))
        return CGRect(
            x: CGFloat(column) * (width + horizontalGap),
            y: shelfFrame.minY + CGFloat(row) * (cellHeight + verticalGap), width: width, height: cellHeight)
    }

    private static func boundedCount(_ ratio: CGFloat, limit: Int) -> Int {
        let maximum = max(1, limit)
        guard ratio.isFinite, ratio < CGFloat(maximum) else { return maximum }
        return max(1, Int(max(0, ratio)))
    }
}
