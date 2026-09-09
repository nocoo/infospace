import AppKit
import InfoSpaceCore
import SwiftUI

struct SpaceResizeHandle: View {
    let model: InfoSpaceModel
    let target: DividerTarget
    let gridSize: CGSize
    let coordinateSpace: Namespace.ID
    let style: InfoSpaceStyle
    let customContent: ((SpaceHandleContext) -> AnyView)?
    @State private var hovered = false
    @State private var dragOrigin: CGPoint?
    @GestureState private var isDragging = false
    @FocusState private var keyboardFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isActive: Bool {
        guard let active = model.activeDivider else { return false }
        return (target.column != nil && active.column == target.column)
            || (target.row != nil && active.row == target.row)
    }

    var body: some View {
        ZStack {
            Color.clear
            if let customContent {
                customContent(
                    SpaceHandleContext(
                        target: target, isActive: isActive,
                        isHovered: hovered, isKeyboardFocused: keyboardFocused)
                )
                .allowsHitTesting(false)
            } else if target.isIntersection {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? style.theme.accent : style.theme.background)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(hovered || keyboardFocused ? style.theme.hoveredHandle : style.theme.border)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 1)
                Image(systemName: "plus").font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isActive ? style.theme.onAccent : style.theme.foreground)
            } else {
                Capsule()
                    .fill(
                        isActive
                            ? style.theme.accent
                            : hovered || keyboardFocused ? style.theme.hoveredHandle : style.theme.handle
                    )
                    .frame(width: target.column != nil ? 2 : 30, height: target.column != nil ? 30 : 2)
            }
        }
        .contentShape(.rect)
        .gesture(drag)
        .onHover { value in
            guard value != hovered else { return }
            hovered = value
            if value { cursor.push() } else { NSCursor.pop() }
        }
        .onDisappear {
            if hovered { NSCursor.pop() }
            cancelTracking()
        }
        .onChange(of: isDragging) { _, dragging in
            if !dragging { cancelTracking() }
        }
        .focusable()
        .focused($keyboardFocused)
        .focusEffectDisabled()
        .onKeyPress(.leftArrow) { nudge(column: -1, row: 0) }
        .onKeyPress(.rightArrow) { nudge(column: 1, row: 0) }
        .onKeyPress(.upArrow) { nudge(column: 0, row: -1) }
        .onKeyPress(.downArrow) { nudge(column: 0, row: 1) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(valueLabel)
        .accessibilityHint("Drag freely and release to snap to the grid, or adjust one tick with the arrow keys")
        .accessibilityAdjustableAction { direction in
            let delta = direction == .increment ? 1 : -1
            _ = nudge(column: target.column == nil ? 0 : delta, row: target.row == nil ? 0 : delta)
        }
        .help("\(label) · \(valueLabel)")
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpace))
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                guard target.column.map({ model.grid.columns.dividers.indices.contains($0) }) ?? true,
                    target.row.map({ model.grid.rows.dividers.indices.contains($0) }) ?? true
                else { return }
                if dragOrigin == nil {
                    let x = target.column.map { CGFloat(model.grid.columns.dividers[$0]) * gridSize.width / 32 } ?? 0
                    let y = target.row.map { CGFloat(model.grid.rows.dividers[$0]) * gridSize.height / 32 } ?? 0
                    dragOrigin = CGPoint(x: x, y: y)
                    model.beginDrag(target)
                }
                guard let origin = dragOrigin else { return }
                // Tracking is immediate. Queuing animations for mouse events causes visible lag.
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { applyTranslation(value.translation, from: origin) }
            }
            .onEnded { value in
                guard model.activeDivider == target else {
                    dragOrigin = nil
                    return
                }
                let origin = dragOrigin
                dragOrigin = nil
                withAnimation(reduceMotion ? nil : style.motion.snapping) {
                    // A mouse-up can carry a newer position than the last delivered drag event.
                    if let origin { applyTranslation(value.translation, from: origin) }
                    model.endDrag()
                }
            }
    }

    private func applyTranslation(_ translation: CGSize, from origin: CGPoint) {
        let column = SnapAxis.fractionalTick(at: origin.x + translation.width, length: gridSize.width)
        let row = SnapAxis.fractionalTick(at: origin.y + translation.height, length: gridSize.height)
        model.updateDrag(target, columnTick: column, rowTick: row)
    }

    private func cancelTracking() {
        guard dragOrigin != nil else { return }
        dragOrigin = nil
        if model.activeDivider == target { model.cancelDrag() }
    }

    private var cursor: NSCursor {
        target.isIntersection ? .crosshair : target.column != nil ? .resizeLeftRight : .resizeUpDown
    }

    private var label: String {
        if let column = target.column, let row = target.row {
            return "Intersection, column \(column + 1), row \(row + 1)"
        }
        if let column = target.column { return "Column divider \(column + 1)" }
        return "Row divider \((target.row ?? 0) + 1)"
    }

    private var valueLabel: String {
        var values: [String] = []
        if let column = target.column, model.grid.columns.dividers.indices.contains(column) {
            let tick =
                model.dragPreview.flatMap { $0.target.column == column ? $0.columnTick : nil }
                ?? Double(model.grid.columns.dividers[column])
            values.append("Horizontal \(tick.formatted(.number.precision(.fractionLength(0...1)))) / 32")
        }
        if let row = target.row, model.grid.rows.dividers.indices.contains(row) {
            let tick =
                model.dragPreview.flatMap { $0.target.row == row ? $0.rowTick : nil }
                ?? Double(model.grid.rows.dividers[row])
            values.append("Vertical \(tick.formatted(.number.precision(.fractionLength(0...1)))) / 32")
        }
        return values.joined(separator: ", ")
    }

    private func nudge(column: Int, row: Int) -> KeyPress.Result {
        guard target.column.map({ model.grid.columns.dividers.indices.contains($0) }) ?? true,
            target.row.map({ model.grid.rows.dividers.indices.contains($0) }) ?? true
        else { return .ignored }
        guard (column != 0 && target.column != nil) || (row != 0 && target.row != nil) else { return .ignored }
        let x = target.column.map { model.grid.columns.dividers[$0] + column }
        let y = target.row.map { model.grid.rows.dividers[$0] + row }
        _ = withAnimation(reduceMotion ? nil : .easeOut(duration: 0.1)) {
            model.move(target, columnTick: x, rowTick: y)
        }
        return .handled
    }
}
