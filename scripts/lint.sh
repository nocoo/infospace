#!/bin/bash
set -euo pipefail
INFOSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
cd "$INFOSPACE_ROOT"
swiftlint lint --strict
xcrun swift-format lint --strict --recursive Sources App Tests Examples Package.swift
