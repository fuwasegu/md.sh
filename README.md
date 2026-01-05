# md.sh

Mac ネイティブの軽量・高速 Markdown ダッシュボード。Claude Code などの AI コーディングツールとの連携に最適化。

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-6-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **3カラムレイアウト** - ファイルツリー | プレビュー | ターミナル
- **高速プレビュー** - GitHub 風スタイル、コードハイライト、Mermaid 図表対応
- **ファイル監視** - 外部変更を即座に検知して Hot Reload
- **レビューコメント** - テキスト選択してコメント、ターミナルへ直接送信
- **タブ/ウィンドウ** - 複数ファイル・プロジェクトを同時に開ける
- **拡張子フィルター** - プロジェクト内の表示ファイルを動的にフィルタリング

## Screenshots

*Coming soon*

## Requirements

- macOS 14.0 (Sonoma) 以上

## Installation

### Homebrew (推奨)

```bash
brew install --cask fuwasegu/tap/md-sh
```

### ソースからビルド

```bash
git clone https://github.com/fuwasegu/md.sh.git
cd md.sh
./build.sh
cp -r "md.sh.app" /Applications/
```

> ビルドには Xcode 15+ / Swift 6 が必要です

## Usage

1. **フォルダを開く** - `Cmd+O` でプロジェクトフォルダを選択
2. **ファイル選択** - 左のツリーからファイルをクリック
3. **ターミナル** - 右側で Claude Code などを実行
4. **レビュー** - プレビュー内のテキストを選択してコメント追加
5. **送信** - コメントをターミナルに直接送信

## Keyboard Shortcuts

| キー | 動作 |
|------|------|
| `Cmd+O` | フォルダを開く |
| `Cmd+Shift+O` | 新規ウィンドウでフォルダを開く |
| `Cmd+N` | 新規ウィンドウ |
| `Cmd+T` | ターミナル表示切替 |
| `Cmd+,` | 設定 |

## Tech Stack

- **SwiftUI** - UI フレームワーク
- **swift-markdown** - Markdown パーサー
- **SwiftTerm** - ターミナルエミュレータ
- **WKWebView** - プレビューレンダリング
- **highlight.js** - コードハイライト
- **Mermaid.js** - 図表レンダリング

## License

MIT License
