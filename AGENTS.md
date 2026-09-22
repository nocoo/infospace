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

6DQ keeps its name with unified L1, L2/L3, G2 and D1; the owner merged former G1 into L1 on 2026-09-21. Statuses: `enforced`, `planned`, `manual`, or `N/A`; partial enforcement below does not certify the full required bar.
Unified L1 requires statements, branches, functions and lines each ≥95%, with no skipped/focused tests; strict check-only types and lint/format with zero errors/warnings; installed hooks and failure rejection. Preserve any stricter package threshold. Native tools must identify unmeasured metrics as gaps.
G2 requires dependency and secret scans, with missing required scanners failing.

| Dimension | Status | Required proof and current evidence/gap |
|---|---|---|
| L1 Swift | planned | CI runs Swift tests; there is no four-metric ≥95% coverage gate. The strict static subchecks are enforced: CI → `check.sh` → strict SwiftLint, strict swift-format and compiler warnings-as-errors. |
| L2 SDK integration | planned | Consumer examples compile in CI; no HTTP API applies, and compilation alone does not prove host integration behavior. |
| L3 native UI | manual | `verify-ui.py` checks real native events/captures; CI does not run desktop inspection. |
| G2 | planned | No secret/dependency scanning job; no third-party Swift runtime dependencies, but secret scanning still applies. |
| D1 | manual | Inspection owns a dedicated PID/window and private reports; require its active key window before sending input. |

No local Git hooks are installed. CI uses the shared base-ci test job on macOS 26/Xcode 26.6 for `check.sh` and the native build.

Target hooks: pre-commit checks unified L1 against the index snapshot (`git checkout-index`) in <30s; pre-push checks L2 and G2 in parallel against every stdin push ref/commit in <3min, plus build where applicable. L3 runs in CI or an explicit manual lane.
Never bypass commit/push hooks, force-push, or use autofix in checks. Documentation changes do not authorize deploying or implementing new gates.

## Resources and isolation

UI inspection requires an unlocked desktop and only targets its own PID/window. Keep reports in ignored `.local/inspections/`; never touch consumer account data. Geometry projections exclude SwiftUI rendering and are not FPS or Accessibility E2E measurements.

## Operations / release

Follow [CONTRIBUTING.md](CONTRIBUTING.md) for version sync, changelog, builds and authorized main/tag/release publication. Releases distribute the Swift package/source; do not imply a signed/notarized demo download. Historical test evidence remains in [development records](docs/01-development-validation.md).

## Retrospective

Move accident narratives to [Retrospective.md](Retrospective.md); keep at most about ten concise recurring project rules here. Put architecture and operational detail in linked docs.

- Report complete native-run failures honestly even when new assertions passed.
- Preserve editor identity, hidden viewport sizes and action identifiers.
