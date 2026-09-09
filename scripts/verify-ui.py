#!/usr/bin/env python3
"""Run opt-in native window checks in a dedicated process and retain its screenshots."""
import argparse
from datetime import datetime
import json
from pathlib import Path
import subprocess
import sys
import time


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    app = root / ".build/xcode/Build/Products/Debug/InfoSpace.app/Contents/MacOS/InfoSpace"
    if not app.exists():
        print("Build the app first with ./scripts/build.sh -quiet", file=sys.stderr)
        return 1
    output = (args.output or root / ".local/inspections" / datetime.now().strftime("%Y%m%d-%H%M%S")).resolve()
    output.mkdir(parents=True, exist_ok=True)
    report_file = output / "report.json"
    if report_file.exists():
        print(f"Choose a fresh output directory; {report_file} already exists.", file=sys.stderr)
        return 1
    with (output / "app.log").open("w") as log:
        process = subprocess.Popen([str(app), f"--inspect={output}"], stdout=log, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + 60
            while time.monotonic() < deadline:
                if report_file.exists():
                    report = json.loads(report_file.read_text())
                    failed = [name for name, passed in report["checks"].items() if not passed]
                    capture_failures = [name for name, result in report["captures"].items() if result != "ok"]
                    print(f"Native window checks: {len(report['checks']) - len(failed)}/{len(report['checks'])}")
                    print(f"Screenshots and report: {output}")
                    print(f"64-panel geometry projection: {report['geometry_projection_microseconds_64_panels']:.1f} µs (excludes rendering)")
                    for name in failed:
                        print(f"FAILED: {name}", file=sys.stderr)
                    for name in capture_failures:
                        print(f"CAPTURE FAILED: {name}", file=sys.stderr)
                    return 1 if failed or capture_failures else 0
                error_file = output / "error.txt"
                if error_file.exists():
                    print(error_file.read_text(), file=sys.stderr)
                    return 1
                if process.poll() is not None:
                    print(f"App exited before finishing. See {output / 'app.log'}", file=sys.stderr)
                    return 1
                time.sleep(0.2)
            print(f"Inspection timed out. See {output / 'app.log'}", file=sys.stderr)
            return 1
        finally:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


if __name__ == "__main__":
    raise SystemExit(main())
