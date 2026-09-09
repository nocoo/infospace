# SDK guide

Info Space provides two library products: `InfoSpaceCore` and `InfoSpaceUI`. There are no third-party runtime dependencies. All model mutations and SwiftUI interactions run on the main actor.

## Choosing a container

| Component | Purpose |
| --- | --- |
| `InfoSpaceCanvas` | Just the grid. Embed it anywhere, including a small area in the top-right of another view. It imposes no window minimum size or toolbar. |
| `InfoSpaceWorkspace` | The canvas with optional top, bottom, leading and trailing regions, configurable padding and spacing. This is a regular SwiftUI `View`. |
| `InfoSpaceWindow` | An optional native `Scene` with a unified header, screen-relative launch size, centering and configurable window background. |
| `InfoSpaceToolbar` | A native toolbar with a custom brand, up to three adjacent actions, and a custom trailing view. |
| `InfoSpaceLayoutControls` | Reusable row/column, preset, grid, balance and restore controls. Hosts choose the visible groups, metrics and button feedback, with an optional animated collapse button. |
| `InfoSpaceFooter` | Optional leading and trailing content slots aligned to the two edges of the workspace. |

The [embedded grid](../Examples/EmbeddedGridExample.swift), [custom workspace](../Examples/CustomizedWorkspaceExample.swift) and [full window](../Examples/WorkspaceWindowExample.swift) examples are compiled by `swift build --target InfoSpaceExamples`.

## Footer and surrounding regions

`InfoSpaceRegions` accepts independent `top`, `bottom`, `leading` and `trailing` view builders. All are empty by default. Put `InfoSpaceFooter` in the bottom region to fill its left and right sides independently. Either slot can contain text, status indicators, menus or buttons, and either can be omitted. There is no built-in instructional text.

```swift
let regions = InfoSpaceRegions(bottom: {
    InfoSpaceFooter(style: style) {
        Text("Connected")
    } trailing: {
        Button("Restore all") { model.restoreAll() }
    }
})

InfoSpaceWorkspace(canvas: canvas, regions: regions)
```

The footer inherits theme colors and provides configurable minimum height and spacing. Its content remains ordinary SwiftUI, so callers can apply their own fonts, colors and layouts. The workspace also has a general `canvas` view-builder initializer for applying host modifiers or wrapping the grid before embedding it.

## Stable identities and positions

`SpaceID` identifies content; `SpacePosition(row:column:)` identifies a zero-based grid cell. Moving a space does not change its ID. Supply a business identifier such as `SpaceID("inbox")`, or let the initializer generate a UUID. Dense grids seed IDs such as `r0c1`; those strings describe their initial positions only. Use `model.position(of:)` for their current positions.

```swift
let model = InfoSpaceModel(rows: 2, columns: 4, fillEmptyCells: false)
let notes = SpaceID("notes")
try model.insertSpace(notes, at: SpacePosition(row: 1, column: 3))
try model.moveSpace(notes, to: SpacePosition(row: 0, column: 2))
try model.setProportions(rows: [1, 2], columns: [1, 2, 2, 1])
```

The canvas animates successful structural mutations automatically. It keeps content mounted under the same ID while moving, minimizing and maximizing. Removing a space ends that view's lifetime. Keep durable data in your own model; the package does not persist content or layouts across application launches.

## Insertion and collisions

`insertSpace(_:at:collision:)` returns the inserted ID. The new space occupies the requested position. With the default `.shiftForward` policy, occupied cells move forward in row-major order until reaching a vacancy, wrapping to the beginning if needed. A full grid grows by one row; at the row limit it grows by one column. Inserting beyond the current dimensions grows the required axes. Newly created cells remain vacant unless used by the shift.

Use `.reject` to reject an occupied cell. Both axes support 1–8 tracks, so valid row and column indices are 0–7 and the maximum capacity is 64. Invalid positions, duplicate IDs and capacity failures throw `InfoSpaceError`. Failure leaves the committed layout, drag preview and presentation state unchanged.

