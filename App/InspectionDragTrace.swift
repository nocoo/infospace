#if DEBUG
import AppKit
import InfoSpaceCore

@MainActor
final class DragTrace {
    let originalGrid: SpaceGrid
    var previews: [DividerPreview] = []
    var committedGridStayedUnchanged = true
    var events: [String: Int] = [:]
    var stayedForeground = true
    var windowFrames: [CGRect]

    init(grid: SpaceGrid, window: NSWindow) {
        originalGrid = grid
        windowFrames = [window.frame]
        observeWindow(window)
    }

    func observe(_ event: NSEvent, window: NSWindow, model: InfoSpaceModel) {
        events[String(describing: event.type), default: 0] += 1
        observeWindow(window)
        sample(model)
    }

    func observeWindow(_ window: NSWindow) {
        stayedForeground = stayedForeground && NSApp.isActive && window.isKeyWindow
        if windowFrames.last != window.frame { windowFrames.append(window.frame) }
    }

    func sample(_ model: InfoSpaceModel) {
        guard let preview = model.dragPreview else { return }
        previews.append(preview)
        committedGridStayedUnchanged = committedGridStayedUnchanged && model.grid == originalGrid
    }

    var isContinuous: Bool {
        guard let target = previews.first?.target, stayedForeground, windowFrames.count == 1,
            events[String(describing: NSEvent.EventType.leftMouseDragged), default: 0] > 1,
            events[String(describing: NSEvent.EventType.leftMouseUp), default: 0] == 1
        else { return false }
        let fractionalColumn = previews.contains { $0.columnTick.map { abs($0 - $0.rounded()) > 0.001 } ?? false }
        let fractionalRow = previews.contains { $0.rowTick.map { abs($0 - $0.rounded()) > 0.001 } ?? false }
        return committedGridStayedUnchanged && (target.column == nil || fractionalColumn)
            && (target.row == nil || fractionalRow)
    }

    var summary: String {
        "samples=\(previews.count), continuous=\(isContinuous), "
            + "committed-grid-unchanged=\(committedGridStayedUnchanged), last=\(String(describing: previews.last)), "
            + "events=\(events), foreground=\(stayedForeground), frames=\(windowFrames.map(NSStringFromRect))"
    }
}

#endif
