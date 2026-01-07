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

<img src="https://private-user-images.githubusercontent.com/52437973/532624120-10b97915-63da-40e6-a002-b000542632d0.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3Njc3NDkzMzIsIm5iZiI6MTc2Nzc0OTAzMiwicGF0aCI6Ii81MjQzNzk3My81MzI2MjQxMjAtMTBiOTc5MTUtNjNkYS00MGU2LWEwMDItYjAwMDU0MjYzMmQwLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNjAxMDclMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjYwMTA3VDAxMjM1MlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTAyYmFlYjMyNTY3NGJhYTg1ZWFlOTEzYjBkZDlkZTQwMjc2ZGE3Y2QyNTIzZTJhMWM0ZDUyZmRhZGRmMWFhNWImWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.LWyEgXEYvbPn_es1vqnExGUMzzFQGUdjqUSZp6WkwFA" alt="md.sh window">

<img src="https://private-user-images.githubusercontent.com/52437973/532624129-3b0b6911-b3fc-49ea-a609-ed2e0a12843f.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3Njc3NDkzMzIsIm5iZiI6MTc2Nzc0OTAzMiwicGF0aCI6Ii81MjQzNzk3My81MzI2MjQxMjktM2IwYjY5MTEtYjNmYy00OWVhLWE2MDktZWQyZTBhMTI4NDNmLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNjAxMDclMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjYwMTA3VDAxMjM1MlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWU1MDBhNDgwYWRhNTRjOTQ3YTk1ZmQwY2ZiZmU0MzBjYTc0YTU3YTVhMGMzMWIxZDljMDhjOTg2ZTQyODY5OTkmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.peiHbPmmufzeL1h57uTirVvkvtRB7hD71J7PHbDt33w" alt="md.sh window">

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
