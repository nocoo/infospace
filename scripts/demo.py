#!/usr/bin/env python3
"""Launch the Debug app in demo mode for a one-minute product walkthrough."""
import subprocess
import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    app = root / ".build/xcode/Build/Products/Debug/InfoSpace.app/Contents/MacOS/InfoSpace"
    if not app.exists():
        print("Build the app first with ./scripts/build.sh -quiet", file=sys.stderr)
        return 1
    print("Demo mode: the window waits 10 seconds, then runs a ~50s walkthrough.")
    print("Start screen recording during the pause. The window size stays fixed.")
    print("The app stays on the final 2x2 layout; close the window when you stop recording.")
    return subprocess.Popen([str(app), "--demo"]).wait()


if __name__ == "__main__":
    raise SystemExit(main())