`moveSpace(_:to:collision:)` swaps with an occupied destination by default; `.reject` instead throws. Moving outside the current dimensions grows the grid within the same limits. `removeSpace(_:)` removes the entry and leaves a vacancy.

Successful insertion, removal, movement, resize and proportion changes exit maximize mode to expose the changed layout. Minimized IDs that still exist remain minimized. Changing an axis's track count redistributes that axis evenly; an unchanged axis retains its proportions.

## Resizing and proportions

`resizeGrid(rows:columns:)` preserves every space. Entries outside the new dimensions move into free cells; insufficient capacity throws an error. Expanding leaves empty cells. The standard layout controls use this policy and disable requests that would lose data.

`setDimensions(rows:columns:)` is a dense-grid convenience used by the demo. It removes entries outside the new dimensions and fills all vacancies. Use `resizeGrid` for workspaces holding user data. To intentionally use the demo policy in controls:

```swift
InfoSpaceLayoutControls(model: model) { rows, columns in
    model.setDimensions(rows: rows, columns: columns)
}
```

`setProportions(rows:columns:)` accepts positive, finite relative weights. Counts must match the existing axes. Committed positions use 32 ticks per axis with a minimum of two ticks per track. Both axes update atomically; invalid input changes neither axis.

Dragging follows the pointer continuously, including within a grid cell. Only release rounds to the nearest tick. Keyboard and accessibility adjustments move one committed tick at a time. An intersection updates both axes together. Neighboring dividers never cross.

## Panels

`SpaceEntry` accepts `span: .cell`, `.rectangle(rows:columns:)`,
`.fullHeight(columns:)` or `.fullWidth(rows:)`. Full-axis spans start at row or
column zero and grow with their grid. Every covered cell participates in collision
and capacity validation. `space(at:)` returns the occupant of any covered cell.
`allowsMove: false` and `allowsRemoval: false` protect stable entries in all layout
commands and snapshot restoration. Minimize, maximize and restore stay available.
Spanning layouts share tracks to prevent overlapping panels; a track containing
only minimized panels collapses. A partly minimized track stays reserved.

`SpaceLayout.applying(_:)` accepts typed `SpaceLayoutCommand` values, independently
of a View or MainActor. Batches validate on copies and fail atomically. The model's
insert/move/remove/resize/proportion methods use these same commands. The older
`setDimensions` dense-demo policy also validates protection and reports a rejected
change in `lastError`; hosts should prefer preserving `resizeGrid`.

`SpaceSnapshot` v1 persists layout, minimized IDs, focus and a monotonic revision.
Its decoder validates grid ticks, spans, duplicate IDs, occupancy and presentation
references. Unsupported or invalid snapshots throw; hosts retain their original
bytes for recovery. `snapshot.applying(command, expectedRevision:)` provides
revision checks and atomic structural/presentation changes. `.restoreSnapshot`
implements validated undo at a **new** revision without weakening protection.

By default `InfoSpaceModel` commits synchronously. A host needing persistence
sets `commandHandler` to receive `(SpaceCommand, expectedRevision)`. All canvas
actions then propose commands without installing optimistic state. The host
validates/persists with its single owner and calls `model.install(accepted)` on
MainActor. Rejecting a command leaves the committed model unchanged; old revisions
cannot be installed. The host reports commit failures and serializes concurrent
requests. Drag previews are transient, never part of a snapshot. Divider-only
commits do not start a structural animation. See `ProtectedWorkspaceExample`.

The required header shows an SF Symbol and a title from `SpaceAppearance`. Its two rightmost buttons remain minimize and maximize/restore. `SpaceAction` values add custom buttons immediately before them. Give actions unique, stable IDs. Additional actions move into an overflow menu when the panel is narrow; extremely small panels put all actions in a compact menu.

```swift
let refresh = SpaceAction(id: "refresh", title: "Refresh", systemImage: "arrow.clockwise") { identity in
    refreshContent(for: identity)
}
```

