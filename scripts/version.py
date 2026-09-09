"""Validate release metadata and synchronize the macOS bundle version."""

import argparse
import json
import re
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sync", action="store_true", help="Update project.yml from package.json")
    arguments = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    version = json.loads((root / "package.json").read_text())["version"]
    if not isinstance(version, str) or not re.fullmatch(r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)", version):
        raise SystemExit("package.json version must be a semantic version such as 0.1.0")

    project = root / "project.yml"
    original = project.read_text()
    updated, count = re.subn(
        r'^    MARKETING_VERSION: "[^"]*"$',
        f'    MARKETING_VERSION: "{version}"',
        original,
        flags=re.MULTILINE,
    )
    if count != 1:
        raise SystemExit("Expected exactly one MARKETING_VERSION in project.yml")
    if original != updated:
        if not arguments.sync:
            raise SystemExit("Bundle version differs from package.json; run python3 scripts/version.py --sync")
        project.write_text(updated)

    latest = re.search(r"^## (\S+)", (root / "CHANGELOG.md").read_text(), flags=re.MULTILINE)
    if latest is None or latest[1] != f"v{version}":
        raise SystemExit(f"The latest CHANGELOG.md entry must be v{version}")
    print(f"Info Space v{version}: release metadata and macOS bundle version agree")


if __name__ == "__main__":
    main()
