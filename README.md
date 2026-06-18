# DigBick

A tiny Markdown viewer for macOS.

## What it is

DigBick is Preview.app for Markdown.

No vaults.  
No plugins.  
No editing.  
Just Markdown.

## Features

- **Viewer Only:** No editing, no plugins, no vaults. Just pure Markdown.
- **Formats:** Open `.md`, `.markdown`, and `.mdown`.
- **Workspaces:** Drag a folder or press `⇧⌘O` to open a file tree sidebar.
- **Table of Contents:** Outline sidebar with clickable headings (toggle with `⌘T`).
- **Beautiful Rendering:** GitHub-inspired Markdown styling with dark mode support.
- **Local Assets:** Perfectly resolves local images relative to your document.
- **Auto Reload:** Instantly updates when the file is modified externally.
- **Native Polish:** Lightweight macOS interface, fast search, and zero telemetry.

## Getting Started

### Quick Build (No Xcode Required)
If you have the macOS Command Line Tools installed, you can compile the app instantly:

```sh
./build.sh
```
This will generate `DigBick.app` right in the folder. Double-click it to run!

### Xcode Build
You can also open the included `DigBick.xcodeproj` in Xcode, select the `DigBick` scheme targeting "My Mac", and press `⌘R`.

## Privacy

DigBick does not collect analytics, telemetry, or personal data. All parsing and rendering happens locally on your device.

## Support

DigBick is free forever.  
If it helps you, you can support development via PayPal.

## License

MIT
