#!/bin/bash
set -e

APP_NAME="HelloMac"
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
    Sources/HelloMac/main.swift \
    Sources/HelloMac/AppDelegate.swift \
    Sources/HelloMac/Config.swift \
    Sources/HelloMac/Keychain.swift \
    Sources/HelloMac/AccountPairing.swift \
    Sources/HelloMac/RelayClient.swift \
    Sources/HelloMac/SQLiteDB.swift \
    Sources/HelloMac/Store.swift \
    Sources/HelloMac/Embeddings.swift \
    Sources/HelloMac/AXReader.swift \
    Sources/HelloMac/Tracker.swift \
    Sources/HelloMac/ContentCapture.swift \
    Sources/HelloMac/Extractors.swift \
    Sources/HelloMac/ReminderScheduler.swift \
    Sources/HelloMac/Digest.swift \
    Sources/HelloMac/HttpServer.swift \
    Sources/HelloMac/Api.swift \
    Sources/HelloMac/CalendarExport.swift \
    Sources/HelloMac/McpServer.swift \
    Sources/HelloMac/DashboardHTML.swift \
    Sources/HelloMac/MenuBarView.swift \
    -o "${APP_DIR}/Contents/MacOS/${APP_NAME}"

echo "Configuring app bundle..."
cp Info.plist "${APP_DIR}/Contents/Info.plist"
cp /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/UserIcon.icns \
   "${APP_DIR}/Contents/Resources/AppIcon.icns" 2>/dev/null || true

echo "Signing (ad-hoc)..."
codesign --force --deep -s - --entitlements entitlements.plist "${APP_DIR}" || true

echo "============================================="
echo "Done: ${APP_DIR}"
echo "Run:  open ${APP_DIR}"
echo "============================================="
