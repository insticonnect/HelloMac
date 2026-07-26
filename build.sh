#!/bin/bash
set -e

APP_NAME="MitthuAI"
SRC_DIR="Sources/MitthuAI"
BUILD_DIR="build"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"

# Build for the machine we're on (arm64 on Apple Silicon, x86_64 on Intel).
ARCH="$(uname -m)"
TARGET="${ARCH}-apple-macosx12.0"

echo "============================================="
echo "Building ${APP_NAME} for macOS (${TARGET})"
echo "============================================="

echo "Cleaning old build..."
rm -rf "$BUILD_DIR"
mkdir -p "${APP_DIR}/Contents/"{MacOS,Resources}

# Newer SDKs implement SwiftUI property wrappers (@State etc.) as compiler
# macros; bare swiftc needs to be told where the macro plugins live.
SDK_PATH="$(xcrun --show-sdk-path)"
TOOLCHAIN_USR="$(dirname "$(dirname "$(xcrun --find swiftc)")")"
PLUGIN_FLAGS=""
for p in "${SDK_PATH}/usr/lib/swift/host/plugins" \
         "${TOOLCHAIN_USR}/lib/swift/host/plugins"; do
    if [ -d "$p" ]; then
        PLUGIN_FLAGS="${PLUGIN_FLAGS} -plugin-path ${p}"
    fi
done

echo "Compiling Swift sources..."
swiftc \
    -O \
    -sdk "$SDK_PATH" \
    -target "$TARGET" \
    ${PLUGIN_FLAGS} \
    ${SRC_DIR}/main.swift \
    ${SRC_DIR}/AppDelegate.swift \
    ${SRC_DIR}/Config.swift \
    ${SRC_DIR}/Keychain.swift \
    ${SRC_DIR}/AccountPairing.swift \
    ${SRC_DIR}/RelayClient.swift \
    ${SRC_DIR}/SQLiteDB.swift \
    ${SRC_DIR}/Store.swift \
    ${SRC_DIR}/Embeddings.swift \
    ${SRC_DIR}/AXReader.swift \
    ${SRC_DIR}/Tracker.swift \
    ${SRC_DIR}/ContentCapture.swift \
    ${SRC_DIR}/Extractors.swift \
    ${SRC_DIR}/ReminderScheduler.swift \
    ${SRC_DIR}/Digest.swift \
    ${SRC_DIR}/HttpServer.swift \
    ${SRC_DIR}/Api.swift \
    ${SRC_DIR}/McpServer.swift \
    ${SRC_DIR}/DashboardHTML.swift \
    ${SRC_DIR}/MenuBarView.swift \
    -o "${APP_DIR}/Contents/MacOS/${APP_NAME}"

echo "Configuring app bundle..."
cp Info.plist "${APP_DIR}/Contents/Info.plist"
if [ -d "Resources/AppIcon.iconset" ]; then
    iconutil -c icns "Resources/AppIcon.iconset" -o "${APP_DIR}/Contents/Resources/AppIcon.icns"
else
    cp /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/UserIcon.icns \
       "${APP_DIR}/Contents/Resources/AppIcon.icns" 2>/dev/null || true
fi

echo "Signing (ad-hoc)..."
codesign --force --deep -s - --entitlements entitlements.plist "${APP_DIR}" || true

echo "============================================="
echo "Done: ${APP_DIR}"
echo "Run:  open ${APP_DIR}"
echo "============================================="
