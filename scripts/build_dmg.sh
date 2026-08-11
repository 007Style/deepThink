#!/usr/bin/env bash
set -euo pipefail

# build_dmg.sh — Build and package deepThink as a macOS DMG
# Usage: ./scripts/build_dmg.sh [version]
# Requires: create-dmg (brew install create-dmg)

VERSION="${1:-1.0.1}"
APP_NAME="deepThink"
BUILD_DIR="build/macos/Build/Products/Release"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
OUTPUT_DIR="build"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

echo "==> Building ${APP_NAME} v${VERSION} for macOS..."
flutter build macos --release

if [ ! -d "${APP_PATH}" ]; then
  echo "ERROR: App not found at ${APP_PATH}" >&2
  exit 1
fi

echo "==> Packaging as DMG: ${DMG_NAME}"

# Remove old DMG if exists
rm -f "${OUTPUT_DIR}/${DMG_NAME}"

create-dmg \
  --volname "${APP_NAME}" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "${APP_NAME}.app" 175 190 \
  --hide-extension "${APP_NAME}.app" \
  --app-drop-link 425 190 \
  "${OUTPUT_DIR}/${DMG_NAME}" \
  "${APP_PATH}"

echo ""
echo "==> Done: ${OUTPUT_DIR}/${DMG_NAME}"
