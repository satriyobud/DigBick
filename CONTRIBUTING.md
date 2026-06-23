# Contributing to DigBick

Thank you for your interest in contributing to DigBick! We welcome and appreciate your help in making this a better Markdown viewer for macOS.

---

## Project Principles

Before proposing or implementing changes, please keep our core project principles in mind:

* **Viewer-Only:** DigBick is designed as a Markdown viewer, not an editor, IDE, or dashboard.
* **Local-First:** All files are scanned, watched, and rendered locally on your device.
* **Lightweight & Snappy:** The app has no database, no background indexing, and uses clean native performance to display documents instantly.
* **Native macOS Feeling:** UI elements should look and behave like standard macOS controls.

---

## Getting Started

1. **Fork the Repository:** Create a fork of [DigBick](https://github.com/satriyobud/DigBick) on GitHub.
2. **Clone the Repo:** Clone your fork locally.
   ```bash
   git clone https://github.com/YOUR_USERNAME/DigBick.git
   ```
3. **Open in Xcode:** Open `DigBick.xcodeproj` or load the Swift package directory directly in Xcode.
4. **Run Locally:** Run the project targeting your local macOS device.
5. **Create a Branch:** Create a branch for your changes:
   ```bash
   git checkout -b feat/my-new-feature
   ```

---

## Build Instructions

If you prefer building from the terminal, you can run our build script:
```bash
./build.sh
```
This will compile the Swift source files, assemble the app bundle, code-sign it, and output `DigBick.app` in the root folder.

---

## Pull Request Guidelines

* **Keep PRs Focused:** Small, single-purpose pull requests are much easier to review and merge.
* **Describe Changes:** Explain what changed, why it changed, and how it was verified.
* **Include Screenshots:** If your change modifies any part of the UI, please attach screenshots or screen recordings.
* **Build Verification:** Run `./build.sh` locally to ensure there are no compilation errors or warnings before submitting.
* **Discuss Large Changes:** For major architectural changes or new features, please open an issue first to discuss the design with us.

---

## Find Something to Work On

Check out the open issues in the repository. If you are a new contributor, look for issues with the `good first issue` label—these are scoped to be simple, self-contained starters.

---

## Suggested GitHub Labels

We use the following labels to categorize issues and pull requests:
* `good first issue`: Ideal starters for external contributors.
* `help wanted`: Open for community assistance.
* `bug`: Reports of unintended behavior.
* `enhancement`: New feature requests or layout improvements.
* `ux`: User experience polish and aesthetics.
* `preview`: Rendering and WebView changes.
* `macos`: Platform-specific controls, menu bar, or OS APIs.
* `documentation`: File and code comment updates.
* `needs discussion`: Architectural decisions requiring alignment.
