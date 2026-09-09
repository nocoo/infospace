#if DEBUG
import InfoSpaceCore

@MainActor
final class DragTrace {
    let originalGrid: SpaceGrid
    var previews: [DividerPreview] = []
    var committedGridStayedUnchanged = true

    init(grid: SpaceGrid) { originalGrid = grid }

    func sample(_ model: InfoSpaceModel) {
        guard let preview = model.dragPreview else { return }
        previews.append(preview)
        committedGridStayedUnchanged = committedGridStayedUnchanged && model.grid == originalGrid
    }

    var isContinuous: Bool {
        guard let target = previews.first?.target else { return false }
        let fractionalColumn = previews.contains { $0.columnTick.map { abs($0 - $0.rounded()) > 0.001 } ?? false }
        let fractionalRow = previews.contains { $0.rowTick.map { abs($0 - $0.rounded()) > 0.001 } ?? false }
        return committedGridStayedUnchanged && (target.column == nil || fractionalColumn)
            && (target.row == nil || fractionalRow)
    }

    var summary: String {
        "samples=\(previews.count), continuous=\(isContinuous), "
            + "committed-grid-unchanged=\(committedGridStayedUnchanged), last=\(String(describing: previews.last))"
    }
}

#endif
