#!/bin/bash
set -euo pipefail
INFOSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
cd "$INFOSPACE_ROOT"
xcrun swift-format format --in-place --recursive Sources App Tests Examples Package.swift
