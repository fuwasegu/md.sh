<p align="center">
  <img src="Resources/AppIcon.png" width="128" height="128" alt="md.sh icon">
</p>

<h1 align="center">md.sh</h1>

<p align="center">
  A lightweight, fast, Mac-native Markdown dashboard optimized for AI coding tools like Claude Code.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-6-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
  <a href="https://github.com/fuwasegu/md.sh/actions/workflows/ci.yml">
    <img src="https://github.com/fuwasegu/md.sh/actions/workflows/ci.yml/badge.svg" alt="CI">
  </a>
</p>

## Features

- **3-Column Layout** — File tree | Preview | Terminal
- **Fast Preview** — GitHub-style rendering, syntax highlighting, Mermaid diagrams
- **File Watching** — Hot reload on external changes with modification badges
- **Review Comments** — Select text to add comments, highlight in preview, send directly to terminal
- **Tabs & Windows** — Open multiple files and projects simultaneously
- **Extension Filter** — Dynamically filter visible files by extension

## Screenshots

*Coming soon*

## Requirements

- macOS 14.0 (Sonoma) or later

## Installation

### Homebrew (Recommended)

```bash
brew install --cask fuwasegu/tap/md-sh
```

### Build from Source

```bash
git clone https://github.com/fuwasegu/md.sh.git
cd md.sh
./build.sh
cp -r "md.sh.app" /Applications/
```

> Requires Xcode 15+ / Swift 6

## Usage

1. **Open Folder** — `Cmd+O` to select a project folder
2. **Select File** — Click a file in the tree to preview
3. **Terminal** — Run Claude Code or other tools in the right pane
4. **Review** — Select text in preview to add comments
5. **Send** — Send comments directly to terminal

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Cmd+O` | Open folder |
| `Cmd+Shift+O` | Open folder in new window |
| `Cmd+N` | New window |
| `Cmd+T` | Toggle terminal |
| `Cmd+,` | Settings |

## Tech Stack

- **SwiftUI** — UI framework
- **swift-markdown** — Markdown parser
- **SwiftTerm** — Terminal emulator
- **WKWebView** — Preview rendering
- **highlight.js** — Syntax highlighting
- **Mermaid.js** — Diagram rendering

## Development

```bash
# Build
swift build

# Run tests
swift test

# Lint
swiftlint lint
```

## License

MIT License
