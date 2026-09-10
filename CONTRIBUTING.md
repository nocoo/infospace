# Contributing

Use Xcode 26.6 or newer with Swift 6.3, plus SwiftLint and XcodeGen:

```sh
brew install swiftlint xcodegen
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
./scripts/check.sh
./scripts/build.sh -quiet
./scripts/run.sh
```

The lint configuration is checked with SwiftLint 0.65.1 and Xcode's swift-format 6.3.0. `./scripts/format.sh` applies formatting; `./scripts/lint.sh` treats every remaining violation as a failure. CI uses Xcode 26.6 on `macos-26` and runs the same checks, followed by a native app build.

Keep layout rules in `InfoSpaceCore`, reusable SwiftUI components in `InfoSpaceUI`, and sample data in `App`. The `Examples` target compiles as a consumer of the public SDK. Add unit tests for changes to layout behavior, identity, collision handling or geometry. Test continuous dragging separately from committed, snapped positions.

For UI changes, also run the native window checks in a logged-in macOS desktop session:

```sh
python3 scripts/verify-ui.py
```

The runner launches a dedicated demo process, requests foreground activation for that PID through System Events, sends native events only to its own window and captures that window with ScreenCaptureKit. Activation requests are recorded separately; the native checks still require an active key window. It intercepts link opening within that inspection process. Reports and screenshots stay in `.local/inspections/` and are excluded from Git. CI does not run this desktop inspection. Its geometry timing excludes SwiftUI layout and rendering.

`python3 scripts/demo.py` plays a one-minute walkthrough of the same window. It waits 10 seconds before moving, then keeps the window size fixed for recording.

Include a short description of the changed behavior and the checks you ran in your pull request. For visual changes, a screenshot or recording is useful. Contributions are provided under the project's [MIT license](LICENSE).

## Releases

The root `package.json` owns the release version. It contains metadata only; Swift Package Manager manages the Swift libraries and app, and no JavaScript runtime is required. `project.yml` mirrors that version into the app bundle and the standard macOS About panel.

For a release, update `package.json`, add a dated `vX.Y.Z` entry at the top of `CHANGELOG.md`, then run:

```sh
python3 scripts/version.py --sync
./scripts/check.sh
./scripts/build.sh -quiet
```

Both build and check scripts reject inconsistent versions. Commit the release changes, push `main`, and verify GitHub Actions. Create and push an annotated `vX.Y.Z` tag for that commit, then publish a GitHub Release using that version's changelog entry. Check CI again five minutes after publication. Initial releases distribute the Swift package and source; no signed or notarized demo download is provided.