Pass an `actions: (SpaceID) -> [SpaceAction]` closure to the canvas or workspace. It can return different actions for each panel, including disabled actions or a `ButtonRole`.

`SpaceAppearance` controls the panel title, icon, background color, foreground, header background, control background and border. Disable `usesGradient` for a solid fill, or supply `customBackground: AnyShapeStyle`. `SpacePanelStyle` controls header height, corner radii, content padding, border width and the size threshold below which content is hidden. Hidden content remains mounted.

Hosts can map their design tokens into `SpacePanelStyle.titleFont`, `bannerTitleFont`, `symbolFont`, `bannerSymbolFont` and `actionFont`. Pass fonts already resolved for the host's reading size; the SDK does not own a second appearance preference. `controlSide`, `controlCornerRadius`, `controlSpacing`, `headerSpacing` and the three horizontal padding fields control chrome geometry. Set `headerHeight` to fit the largest font/control, and `contentHeaderOverlap = 0` when content must begin strictly below the header. Enlarging `controlSide` also increases the width required for inline custom actions, so controls move into the existing overflow menu sooner. Very small panels still use compact actions and banners; they do not force the panel wider than its grid track. See the compiled `CustomizedWorkspaceExample` for a 40 pt control configuration.

Set `style.panel.controlButtonStyle = SpaceControlButtonStyle(MyButtonStyle())` to reuse a host's standard hover, press, selection and disabled feedback on built-in actions, custom actions and overflow menus. The supplied SwiftUI `ButtonStyle` receives the original configuration and inherited environment, including enabled state and Reduce Motion. It owns the control background; the SDK does not paint a second fill beneath it. Keep sizing in `SpacePanelStyle` so overflow decisions use the actual hit targets. A nil override keeps the SDK's default appearance. The SDK still owns actions, roles, identifiers and keyboard/accessibility behavior; this hook does not replace business commands.

### Reusable layout controls

Map the host's already resolved fonts, spacing and hit targets into
`style.controls: InfoSpaceLayoutControlStyle`. Its `buttonStyle` uses the same
`SpaceControlButtonStyle` hook as panel actions. The SDK retains its native
buttons, labels, disabled boundaries and model commands; a host does not need to
copy the dimension selector to apply its own appearance.

`InfoSpaceLayoutControlOptions` selects presets, grid, balance and restore groups.
Set `allowsCollapse: false` for an always visible dock. Optional
`canChangeDimensions` adds host restrictions to the SDK's validation, including
spanning and protected spaces. It cannot bypass that validation. Supplying
`onDimensionsChange` still opts into the caller's own resize policy, as in the
dense-demo example above.

```swift
var style = InfoSpaceStyle()
style.controls.controlSide = 40
style.controls.dimensionSize = CGSize(width: 40, height: 40)
style.controls.font = .body
style.controls.buttonStyle = SpaceControlButtonStyle(MyButtonStyle())

InfoSpaceLayoutControls(
    model: model, style: style,
    options: .init(allowsCollapse: false, showsPresets: false,
                   canChangeDimensions: { _, columns in columns >= 2 }))
```

Buttons keep stable accessibility identifiers such as `increase-rows`,
`decrease-columns`, `balance`, `toggle-grid` and `restore-all`. Dimension groups
are `infospace-layout-rows` and `infospace-layout-columns`. These controls may
live in any workspace region; placement is a host concern.

The groups are explicit accessibility containers, preserving each button's own
identifier and label. Hosts that identify an enclosing SwiftUI group should also
use `.accessibilityElement(children: .contain)` before assigning its identifier;
an ungrouped ancestor identifier can otherwise propagate into every child.

### Host localization

