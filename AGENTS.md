# InfoSpace

Native macOS 26+ SwiftUI workspace SDK (`InfoSpaceCore`, `InfoSpaceUI`) and demo app (`App`) for resizable information panels.
Docs: [README.md](README.md) · [SDK API](docs/API.md) · [CONTRIBUTING.md](CONTRIBUTING.md) · [Validation Records](docs/01-development-validation.md) · [Retrospective.md](Retrospective.md)

## Commands

Run from root with full Xcode 26.6+ (`DEVELOPER_DIR`), Swift 6.3, XcodeGen 2.46+, SwiftLint, and Python 3. Install SwiftLint/XcodeGen via Homebrew; root `package.json` is metadata-only (never install Node dependencies). Layout logic lives in `Sources/InfoSpaceCore`, SwiftUI/demo in `Sources/InfoSpaceUI` and `App`, and consumers/tests in `Examples` and `Tests/InfoSpaceCoreTests`.

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
python3 scripts/version.py                                           # S1 version parity (--sync updates project.yml)
swift build -Xswiftc -warnings-as-errors                             # S1 typecheck
./scripts/lint.sh                                                    # S2 check-only (strict SwiftLint + swift-format)
swift test -Xswiftc -warnings-as-errors                              # L1 unit tests
swift build --target InfoSpaceExamples -Xswiftc -warnings-as-errors  # L1 consumer compile check
./scripts/check.sh                                                   # full local check: version, lint, tests, examples, release build
./scripts/build.sh -quiet                                            # B1 native Debug app build (XcodeGen + xcodebuild)
python3 scripts/verify-ui.py                                         # L4 manual native UI check (unlocked desktop)
```

## Invariants

- Keep layout, spans, protected spaces, and host lifecycle/appearance hooks generic; consumer APIs, account data, and application agent behavior stay outside the SDK.
- Preserve panel/editor identity; consumers pin tested committed revisions. Use `resizeGrid` to retain user panels, while demo-only `setDimensions` may drop out-of-bounds content.
- Localize built-in text via `InfoSpaceLocalization` and typed `InfoSpaceText`; keep English defaults, custom content, and host-owned language storage separate from layout state.
- Observe continuous drag at canvas geometry level without rebuilding consumer factories; preserve live resizing, hidden content's last visible viewport, and the outer viewport sizing boundary.
- Preserve explicit accessibility containers so enclosing identifiers never replace child action identifiers.
- Root `package.json` owns the release version (metadata-only, no JS runtime); `project.yml` mirrors it and `CHANGELOG.md` must match (`python3 scripts/version.py`).
- Historical test runs are not current evidence; report complete native-run failures honestly even when new assertions pass.
- Releases distribute the Swift package/source (no signed/notarized demo download) and require explicit authorization; use personal Git identity on `main` (no force-push) per [CONTRIBUTING.md](CONTRIBUTING.md).

## Quality & Local Gates

Follows `system1-quality`; CI slot definitions and pinned `nocoo/base-ci` (`v2026.24`) action revisions live in `.github/workflows/quality-slots.yml` (called by `.github/workflows/pipeline.yml`; `quality / Z1: Gate` required on `main`), with no automated CD workflow. Status vocabulary: `enforced`, `planned`, `manual`, `N/A`.

- **Enforced in CI**: `S1`, `S2` (check-only, 0 warnings), `S3`, `G1`, `B1` (Release `./scripts/build.sh -quiet` with cached `xcodegen`), `L1` (`swift test` + `InfoSpaceExamples`; no coverage threshold), and `Z1: Gate` (`enforced`; checks all enabled slots and `tested-sha`).
- **Exceptions**: `G2` (no third-party Swift deps/lockfile), `L2` (no worker runtime), `L3` (no HTTP API), and `P1` (Swift source, not npm) are `N/A`; `L4` is `manual` on an unlocked desktop (`N/A` in CI).
- **Local hooks**: `planned` (none installed); run `./scripts/check.sh` and `./scripts/build.sh -quiet` manually, never bypass gates, and never run autofix in checks (use `./scripts/format.sh` explicitly).

## Resources & Isolation

- Native UI inspection (`python3 scripts/verify-ui.py`) requires an unlocked macOS desktop, targets only its own PID/window, and never touches consumer account data.
- Keep inspection reports and captures in gitignored `.local/inspections/`; geometry projections exclude SwiftUI rendering and are not FPS or Accessibility E2E measurements.

## Retrospective

Record accident narratives in [Retrospective.md](Retrospective.md); promote recurring project constraints to `Invariants` above and enforceable safeguards to tests or hooks.
