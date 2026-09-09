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
