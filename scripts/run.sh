#!/bin/bash
set -euo pipefail
INFOSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFOSPACE_APP="$INFOSPACE_ROOT/.build/xcode/Build/Products/Debug/InfoSpace.app"
if [[ ! -d "$INFOSPACE_APP" ]]; then
  "$INFOSPACE_ROOT/scripts/build.sh" -quiet
fi
if [[ $# -eq 0 ]]; then
  open "$INFOSPACE_APP"
else
  open -n "$INFOSPACE_APP" --args "$@"
fi
