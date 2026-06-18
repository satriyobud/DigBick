# DigBick

A tiny Markdown viewer for macOS.

## What it is

DigBick is Preview.app for Markdown.

No vaults.  
No plugins.  
No editing.  
Just Markdown.

## Features

- Open `.md`, `.markdown`, and `.mdown`
- GitHub-inspired Markdown rendering
- Dark mode
- Local images
- Search
- Auto reload
- Open in external editor
- Free forever

## Getting Started

### Building
You can use the provided `setup.sh` to generate the `.xcodeproj` dynamically:

```sh
./setup.sh
```

Alternatively, open `DigBick.xcodeproj` if it is already generated.

To build from command line:
```sh
xcodebuild -project DigBick.xcodeproj -scheme DigBick build
```

### Running
Open `DigBick.xcodeproj` in Xcode, select the `DigBick` scheme and target your Mac, then press ⌘R.

## Privacy

DigBick does not collect analytics, telemetry, or personal data. All parsing and rendering happens locally on your device.

## Support

DigBick is free forever.  
If it helps you, you can support development via PayPal.

## License

MIT
