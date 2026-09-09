<p align="center">
  <img src="../logo.svg" width="128" height="128" alt="Info Space logo" />
</p>
<h1 align="center">Info Space</h1>
<p align="center">Organize information panels in a macOS app and drag dividers to adjust the layout.</p>
<p align="center"><a href="../README.md">简体中文</a></p>

<p align="center"><img src="images/workspace.png" width="720" alt="Info Space panels, native toolbar and custom footer" /></p>

## What it does

Info Space is a SwiftUI workspace SDK for macOS app developers, with a runnable demo app. It arranges information panels in a grid, lets you adjust proportions by dragging dividers or intersections, and supports minimizing panels or maximizing one of them.

`InfoSpaceCore` provides layout and interaction state; `InfoSpaceUI` provides grids, panels, workspaces and native window components. The host app supplies content, data sources and persistence. The demo inbox, project progress and schedule use sample data. Notes are editable, but content and layout are not saved between launches.

## Features

- Arrange panels in 1–8 rows and 1–8 columns. Dividers follow the pointer continuously and snap to a grid with 32 divisions per axis on release.
- Minimize individual panels, or maximize one panel while keeping the others as titled banners. Click a banner to restore it.
- Use APIs to insert, move or remove panels at specific cells, set row and column proportions, and create sparse layouts with vacant cells. Stable IDs preserve existing view state during moves, minimization and restoration.
- Customize panel colors, icons, titles, content and extra actions. Replace banners, vacant cells, empty states, overlays and divider visuals.
- Embed a grid on its own or compose a workspace with surrounding regions and independent footer slots. The native window toolbar supports a custom brand, up to three adjacent actions and collapsible layout controls.
- Adjust dividers with arrow keys, use accessibility labels, and respect the system's Reduce Motion setting.

## Usage

### Integrate the SDK

Requires macOS 26+ and Swift 6.3; the repository uses Xcode 26.6+ for development. In Xcode, add `https://github.com/nocoo/infospace` and select the `InfoSpaceCore` and `InfoSpaceUI` products.

Add the package dependency:

```swift
.package(url: "https://github.com/nocoo/infospace.git", from: "0.1.0")
```

Add the required library products to your target dependencies:

```swift
.product(name: "InfoSpaceCore", package: "infospace"),
.product(name: "InfoSpaceUI", package: "infospace")
```

A minimal grid:

```swift
import InfoSpaceCore
import InfoSpaceUI
import SwiftUI

struct MyGrid: View {
    @State private var model = InfoSpaceModel(rows: 2, columns: 2)

    var body: some View {
        InfoSpaceCanvas(model: model, appearance: { identity in
            SpaceAppearance(title: identity.rawValue, symbol: "doc.text", color: .indigo)
        }) { identity in
            Text("Content for \(identity.rawValue)")
        }
    }
}
```

`InfoSpaceCanvas` embeds in an existing SwiftUI view without imposing a minimum window size. Use `InfoSpaceWorkspace` for surrounding regions and `InfoSpaceWindow` for a native window. See the [SDK guide](API.md) and [examples](../Examples) for complete integration options. Model mutations run on the main actor.

For layouts containing user data, use `resizeGrid(rows:columns:)`: it preserves every panel and throws when capacity is insufficient. The demo's `setDimensions(rows:columns:)` removes panels outside the new bounds and fills vacancies to rebuild a sample layout. See [layout mutations](API.md#insertion-and-collisions) for insertion, movement and collision policies.

### Use the demo

Build and open the demo using the development steps below. Drag dividers to change proportions, use a panel's `+` action to insert at that position, or use the palette button to change its color. The footer shows expanded and collapsed counts and provides a restore-all button.

| Shortcut | Action |
| --- | --- |
| `⌘G` | Show or hide the grid |
| `⌘0` | Balance rows and columns |
| `⇧⌘0` | Restore all panels |
| `⌘1` / `⌘2` / `⌘3` | Select a 2 × 2, 2 × 4 or 3 × 4 layout |
| `Esc` | Leave maximize mode |

Shrinking the demo layout removes panels outside its bounds and their temporary editing state. The host app should manage any content that needs to be saved.

## Development

Install full Xcode and complete its first-launch setup. Building the native app also requires XcodeGen 2.46+ and Python 3. Code checks use SwiftLint and the swift-format bundled with Xcode.

```bash
git clone https://github.com/nocoo/infospace.git
cd infospace
brew install xcodegen swiftlint
./scripts/build.sh -quiet
./scripts/run.sh
```

The build script generates the Xcode project and writes the Debug app to `.build/xcode/Build/Products/Debug/InfoSpace.app`; the run script opens it. Scripts default to `/Applications/Xcode.app/Contents/Developer`. Set `DEVELOPER_DIR` to use another Xcode installation.

| Command | Purpose |
| --- | --- |
| `./scripts/build.sh -quiet` | Build the native demo app |
| `./scripts/run.sh` | Open the demo window, building it first if needed |
| `./scripts/format.sh` | Format Swift code |
| `./scripts/lint.sh` | Run SwiftLint and swift-format checks |
| `./scripts/check.sh` | Run local checks, unit tests, example compilation and a Release package build |

```text
Sources/InfoSpaceCore/       Layout, stable IDs, proportions and snapping
Sources/InfoSpaceUI/         SwiftUI grids, panels, workspaces and windows
App/                        Demo content and native window inspection
Examples/                   SDK consumer examples
Tests/InfoSpaceCoreTests/    Layout and interaction-state unit tests
```

Swift Package Manager manages dependencies and package builds. `package.json` stores release version metadata. See [contributing](../CONTRIBUTING.md) for development and release steps.

## Tests

Run from the repository root. Before calling Swift tools directly, select your installed full Xcode. Adjust this path to match its location:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

| Scope | Command |
| --- | --- |
| Core layout and interaction-state unit tests | `swift test -Xswiftc -warnings-as-errors` |
| SDK consumer example compilation | `swift build --target InfoSpaceExamples -Xswiftc -warnings-as-errors` |

Native window inspection requires a logged-in macOS desktop session, Python 3 and a built Debug app:

```bash
./scripts/build.sh -quiet
python3 scripts/verify-ui.py
```

The inspection script starts a dedicated demo process, interacts with its own window and captures that window. Reports and screenshots are saved to `.local/inspections/`.

## Stack

![Swift](https://img.shields.io/badge/Swift-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-007AFF?logo=swift&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-222222?logo=apple&logoColor=white)

| Area | Implementation |
| --- | --- |
| UI | SwiftUI grids, panels, toolbars and slots |
| Native windows | AppKit window configuration and event handling |
| Layout and state | Swift, Observation, MainActor |
| Package and app builds | Swift Package Manager, XcodeGen, Xcode |
| Verification | Swift Testing, native window event checks, ScreenCaptureKit window captures |
| Development tools | SwiftLint, swift-format, Python scripts |

The SDK has no third-party runtime dependencies.

## Documentation

- [SDK guide](API.md): containers, slots, appearance, actions and layout mutation semantics.
- [Consumer examples](../Examples): embedded grid, customized workspace and native window.
- [Contributing](../CONTRIBUTING.md): development, checks and release steps.
- [Changelog](../CHANGELOG.md): changes by version.

## License

[MIT](../LICENSE) © 2026 NOCOO
