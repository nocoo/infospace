# SDK 开发与验证记录

Detailed project constraints and procedures. The root [AGENTS.md](../AGENTS.md) defines the quality contract and records current enforcement gaps.

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

The incomplete accessibility validation runs are preserved in [Retrospective.md](../Retrospective.md).

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

The outer workspace also uses a viewport sizing boundary, so speculative parent
size/alignment queries do not descend into every region and panel. Actual
placement retains ordinary region sizing. This increment passed lint, all
58 tests/eight suites, examples, Release/Debug builds and 62/62 native checks
with every capture in .local/workspace-audit/workspace-viewport-native. Footer
geometry, live resizing, editor identity and hidden viewports remain covered.
The 122.2-microsecond geometry projection still excludes consumer rendering.
