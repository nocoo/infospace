# InfoSpace

Native SwiftUI workspace SDK and demo for resizable information panels.
Profile: native-hybrid.
Direction: [SDK API](docs/API.md). Frameworks must preserve this handbook.

## Scope and instruction sources

- This file is the only project handbook; nested files do not compete with it. Do not create a `CLAUDE.md` alias or copy.
- This file is the quality contract; hooks, CI and config are enforcement. Close implementation gaps without lowering the contract. Historical test results are not evidence of a current passing run.
- Human/SDK docs: [README.md](README.md) and [CONTRIBUTING.md](CONTRIBUTING.md). Version: metadata-only `package.json`; `project.yml` mirrors app version. Toolchain/enforcement: `Package.swift`, `.swiftlint.yml`, `.github/workflows/ci.yml`, `scripts/check.sh`. Historical validation: [development records](docs/01-development-validation.md). Accidents: [Retrospective.md](Retrospective.md). Machine workflow: global `AGENTS.md` and Git rules.

## Project invariants

- Keep layout, spans, protected spaces and host lifecycle/appearance hooks generic; consumer APIs, account data and application agent behavior stay outside the SDK.
- Preserve panel/editor identity. Consumers pin tested committed revisions; use `resizeGrid` to retain user panels, while demo-only `setDimensions` may drop out-of-bounds content.
- Localize built-in text through `InfoSpaceLocalization` and typed `InfoSpaceText`; English defaults, custom content and host-owned language storage remain separate from layout state.
- Observe continuous drag at canvas geometry level without rebuilding consumer factories. Keep live resizing, hidden content's last visible viewport and the outer viewport sizing boundary.
- Preserve explicit accessibility containers so enclosing identifiers do not replace child action identifiers.
- Use the personal Git identity and normal pushes. The owner's main-branch workflow remains the default; this audit explicitly permits isolated worktrees.

## Setup and commands

Layout logic in `Sources/InfoSpaceCore` (Swift 6.3); SwiftUI/demo in `Sources/InfoSpaceUI` and `App` (macOS 26+); consumers/tests in `Examples` and `Tests/InfoSpaceCoreTests`; tooling Xcode 26.6+, XcodeGen 2.46+, SwiftLint, Python 3, no JS dependencies. Run at repository root with full Xcode selected by `DEVELOPER_DIR`. Install SwiftLint/XcodeGen using Homebrew. Do not install Node dependencies for the metadata package.

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
./scripts/lint.sh
swift test -Xswiftc -warnings-as-errors
swift build --target InfoSpaceExamples -Xswiftc -warnings-as-errors
./scripts/check.sh
./scripts/build.sh -quiet
python3 scripts/verify-ui.py  # dedicated native window, logged-in desktop
```

## Testing and quality contract

Quality follows `system1-quality` (12 slots `S1..Z1` in `.github/workflows/quality-slots.yml`, `nocoo/base-ci v2026.15` for pinned actions). Statuses: `impl`, `na`, `manual`, or `planned`.

| Slot | Status | Implementation / Evidence |
| --- | --- | --- |
| S1: Typecheck | impl | `python3 scripts/version.py` and `swift build -Xswiftc -warnings-as-errors` |
| S2: Lint | impl | `./scripts/lint.sh` (strict SwiftLint and strict swift-format) |
| S3: Workflow Lint | impl | `actionlint`, immutable `nocoo/base-ci` SHA check, and `yamllint` |
| G1: Secret Scan | impl | `gitleaks detect --no-banner --verbose --redact --no-git` |
| G2: Dependency Vulnerabilities | na | No third-party Swift runtime dependencies or lockfile |
| B1: Build | impl | `./scripts/build.sh -quiet` and `swift build --configuration release -Xswiftc -warnings-as-errors` |
| L1: Unit Tests & Coverage | impl | `swift test -Xswiftc -warnings-as-errors` and `swift build --target InfoSpaceExamples -Xswiftc -warnings-as-errors` |
| L2: Runtime | na | Native SwiftUI SDK; no separate worker runtime |
| L3: Integration | na | No HTTP API integration suite |
| L4: E2E | na (manual) | `python3 scripts/verify-ui.py` runs manually on an unlocked desktop |
| P1: Package Check | na | Swift Package source, not published to npm |
| Z1: Gate | impl | Aggregates all 11 slot outcomes and verifies `tested-sha` |

No local Git hooks are installed. CI runs all implemented native macOS slots via `.github/workflows/ci.yml` → `quality-slots.yml`.
Never bypass commit/push hooks, force-push, or use autofix in checks. Documentation changes do not authorize deploying or implementing new gates.

## Resources and isolation

UI inspection requires an unlocked desktop and only targets its own PID/window. Keep reports in ignored `.local/inspections/`; never touch consumer account data. Geometry projections exclude SwiftUI rendering and are not FPS or Accessibility E2E measurements.

## Operations / release

Follow [CONTRIBUTING.md](CONTRIBUTING.md) for version sync, changelog, builds and authorized main/tag/release publication. Releases distribute the Swift package/source; do not imply a signed/notarized demo download. Historical test evidence remains in [development records](docs/01-development-validation.md).

## Retrospective

Move accident narratives to [Retrospective.md](Retrospective.md); keep at most about ten concise recurring project rules here. Put architecture and operational detail in linked docs.

- Report complete native-run failures honestly even when new assertions passed.
- Preserve editor identity, hidden viewport sizes and action identifiers.