Apply `.infoSpaceLocalization(InfoSpaceLocalization { text in ... })` to a common
ancestor of the canvas and optional layout controls. The resolver receives typed
`InfoSpaceText` cases with panel titles, row/column counts or divider positions as
arguments. Use the host's catalog and locale to translate built-in menu items,
tooltips, accessibility labels, resize hints and dimension controls. The compiled
`CustomizedWorkspaceExample` demonstrates overriding selected labels; return
`text.defaultText` for an English fallback. `.english` preserves the default SDK
wording when no override is supplied.

Resolution happens while views render. The host owns language observation and
persistence; an environment change does not replace the model, panel identity or
editor. Keep one `InfoSpaceModel` when switching languages. Custom panel titles,
actions, content, window titles and branding stay under host ownership and are
never translated by the SDK. Language selection does not issue layout commands
or change revisions, protection, undo or serialized state.

The canvas also accepts custom builders:

| Builder | Context |
| --- | --- |
| `.banner { ... }` | Space identity, appearance and a `restore` closure. The custom view owns the restore button. |
| `.emptyCell { ... }` | The vacant `SpacePosition`; useful for an insertion button. |
| `.emptyState { ... }` | Content for a workspace with no expanded spaces. |
| `.resizeHandle { ... }` | Divider target, active, hover and keyboard-focus state. Native hit areas, gestures and keyboard behavior are preserved. |
| `.panelOverlay { ... }` | Identity, appearance, size and presentation state. Use `allowsHitTesting(false)` for purely decorative overlays. |

## Window header actions

`InfoSpaceToolbar` places `leadingActions` immediately to the right of your brand view. It displays the first three entries, using the same theme, 30-point button size and rounded background as the trailing layout controls. An empty array omits the group. The brand and trailing controls are separate view builders, so callers can replace either.

Use `InfoSpaceHeaderAction` with an action closure for commands, or with a `URL` for a link. Links use SwiftUI's `openURL` environment action. The demo includes a link to `https://github.com/nocoo/infospace`.

```swift
let help = InfoSpaceHeaderAction(id: "help", title: "Help", systemImage: "questionmark") {
    showHelp()
}

InfoSpaceToolbar(style: style, leadingActions: [help]) {
    Label("My workspace", systemImage: "square.grid.2x2")
} controls: {
    InfoSpaceLayoutControls(model: model, style: style)
}
```

Add the toolbar with the usual `.toolbar { ... }` modifier inside `InfoSpaceWindow`, or use it in your own window scene. Controls start expanded. Their right-facing arrow collapses them toward the right with an animation. The remaining left-facing arrow reopens them. Supply `isExpanded: Binding<Bool>` to manage expansion from your host app.

## Theme, motion and performance

Share one `InfoSpaceStyle` across the canvas, workspace and toolbar. `InfoSpaceTheme` contains workspace, control, divider and grid colors, with automatic, dark and light defaults. `SpaceLayoutMetrics` controls gaps and the banner shelf. Window colors and initial sizing live in `InfoSpaceWindowConfiguration`; its default launch frame uses 92% of available screen width and 90% of available height.

`InfoSpaceMotion` configures structural transitions, release snapping and toolbar animation. Use `.none` to disable them. The canvas and controls respect the system's Reduce Motion setting. Drag tracking is immediate, without queuing animations for pointer events.

The grid performs one geometry projection for all panels and uses one SwiftUI
`Canvas` for the grid overlay. Each embedded canvas has its own gesture coordinate
space. A dedicated geometry view observes continuous pointer positions and passes
proposals through a SwiftUI `Layout`; host content factories remain outside that
observation boundary. `activeDivider` changes only when a gesture starts or ends,
so inactive handle observers do not invalidate on every pointer tick. Content
stays strongly typed; type erasure is limited to optional replacement slots.

Panels still receive live size proposals and reflow while dragging. Host content
and environment changes remain observable without requiring a layout revision;
there is no equality gate, screenshot freezing or delayed release-only resize.
Stable IDs preserve local editors during movement and presentation changes.
Measure rendering with the content you intend to host. The included geometry
benchmark excludes SwiftUI layout and does not measure display frame rate; native
window checks separately verify content-factory isolation and continuous resize.
