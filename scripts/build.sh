#!/bin/bash
set -euo pipefail
INFOSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
cd "$INFOSPACE_ROOT"
xcodegen generate
xcodebuild -project InfoSpace.xcodeproj -scheme InfoSpace \
  -destination "platform=macOS,arch=$(uname -m)" -configuration Debug \
  -derivedDataPath .build/xcode CODE_SIGN_IDENTITY=- build "$@"
