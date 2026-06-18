#!/bin/bash
set -e

# make_icns.sh
# Converts a square PNG image into a macOS .icns file

if [ ! -f "logo.png" ]; then
    echo "Error: logo.png not found in the current directory."
    echo "Please save the image as logo.png in Documents/DigBick/"
    exit 1
fi

echo "🎨 Creating macOS App Icon from logo.png..."

ICONSET="Resources/AppIcon.iconset"
mkdir -p "$ICONSET"

# Generate different sizes using sips
sips -z 16 16     logo.png --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32     logo.png --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32     logo.png --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64     logo.png --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128   logo.png --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256   logo.png --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256   logo.png --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512   logo.png --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512   logo.png --out "$ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 logo.png --out "$ICONSET/icon_512x512@2x.png" >/dev/null

# Convert the .iconset folder to .icns
iconutil -c icns "$ICONSET" -o "Resources/AppIcon.icns"

# Clean up the temporary .iconset folder
rm -rf "$ICONSET"

echo "✅ Successfully created Resources/AppIcon.icns!"
