# Project: md.sh (Next-Gen Native Markdown Dashboard)

AI（Claude Code / Aider 等）によるドキュメント生成を最大限に活用するための、Macネイティブな軽量・高速プレビューアー。

---

## 1. コア・コンセプト
* **Anti-Electron:** VS Code よりも圧倒的に軽く、起動とレスポンスを最優先する。
* **Mono-repo Ready:** 数万ファイルあるプロジェクトでも、特定のドキュメント資産のみを抽出して固まらない。
* **AI Co-pilot Friendly:** 外部（ターミナル等）からのファイル変更を瞬時に検知し、プレビューを同期する。

---

## 2. 画面構成 (3-Column Layout)
Mac 標準の `NavigationSplitView` を採用し、直感的な操作感を実現する。

1.  **Left: File Tree (The Filtered Navigator)**
    * プロジェクト内の `.md`, `.json`, `.yaml`, `.mermaid` のみを抽出表示。
    * `node_modules`, `.next`, `.git` 等の巨大ディレクトリはデフォルトでスキャン対象外（無視リスト機能）。
2.  **Center: Preview (Live Renderer)**
    * WebKit ベースの高速レンダリング。
    * Mermaid.js を組み込み、図表をネイティブ級の速度で表示。
    * Markdown 内のリンククリックによるファイルジャンプ（左カラムとの連動）をサポート。
3.  **Right: Embedded Terminal**
    * `SwiftTerm` 等を利用した完全なターミナル。
    * ここで Claude Code を動かし、左でファイルを選び、中央で成果物を確認するループを作る。

---

## 3. 主要機能 (Technical Specifications)

### A. 超高速ファイルスキャン
* **Lazy Loading:** ディレクトリを展開した瞬間にその階層だけをスキャン。
* **Extension Filtering:** 指定拡張子以外はメモリに載せず、ファイル I/O を最小化。

### B. スマート・プレビュー
* **Mermaid.js Integration:** コードブロック ` ```mermaid ` を検知し、即座に図表化。
* **GitHub Flavor:** 見た目は GitHub の README に準拠。
* **Hot Reload:** `NSFilePresenter` を使用。OS レベルでファイル保存を検知し、リロードなしで WebKit の DOM を書き換え。

### C. ナビゲーション
* **Relative Path Jumping:** ドキュメント間の相対パスによる遷移をサポート。
* **Deep Link:** JSON や YAML ファイルを選択した際は、構造化されたビューア（Tree View）で表示するモードを搭載。

---

## 4. 技術スタック (Implementation Strategy)
* **Language:** Swift 6 / SwiftUI
* **Parser:** [swift-markdown](https://github.com/apple/swift-markdown) (Apple)
* **Terminal:** [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm)
* **Rendering:** WKWebView + [Ink](https://github.com/johnsundell/ink) (Markdown to HTML)
* **File Watching:** `NSFilePresenter` / `Combine`

---

## 5. ユースケース
1.  **Claude Code で設計:** 右側のターミナルで「Next.js のコンポーネント構成を mermaid で書いて」と命令。
2.  **即時確認:** 生成された `ARCHITECTURE.md` が中央のプレビューに即座に反映。
3.  **ドキュメント探索:** 左側のツリーで他のドキュメントを高速に切り替え、リンクを辿って仕様を確認。

---

