# InfoSpace development

Follow [CONTRIBUTING.md](CONTRIBUTING.md) for the SDK boundaries and validation.

The repository owner requested direct development on main on 2026-09-09.
Make future SDK changes on main, commit coherent increments and push completed
changes to origin/main. Do not create a feature branch or a separate worktree
unless the owner asks for one. Existing feature work may be merged into main.
Preserve unrelated work and use normal pushes; never force-push shared history.

Use this repository's personal Git identity and GitHub account. Consumer
repositories may use a different account; do not change global credentials or
carry their identity into this public SDK.

Keep InfoSpace generic: layout rules, spans, protected spaces, presentation
lifecycle and host commit/appearance hooks belong here. Product modules, service
APIs, account data and application-specific Agent behavior belong to consumers.
Consumers should pin a tested, committed SDK revision.

Run scripts/check.sh and compile the example and native demo after SDK changes.
UI changes also require the dedicated native window checks in CONTRIBUTING.md.
Record actual validation results; generated native probes are not Accessibility
E2E or a measurement of all SwiftUI rendering performance.

Host language integration uses `InfoSpaceLocalization` and typed `InfoSpaceText`
in the UI target. Keep built-in text behind that environment hook. The host owns
its catalog, language preference and observation; the SDK keeps English defaults
and never translates custom content or stores language in layout state.

On 2026-09-09 the owner paused automated tests during consumer manual validation.
The localization hook compiled with both `InfoSpaceExamples` and the `InfoSpace`
executable in Release (4.00 s and 1.22 s). `scripts/check.sh` and native window
validation remain deferred until automation is resumed. No application was
launched or activated for these builds.

On 2026-09-10 automation was resumed. Continuous drag observation now ends at
the canvas geometry layer; consumer factories do not rebuild for each pointer
tick, while live resizing and host content updates remain enabled. Layout
controls expose generic metrics, button-style and visibility/policy options.
See docs/API.md and the compiled CustomizedWorkspaceExample.

Validation: scripts/check.sh passed lint, 58 Swift tests, the examples and the
Release build. scripts/build.sh -quiet passed. The dedicated native run passed
56/56 checks and all 19 captures, including host-content isolation, live geometry,
editor retention and styled native layout controls. Its 64-panel geometry-only
projection averaged 123.3 microseconds; this is not a rendering FPS measurement.
Private evidence is retained under .local/warp-surface/sdk-native-1.

The layout-controls group and dimension groups are explicit accessibility
containers. An enclosing host group that has an identifier must also contain
its children; otherwise SwiftUI can propagate that identifier into all buttons.
The native control-style inspection verifies all seven real action identifiers.

This accessibility increment passed scripts/check.sh (58 tests, examples and
Release), the Debug build, and the added identifier/control-style assertions in
both native attempts. The complete native runs were 56/57 and 55/57: foreground
loss invalidated a drag in each, and the second also had one ScreenCaptureKit
capture failure. Frames remained fixed and drag previews/commits were correct.
Keep both failed reports under .local/warp-surface/sdk-accessibility-native-{1,2};
do not describe those complete runs as passed. No drag or geometry code changed
in this increment; consumer-mounted dragging is validated separately.

The September 11 lifecycle increment keeps hidden panel content at its last
visible viewport, preserving editor identity without reflowing long lists into
a banner. Visible dragging still updates the viewport. Canvas placement does
not recursively measure its children for unused alignment guides.

Validation passed lint, 58 Swift tests in eight suites, examples, Release and
the native Debug build. Native window runs content-viewport-native-{2,3} each
passed 62/62 checks and every capture, including five hidden-content viewport
and identity checks. The regular runner now requests foreground activation for
its dedicated PID; input checks still assert an active key window and actual
effects. The earlier timeout in content-viewport-native remains preserved.
Private evidence is under .local/workspace-audit. The third run's 64-panel
geometry projection averaged 122.6 microseconds, excluding rendering.
