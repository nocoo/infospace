#!/bin/bash
set -euo pipefail
INFOSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
cd "$INFOSPACE_ROOT"
python3 scripts/version.py
./scripts/lint.sh
swift test -Xswiftc -warnings-as-errors
swift build --target InfoSpaceExamples -Xswiftc -warnings-as-errors
swift build --configuration release -Xswiftc -warnings-as-errors
