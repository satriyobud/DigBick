#!/bin/bash
set -e

# setup.sh
# Downloads xcodegen locally and generates the Xcode project

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$DIR"

BUILD_DIR=".build/tools"
XCODEGEN_DIR="$BUILD_DIR/xcodegen"
XCODEGEN_BIN="$XCODEGEN_DIR/bin/xcodegen"

if [ ! -f "$XCODEGEN_BIN" ]; then
    echo "Downloading XcodeGen to $BUILD_DIR..."
    mkdir -p "$BUILD_DIR"
    curl -sL https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip -o "$BUILD_DIR/xcodegen.zip"
    unzip -q "$BUILD_DIR/xcodegen.zip" -d "$BUILD_DIR"
    rm "$BUILD_DIR/xcodegen.zip"
fi

echo "Generating DigBick.xcodeproj..."
"$XCODEGEN_BIN" generate

echo "Done! You can now open DigBick.xcodeproj in Xcode."
