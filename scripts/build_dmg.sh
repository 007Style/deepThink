#!/usr/bin/env bash
set -euo pipefail

# build_dmg.sh — Build and package deepThink as a macOS DMG
#
# Usage:
#   ./scripts/build_dmg.sh           # uses default version 1.0.1
#   ./scripts/build_dmg.sh 1.2.0     # override version
#
# Requirements:
#   - Flutter SDK in PATH
#   - create-dmg  (auto-installed via brew if missing)

VERSION="${1:-1.0.1}"
APP_NAME="deepThink"
BUILD_DIR="build/macos/Build/Products/Release"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
OUTPUT_DIR="build"
DMG_NAME="${APP_NAME}-v${VERSION}-macos.dmg"
OUTPUT_PATH="${OUTPUT_DIR}/${DMG_NAME}"

# ── 1. Ensure create-dmg is available ───────────────────────────────────────
if ! command -v create-dmg &>/dev/null; then
  echo "==> create-dmg not found — installing via Homebrew..."
  if ! command -v brew &>/dev/null; then
    echo "ERROR: Homebrew is not installed. Install it from https://brew.sh and re-run." >&2
    exit 1
  fi
  brew install create-dmg
fi

# ── 2. Flutter release build ─────────────────────────────────────────────────
echo "==> Building ${APP_NAME} v${VERSION} for macOS (release)..."
flutter build macos --release

if [ ! -d "${APP_PATH}" ]; then
  echo "ERROR: Expected app bundle not found at: ${APP_PATH}" >&2
  exit 1
fi

# ── 3. Package as DMG ────────────────────────────────────────────────────────
echo "==> Packaging as DMG: ${DMG_NAME}"

# Remove any stale DMG from a previous run
rm -f "${OUTPUT_PATH}"

create-dmg \
  --volname "${APP_NAME}" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 128 \
  --icon "${APP_NAME}.app" 160 185 \
  --hide-extension "${APP_NAME}.app" \
  --app-drop-link 430 185 \
  "${OUTPUT_PATH}" \
  "${APP_PATH}"

# ── 4. Done ──────────────────────────────────────────────────────────────────
echo ""
echo "✓ DMG created successfully:"
echo "  ${OUTPUT_PATH}"
