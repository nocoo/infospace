import InfoSpaceCore
import SwiftUI

/// Optional native controls. They can live in a toolbar, a workspace region or any other SwiftUI view.
@MainActor
public struct InfoSpaceLayoutControls: View {
    private let model: InfoSpaceModel
    private let style: InfoSpaceStyle
    private let expansion: Binding<Bool>?
    private let options: InfoSpaceLayoutControlOptions
    private let changeDimensions: ((Int, Int) -> Void)?
    @State private var locallyExpanded = true
    @State private var expandedWidth: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.infoSpaceLocalization) private var localization

    /// The default dimension action preserves all spaces and disables layouts with insufficient capacity.
    /// Supply `onDimensionsChange` to implement a different policy, such as a dense demo preset.
    public init(
        model: InfoSpaceModel, style: InfoSpaceStyle = .init(), isExpanded: Binding<Bool>? = nil,
        options: InfoSpaceLayoutControlOptions = .init(),
        onDimensionsChange: ((Int, Int) -> Void)? = nil
    ) {
        self.model = model
        self.style = style
        expansion = isExpanded
        self.options = options
        changeDimensions = onDimensionsChange
    }

    private var isExpanded: Bool { expansion?.wrappedValue ?? locallyExpanded }

    public var body: some View {
        Group {
            if options.allowsCollapse { collapsibleControls } else { controls }
        }
        .buttonStyle(.plain)
        .foregroundStyle(style.theme.foreground)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("infospace-layout-controls")
    }

    private var collapsibleControls: some View {
        HStack(spacing: 0) {
            controls
                .padding(.trailing, style.controls.spacing)
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
                    .font(style.controls.symbolFont)
                    .frame(width: style.controls.controlSide, height: style.controls.controlSide)
                    .background(controlBackground(selected: false))
                    .contentShape(.rect)
            }
            .help(localization.text(isExpanded ? .collapseLayoutControls : .expandLayoutControls))
            .accessibilityLabel(localization.text(isExpanded ? .collapseLayoutControls : .expandLayoutControls))
            .accessibilityValue(localization.text(isExpanded ? .expanded : .collapsed))
            .accessibilityIdentifier("toggle-layout-controls")
            .modifier(SpaceControlAppearance(style: style.controls.buttonStyle))
        }
    }

    private var controls: some View {
        HStack(spacing: style.controls.groupSpacing) {
            if options.showsPresets {
                HStack(spacing: style.controls.presetPadding) {
                    preset(rows: 2, columns: 2)
                    preset(rows: 2, columns: 4)
                    preset(rows: 3, columns: 4)
                }
                .padding(style.controls.presetPadding)
                .background(
                    style.theme.controlBackground, in: RoundedRectangle(cornerRadius: style.controls.cornerRadius))
            }
            dimensionControl(localization.text(.rows), value: model.grid.rows.count, identifier: "rows", isRow: true)
            dimensionControl(
                localization.text(.columns), value: model.grid.columns.count, identifier: "columns", isRow: false)
            HStack(spacing: style.controls.controlSpacing) {
                if options.showsGrid {
                    controlButton(
                        "grid", title: localization.text(.showGrid), id: "toggle-grid", selected: model.showsGrid
                    ) {
                        model.showsGrid.toggle()
                    }
                }
                if options.showsBalance {
                    controlButton(
                        "arrow.left.and.right.righttriangle.left.righttriangle.right",
                        title: localization.text(.balanceRowsAndColumns), id: "balance"
                    ) { model.balance() }
                    .disabled(model.maximized != nil)
                }
                if options.showsRestoreAll {
                    controlButton(
                        "arrow.uturn.backward", title: localization.text(.restoreAllSpaces), id: "restore-all"
                    ) {
                        model.restoreAll()
                    }
                    .disabled(model.maximized == nil && model.minimized.isEmpty)
                }
            }
        }
    }

    private func preset(rows: Int, columns: Int) -> some View {
        let selected = model.grid.rows.count == rows && model.grid.columns.count == columns
        return Button {
            resize(rows: rows, columns: columns)
        } label: {
            HStack(spacing: style.controls.spacing) {
                LayoutGlyph(rows: rows, columns: columns)
                    .frame(width: style.controls.glyphSize.width, height: style.controls.glyphSize.height)
                Text("\(rows) × \(columns)").font(style.controls.presetFont)
            }
            .foregroundStyle(selected ? style.theme.foreground : style.theme.secondaryForeground)
            .padding(.horizontal, style.controls.presetInset).frame(height: style.controls.presetHeight)
            .background(
                selected ? style.theme.selectedControlBackground : .clear,
                in: RoundedRectangle(cornerRadius: style.controls.cornerRadius)
            )
            .contentShape(.rect)
        }
        .disabled(!canResize(rows: rows, columns: columns))
        .modifier(SpaceControlAppearance(style: style.controls.buttonStyle))
        .accessibilityLabel(localization.text(.dimensions(rows: rows, columns: columns)))
        .accessibilityIdentifier("preset-\(rows)x\(columns)")
    }

    private func dimensionControl(_ title: String, value: Int, identifier: String, isRow: Bool) -> some View {
        HStack(spacing: style.controls.spacing) {
            Text(title).font(style.controls.font).foregroundStyle(style.theme.secondaryForeground)
            dimensionButton(value: value - 1, identifier: identifier, isRow: isRow, increasing: false)
            Text("\(value)").font(style.controls.valueFont).frame(minWidth: style.controls.valueWidth)
                .contentTransition(.numericText())
            dimensionButton(value: value + 1, identifier: identifier, isRow: isRow, increasing: true)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("infospace-layout-\(identifier)")
    }

    private func dimensionButton(value: Int, identifier: String, isRow: Bool, increasing: Bool) -> some View {
        let rows = isRow ? value : model.grid.rows.count
        let columns = isRow ? model.grid.columns.count : value
        return Button {
            resize(rows: rows, columns: columns)
        } label: {
            Image(systemName: increasing ? "plus" : "minus")
                .font(style.controls.dimensionSymbolFont)
                .frame(width: style.controls.dimensionSize.width, height: style.controls.dimensionSize.height)
                .contentShape(.rect)
        }
        .disabled(!canResize(rows: rows, columns: columns))
        .modifier(SpaceControlAppearance(style: style.controls.buttonStyle))
        .accessibilityLabel(
            localization.text(
                isRow
                    ? (increasing ? .increaseRows : .decreaseRows)
                    : (increasing ? .increaseColumns : .decreaseColumns))
        )
        .accessibilityIdentifier("\(increasing ? "increase" : "decrease")-\(identifier)")
    }

    private func canResize(rows: Int, columns: Int) -> Bool {
        guard SnapAxis.supportedCounts.contains(rows), SnapAxis.supportedCounts.contains(columns),
            options.canChangeDimensions?(rows, columns) ?? true
        else { return false }
        if changeDimensions != nil { return true }
        return (try? model.layout.applying(.resize(rows: rows, columns: columns))) != nil
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
            Image(systemName: symbol).font(style.controls.symbolFont)
                .frame(width: style.controls.controlSide, height: style.controls.controlSide)
                .background(controlBackground(selected: selected))
                .contentShape(.rect)
        }
        .help(title).accessibilityLabel(title).accessibilityIdentifier(id)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .modifier(SpaceControlAppearance(style: style.controls.buttonStyle))
    }

    @ViewBuilder private func controlBackground(selected: Bool) -> some View {
        if style.controls.buttonStyle == nil || selected {
            RoundedRectangle(cornerRadius: style.controls.cornerRadius)
                .fill(selected ? style.theme.selectedControlBackground : style.theme.controlBackground)
        }
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
