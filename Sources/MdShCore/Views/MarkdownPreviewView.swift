import SwiftUI

struct MarkdownPreviewView: View {
    let fileURL: URL
    @Environment(AppState.self) private var appState

    @State private var html: String = ""
    @State private var fileWatcher: FileWatcher?
    @State private var errorMessage: String?

    // Review comment input
    @State private var pendingComment: PendingComment?
    @State private var commentInput = ""

    struct PendingComment: Identifiable {
        let id = UUID()
        let startLine: Int
        let endLine: Int
        let text: String
    }

    var body: some View {
        Group {
            if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isMarkdownFile {
                ReviewWebView(
                    html: html,
                    baseURL: fileURL.deletingLastPathComponent(),
                    comments: currentFileComments,
                    onLinkClick: handleLinkClick,
                    onAddComment: handleAddComment,
                    onFocusComment: { commentId in
                        appState.focusedCommentId = commentId
                    }
                )
            } else {
                WebView(
                    html: html,
                    baseURL: fileURL.deletingLastPathComponent(),
                    onLinkClick: handleLinkClick
                )
            }
        }
        .onAppear {
            loadFile()
            startWatching()
        }
        .onChange(of: fileURL) { _, _ in
            loadFile()
            startWatching()
        }
        .onDisappear {
            stopWatching()
        }
        .sheet(item: $pendingComment) { pending in
            CommentInputSheet(
                fileName: fileURL.lastPathComponent,
                lineRange: pending.startLine == pending.endLine
                    ? "L\(pending.startLine)"
                    : "L\(pending.startLine)-\(pending.endLine)",
                originalText: pending.text,
                comment: $commentInput,
                onSubmit: { submitComment(pending) },
                onCancel: { pendingComment = nil }
            )
        }
    }

    private var isMarkdownFile: Bool {
        let ext = fileURL.pathExtension.lowercased()
        return ext == "md" || ext == "markdown"
    }

    private var currentFileComments: [ReviewComment] {
        appState.reviewStore.comments.filter { $0.fileURL == fileURL }
    }

    private func handleAddComment(_ startLine: Int, _ endLine: Int, _ text: String) {
        commentInput = ""
        pendingComment = PendingComment(startLine: startLine, endLine: endLine, text: text)
    }

    private func submitComment(_ pending: PendingComment) {
        appState.reviewStore.add(
            fileURL: fileURL,
            startLine: pending.startLine,
            endLine: pending.endLine,
            originalText: pending.text,
            comment: commentInput
        )
        pendingComment = nil
    }

    private func loadFile() {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            renderContent(content)
        } catch {
            errorMessage = "Failed to load file: \(error.localizedDescription)"
        }
    }

    private func renderContent(_ markdown: String) {
        let ext = fileURL.pathExtension.lowercased()

        switch ext {
        case "md", "markdown":
            html = MarkdownRenderer.render(markdown, baseURL: fileURL.deletingLastPathComponent(), enableReview: true)
            errorMessage = nil

        case "json":
            html = renderJSON(markdown)
            errorMessage = nil

        case "yaml", "yml":
            html = renderYAML(markdown)
            errorMessage = nil

        case "mermaid":
            html = renderMermaid(markdown)
            errorMessage = nil

        default:
            html = renderPlainText(markdown)
            errorMessage = nil
        }
    }

    private func renderJSON(_ content: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                :root { color-scheme: light dark; }
                body {
                    font-family: ui-monospace, SFMono-Regular, 'SF Mono', Menlo, monospace;
                    padding: 16px;
                    background: #ffffff;
                    color: #24292f;
                }
                @media (prefers-color-scheme: dark) {
                    body { background: #0d1117; color: #c9d1d9; }
                }
                pre { white-space: pre-wrap; word-wrap: break-word; }
            </style>
        </head>
        <body><pre>\(escapeHTML(formatJSON(content)))</pre></body>
        </html>
        """
    }

    private func renderYAML(_ content: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                :root { color-scheme: light dark; }
                body {
                    font-family: ui-monospace, SFMono-Regular, 'SF Mono', Menlo, monospace;
                    padding: 16px;
                    background: #ffffff;
                    color: #24292f;
                }
                @media (prefers-color-scheme: dark) {
                    body { background: #0d1117; color: #c9d1d9; }
                }
                pre { white-space: pre-wrap; word-wrap: break-word; }
            </style>
        </head>
        <body><pre>\(escapeHTML(content))</pre></body>
        </html>
        """
    }

    private func renderMermaid(_ content: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                :root { color-scheme: light dark; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    padding: 32px;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                    margin: 0;
                    background: #ffffff;
                }
                @media (prefers-color-scheme: dark) {
                    body { background: #0d1117; }
                }
            </style>
            <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
            <script>
                document.addEventListener('DOMContentLoaded', function() {
                    mermaid.initialize({
                        startOnLoad: true,
                        theme: window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default'
                    });
                });
            </script>
        </head>
        <body>
            <div class="mermaid">\(escapeHTML(content))</div>
        </body>
        </html>
        """
    }

    private func renderPlainText(_ content: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                :root { color-scheme: light dark; }
                body {
                    font-family: ui-monospace, SFMono-Regular, 'SF Mono', Menlo, monospace;
                    padding: 16px;
                    background: #ffffff;
                    color: #24292f;
                }
                @media (prefers-color-scheme: dark) {
                    body { background: #0d1117; color: #c9d1d9; }
                }
                pre { white-space: pre-wrap; word-wrap: break-word; }
            </style>
        </head>
        <body><pre>\(escapeHTML(content))</pre></body>
        </html>
        """
    }

    private func formatJSON(_ json: String) -> String {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let result = String(data: formatted, encoding: .utf8) else {
            return json
        }
        return result
    }

    private func escapeHTML(_ string: String) -> String {
        MarkdownRenderer.escapeHTML(string)
    }

    private func handleLinkClick(_ url: URL) {
        appState.openFile(url)
    }

    private func startWatching() {
        stopWatching()
        fileWatcher = FileWatcher(url: fileURL) { [self] in
            loadFile()
        }
        fileWatcher?.start()
    }

    private func stopWatching() {
        fileWatcher?.stop()
        fileWatcher = nil
    }
}

struct CommentInputSheet: View {
    let fileName: String
    let lineRange: String
    let originalText: String
    @Binding var comment: String
    let onSubmit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(fileName)
                    .font(.headline)
                Text(lineRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(originalText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .padding(8)
                .background(.quaternary)
                .cornerRadius(6)

            TextEditor(text: $comment)
                .font(.body)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.background)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.tertiary, lineWidth: 1)
                )

            HStack {
                Button("Cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Add Comment", action: onSubmit)
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                    .disabled(comment.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
