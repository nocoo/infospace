import InfoSpaceCore
import SwiftUI

/// Optional native controls. They can live in a toolbar, a workspace region or any other SwiftUI view.
@MainActor
public struct InfoSpaceLayoutControls: View {
    private let model: InfoSpaceModel
    private let style: InfoSpaceStyle
    private let expansion: Binding<Bool>?
    private let changeDimensions: ((Int, Int) -> Void)?
    @State private var locallyExpanded = true
    @State private var expandedWidth: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The default dimension action preserves all spaces and disables layouts with insufficient capacity.
    /// Supply `onDimensionsChange` to implement a different policy, such as a dense demo preset.
    public init(
        model: InfoSpaceModel, style: InfoSpaceStyle = .init(), isExpanded: Binding<Bool>? = nil,
        onDimensionsChange: ((Int, Int) -> Void)? = nil
    ) {
        self.model = model
        self.style = style
        expansion = isExpanded
        changeDimensions = onDimensionsChange
    }

    private var isExpanded: Bool { expansion?.wrappedValue ?? locallyExpanded }

    public var body: some View {
        HStack(spacing: 0) {
            controls
                .padding(.trailing, 8)
                .fixedSize()
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.width
                } action: {
                    expandedWidth = $0
                }
                .frame(width: isExpanded ? (expandedWidth > 0 ? expandedWidth : nil) : 0, alignment: .trailing)
                .clipped()
                .opacity(isExpanded ? 1 : 0)
                .allowsHitTesting(isExpanded)
                .accessibilityHidden(!isExpanded)
            Button {
                withAnimation(reduceMotion ? nil : style.motion.controls) {
                    if let expansion { expansion.wrappedValue.toggle() } else { locallyExpanded.toggle() }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 0 : 180))
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .background(style.theme.controlBackground, in: RoundedRectangle(cornerRadius: 8))
                    .contentShape(.rect)
            }
            .help(isExpanded ? "Collapse layout controls" : "Expand layout controls")
            .accessibilityLabel(isExpanded ? "Collapse layout controls" : "Expand layout controls")
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityIdentifier("toggle-layout-controls")
        }
        .buttonStyle(.plain)
        .foregroundStyle(style.theme.foreground)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityIdentifier("infospace-layout-controls")
    }

    private var controls: some View {
        HStack(spacing: 14) {
            HStack(spacing: 3) {
                preset(rows: 2, columns: 2)
                preset(rows: 2, columns: 4)
                preset(rows: 3, columns: 4)
            }
            .padding(3)
            .background(style.theme.controlBackground, in: RoundedRectangle(cornerRadius: 9))
            dimensionControl("Rows", value: model.grid.rows.count, identifier: "rows", isRow: true)
            dimensionControl("Columns", value: model.grid.columns.count, identifier: "columns", isRow: false)
            HStack(spacing: 6) {
                controlButton("grid", title: "Show grid", id: "toggle-grid", selected: model.showsGrid) {
                    model.showsGrid.toggle()
                }
                controlButton(
                    "arrow.left.and.right.righttriangle.left.righttriangle.right",
                    title: "Balance rows and columns", id: "balance"
                ) { model.balance() }
                .disabled(model.maximized != nil)
                controlButton("arrow.uturn.backward", title: "Restore all spaces", id: "restore-all") {
                    model.restoreAll()
                }
                .disabled(model.maximized == nil && model.minimized.isEmpty)
            }
        }
    }

    private func preset(rows: Int, columns: Int) -> some View {
        let selected = model.grid.rows.count == rows && model.grid.columns.count == columns
        return Button {
            resize(rows: rows, columns: columns)
        } label: {
            HStack(spacing: 5) {
                LayoutGlyph(rows: rows, columns: columns).frame(width: 17, height: 13)
                Text("\(rows) × \(columns)").font(.system(size: 11, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(selected ? style.theme.foreground : style.theme.secondaryForeground)
            .padding(.horizontal, 8).frame(height: 28)
            .background(
                selected ? style.theme.selectedControlBackground : .clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
            .contentShape(.rect)
        }
        .disabled(!canResize(rows: rows, columns: columns))
        .accessibilityLabel("\(rows) rows, \(columns) columns")
        .accessibilityIdentifier("preset-\(rows)x\(columns)")
    }

    private func dimensionControl(_ title: String, value: Int, identifier: String, isRow: Bool) -> some View {
        HStack(spacing: 5) {
            Text(title).font(.system(size: 11)).foregroundStyle(style.theme.secondaryForeground)
            dimensionButton(value: value - 1, identifier: identifier, isRow: isRow, increasing: false)
            Text("\(value)").font(.system(size: 12, weight: .medium, design: .monospaced)).frame(width: 12)
                .contentTransition(.numericText())
            dimensionButton(value: value + 1, identifier: identifier, isRow: isRow, increasing: true)
        }
    }

    private func dimensionButton(value: Int, identifier: String, isRow: Bool, increasing: Bool) -> some View {
        let rows = isRow ? value : model.grid.rows.count
        let columns = isRow ? model.grid.columns.count : value
        return Button {
            resize(rows: rows, columns: columns)
        } label: {
            Image(systemName: increasing ? "plus" : "minus")
                .font(.system(size: 9, weight: .semibold)).frame(width: 18, height: 24)
                .contentShape(.rect)
        }
        .disabled(!canResize(rows: rows, columns: columns))
        .accessibilityLabel("\(increasing ? "Increase" : "Decrease") \(identifier)")
        .accessibilityIdentifier("\(increasing ? "increase" : "decrease")-\(identifier)")
    }

    private func canResize(rows: Int, columns: Int) -> Bool {
        SnapAxis.supportedCounts.contains(rows) && SnapAxis.supportedCounts.contains(columns)
            && (changeDimensions != nil || rows * columns >= model.spaces.count)
    }

    private func resize(rows: Int, columns: Int) {
        withAnimation(reduceMotion ? nil : style.motion.layout) {
            if let changeDimensions {
                changeDimensions(rows, columns)
            } else {
                // canResize disables every invalid request; the model still validates its public boundary.
                try? model.resizeGrid(rows: rows, columns: columns)
            }
        }
    }

    private func controlButton(
        _ symbol: String, title: String, id: String, selected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 13)).frame(width: 30, height: 30)
                .background(
                    selected ? style.theme.selectedControlBackground : style.theme.controlBackground,
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .contentShape(.rect)
        }
        .help(title).accessibilityLabel(title).accessibilityIdentifier(id)
    }
}

private struct LayoutGlyph: View {
    let rows: Int
    let columns: Int

    var body: some View {
        Canvas { context, size in
            let width = (size.width - CGFloat(columns - 1) * 1.5) / CGFloat(columns)
            let height = (size.height - CGFloat(rows - 1) * 1.5) / CGFloat(rows)
            for row in 0..<rows {
                for column in 0..<columns {
                    let rect = CGRect(
                        x: CGFloat(column) * (width + 1.5), y: CGFloat(row) * (height + 1.5),
                        width: width, height: height)
                    context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .foreground)
                }
            }
        }
    }
}
