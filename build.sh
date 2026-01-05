#!/bin/bash
set -e

cd "$(dirname "$0")"

APP_NAME="md.sh"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building..."
swift build -c release

# Clean old app
rm -rf "$APP_DIR"

# Create app bundle structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp ".build/release/MdSh" "$MACOS_DIR/"

# Create icon from PNG
if [ -f "Resources/AppIcon.png" ]; then
    echo "Creating app icon..."
    mkdir -p AppIcon.iconset

    # Create rounded icon with padding using Swift
    swift -e '
    import AppKit
    let src = NSImage(contentsOfFile: "Resources/AppIcon.png")!
    let canvas = NSSize(width: 1024, height: 1024)
    let scale: CGFloat = 0.80
    let iconSize = NSSize(width: canvas.width * scale, height: canvas.height * scale)
    let offset = (canvas.width - iconSize.width) / 2
    let radius = iconSize.width * 0.22
    let img = NSImage(size: canvas)
    img.lockFocus()
    NSColor.clear.setFill()
    NSRect(origin: .zero, size: canvas).fill()
    let rect = NSRect(x: offset, y: offset, width: iconSize.width, height: iconSize.height)
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
    src.draw(in: rect)
    img.unlockFocus()
    let data = img.tiffRepresentation.flatMap { NSBitmapImageRep(data: $0) }?.representation(using: .png, properties: [:])
    try! data!.write(to: URL(fileURLWithPath: "/tmp/icon_processed.png"))
    ' 2>/dev/null

    SRC="/tmp/icon_processed.png"
    sips -z 16 16     "$SRC" --out AppIcon.iconset/icon_16x16.png      2>/dev/null
    sips -z 32 32     "$SRC" --out AppIcon.iconset/icon_16x16@2x.png   2>/dev/null
    sips -z 32 32     "$SRC" --out AppIcon.iconset/icon_32x32.png      2>/dev/null
    sips -z 64 64     "$SRC" --out AppIcon.iconset/icon_32x32@2x.png   2>/dev/null
    sips -z 128 128   "$SRC" --out AppIcon.iconset/icon_128x128.png    2>/dev/null
    sips -z 256 256   "$SRC" --out AppIcon.iconset/icon_128x128@2x.png 2>/dev/null
    sips -z 256 256   "$SRC" --out AppIcon.iconset/icon_256x256.png    2>/dev/null
    sips -z 512 512   "$SRC" --out AppIcon.iconset/icon_256x256@2x.png 2>/dev/null
    sips -z 512 512   "$SRC" --out AppIcon.iconset/icon_512x512.png    2>/dev/null
    sips -z 1024 1024 "$SRC" --out AppIcon.iconset/icon_512x512@2x.png 2>/dev/null

    iconutil -c icns AppIcon.iconset -o "$RESOURCES_DIR/AppIcon.icns"
    rm -rf AppIcon.iconset /tmp/icon_processed.png
fi

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MdSh</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.personal.mdsh</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>md.sh</string>
    <key>CFBundleDisplayName</key>
    <string>md.sh</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
</dict>
</plist>
EOF

echo ""
echo "Created: $APP_DIR"
echo "Run: open \"$APP_DIR\""
