# Info Space

A native SwiftUI information workspace for macOS. Arrange panels in a grid, drag dividers or intersections freely, and snap to the nearest grid tick on release. Embed just the grid or compose a complete window around it.

[中文](README.zh-CN.md) · [SDK guide](docs/API.md) · [Examples](Examples) · [Contributing](CONTRIBUTING.md) · [MIT license](LICENSE)

![Info Space with its unified header and four information panels](docs/images/workspace.png)

## Features

- Independent rows and columns, from 1 × 1 to 8 × 8, on a 32 × 32 grid.
- Continuous dragging with snapping only on release; drag an intersection to adjust both axes together.
- Animated insertion at a specified cell, stable content identities, movement and proportion APIs.
- Maximize a panel while keeping the others as colored, named banners. Minimize individual panels and restore them without losing their content state.
- Custom panel colors, content, header actions, banners, overlays, empty cells and resize handles.
- Custom regions on all four sides, an optional native window and a unified toolbar sharing one row with the traffic lights.
- Up to three custom buttons beside the window brand, plus an animated, collapsible layout toolbar.
- Optional footer with independent left and right content slots.
- Swift 6 concurrency, Observation, keyboard controls, accessibility labels and Reduce Motion support. No third-party runtime dependencies.

## Requirements

macOS 26 or later, Swift 6.3 and Xcode 26.6 or later. Development scripts use the full Xcode toolchain through `DEVELOPER_DIR` without changing the system-wide selection.

## Add the package

In Xcode, add `https://github.com/nocoo/infospace` as a package dependency and select **InfoSpaceCore** and **InfoSpaceUI**. For a Swift package:

```swift
.package(url: "https://github.com/nocoo/infospace.git", from: "0.1.0")
```

Add these products to your target dependencies:

```swift
.product(name: "InfoSpaceCore", package: "infospace"),
.product(name: "InfoSpaceUI", package: "infospace")
```

For local development, add this directory as a local package dependency instead.

## A standalone grid

```swift
import InfoSpaceCore
import InfoSpaceUI
import SwiftUI

struct MyGrid: View {
    @State private var model = InfoSpaceModel(rows: 2, columns: 2)

    var body: some View {
        InfoSpaceCanvas(model: model, appearance: appearance) { identity in
            Text("Content for \(identity.rawValue)")
        }
    }

    private func appearance(_ identity: SpaceID) -> SpaceAppearance {
        SpaceAppearance(title: identity.rawValue, symbol: "doc.text", color: .indigo)
    }
}
```

The canvas has no window chrome or minimum window size. Place it in any SwiftUI layout and give it the size you need. For a full workspace, use `InfoSpaceWorkspace` with `InfoSpaceRegions`; for a native window, use `InfoSpaceWindow`. The [compiled examples](Examples) demonstrate each option.

## Insert and customize

Model APIs run on the main actor. An insertion automatically animates in every attached canvas:

```swift
let model = InfoSpaceModel(rows: 2, columns: 4, fillEmptyCells: false)
let inbox = SpaceID("inbox")
try model.insertSpace(inbox, at: SpacePosition(row: 0, column: 3))
try model.moveSpace(inbox, to: SpacePosition(row: 1, column: 2))
try model.setProportions(rows: [1, 2], columns: [1, 1, 2, 2])
```

When an insertion cell is occupied, existing spaces shift forward with their identities intact. A full grid grows within the 8 × 8 limit; invalid requests throw without changing state. Use `collision: .reject` to require a vacant cell. `resizeGrid` preserves existing spaces; the demo's `setDimensions` convenience fills a dense grid and removes cells outside its new dimensions.

Use `SpaceAppearance` for per-panel colors and the required icon/title, `SpaceAction` for extra panel buttons, and `InfoSpaceStyle` for workspace colors, spacing and animation. The minimize and maximize buttons remain at the far right of each panel header. Use `InfoSpaceToolbar` and `InfoSpaceHeaderAction` for up to three commands or links beside the window brand. See the [SDK guide](docs/API.md) for the full customization surface and collision semantics.

## Run the demo

```sh
brew install xcodegen swiftlint
./scripts/build.sh -quiet
./scripts/run.sh
```

The window launches centered at 92% of the screen's available width and 90% of its height. Sample notes are editable. Each panel's `+` action inserts a space at that cell; the palette action changes its color. The header's code button opens this GitHub repository, and the right arrow collapses the layout controls.

The demo uses sample content and does not persist data between launches. `⌘G` toggles the grid, `⌘0` balances tracks, `⇧⌘0` restores all spaces, `⌘1 / 2 / 3` selects a preset, and `Esc` exits maximize mode.

## Validation

```sh
./scripts/check.sh              # strict lint, unit tests, compiled examples, Release build
python3 scripts/verify-ui.py    # native window checks after building the demo
```

Tests cover insertion and collisions, safe resizing, stable IDs, proportions, continuous dragging, snapping, sparse geometry and all 4,096 minimization patterns of a twelve-panel grid. Strict SwiftLint and swift-format checks run in GitHub Actions alongside the unit tests, examples and Debug/Release builds.

Native window inspection runs separately in a logged-in desktop session. It drives this app's own window, verifies button and drag behavior, and retains screenshots under `.local/inspections/`. Its geometry timing excludes rendering. Live content resizes during dragging; the package currently does not freeze panels into snapshots. See [contributing](CONTRIBUTING.md) for the test workflow.

## License

[MIT](LICENSE), copyright © 2026 NOCOO.
