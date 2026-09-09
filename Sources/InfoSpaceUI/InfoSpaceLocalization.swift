import SwiftUI

/// SDK-owned interface text. Values such as panel titles remain host content.
/// Stable cases keep localization separate from layout commands and identities.
public enum InfoSpaceText: Equatable, Sendable {
    case restoreSpace, minimizeSpace, maximizeSpace, restoreLayout
    case minimize(String), maximize(String), restore(String)
    case additionalActions(String), actions(String)
    case collapseLayoutControls, expandLayoutControls, expanded, collapsed
    case rows, columns, increaseRows, decreaseRows, increaseColumns, decreaseColumns
    case showGrid, balanceRowsAndColumns, restoreAllSpaces
    case dimensions(rows: Int, columns: Int)
    case resizeHint
    case intersection(column: Int, row: Int)
    case columnDivider(Int), rowDivider(Int)
    case horizontalPosition(Double), verticalPosition(Double)
    case valueSeparator

    /// English fallback, also available to hosts overriding only selected labels.
    public var defaultText: String {
        switch self {
        case .restoreSpace: "Restore space"
        case .minimizeSpace: "Minimize space"
        case .maximizeSpace: "Maximize space"
        case .restoreLayout: "Restore layout"
        case .minimize(let title): "Minimize \(title)"
        case .maximize(let title): "Maximize \(title)"
        case .restore(let title): "Restore \(title)"
        case .additionalActions(let title): "Additional actions for \(title)"
        case .actions(let title): "Actions for \(title)"
        case .collapseLayoutControls: "Collapse layout controls"
        case .expandLayoutControls: "Expand layout controls"
        case .expanded: "Expanded"
        case .collapsed: "Collapsed"
        case .rows: "Rows"
        case .columns: "Columns"
        case .increaseRows: "Increase rows"
        case .decreaseRows: "Decrease rows"
        case .increaseColumns: "Increase columns"
        case .decreaseColumns: "Decrease columns"
        case .showGrid: "Show grid"
        case .balanceRowsAndColumns: "Balance rows and columns"
        case .restoreAllSpaces: "Restore all spaces"
        case .dimensions(let rows, let columns): "\(rows) rows, \(columns) columns"
        case .resizeHint: "Drag freely and release to snap to the grid, or adjust one tick with the arrow keys"
        case .intersection(let column, let row): "Intersection, column \(column), row \(row)"
        case .columnDivider(let column): "Column divider \(column)"
        case .rowDivider(let row): "Row divider \(row)"
        case .horizontalPosition(let tick):
            "Horizontal \(tick.formatted(.number.precision(.fractionLength(0...1)))) / 32"
        case .verticalPosition(let tick): "Vertical \(tick.formatted(.number.precision(.fractionLength(0...1)))) / 32"
        case .valueSeparator: ", "
        }
    }
}

/// A host-supplied text resolver, evaluated when controls render. The host owns
/// language preferences and resources; changing them must not replace the model.
public struct InfoSpaceLocalization: Sendable {
    private let resolve: @Sendable (InfoSpaceText) -> String

    public init(resolve: @escaping @Sendable (InfoSpaceText) -> String) {
        self.resolve = resolve
    }

    public func text(_ value: InfoSpaceText) -> String { resolve(value) }

    public static let english = InfoSpaceLocalization { $0.defaultText }
}

extension EnvironmentValues {
    @Entry public var infoSpaceLocalization: InfoSpaceLocalization = .english
}

extension View {
    /// Apply to a canvas or to a common ancestor of the canvas and layout controls.
    public func infoSpaceLocalization(_ localization: InfoSpaceLocalization) -> some View {
        environment(\.infoSpaceLocalization, localization)
    }
}
