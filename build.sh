#!/bin/bash
set -e

echo "🔨 Building DigBick using Swift Command Line Tools..."

# 1. Compile the Swift source files into an executable
swiftc Sources/*.swift -o DigBick

# 2. Create the standard macOS app bundle structure
echo "📦 Creating app bundle..."
mkdir -p DigBick.app/Contents/MacOS
mkdir -p DigBick.app/Contents/Resources

# 3. Move the executable to the MacOS folder
mv DigBick DigBick.app/Contents/MacOS/

# 4. Copy resources
cp -r Resources/* DigBick.app/Contents/Resources/

# 5. Create PkgInfo
echo "APPL????" > DigBick.app/Contents/PkgInfo

# 6. Create Info.plist manually
cat > DigBick.app/Contents/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>DigBick</string>
    <key>CFBundleDisplayName</key>
    <string>DigBick</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.DigBick</string>
    <key>CFBundleExecutable</key>
    <string>DigBick</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Markdown Document</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Default</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>md</string>
                <string>markdown</string>
                <string>mdown</string>
            </array>
        </dict>
    </array>
    <key>LSSupportsOpeningDocumentsInPlace</key>
    <true/>
</dict>
</plist>
EOF

# 7. Ad-hoc sign the app so macOS doesn't complain as much
echo "✍️ Signing app..."
codesign --force --deep --sign - DigBick.app

echo "✅ Done! DigBick.app is ready."
