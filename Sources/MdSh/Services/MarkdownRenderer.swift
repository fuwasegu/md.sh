import Foundation
import Markdown

struct MarkdownRenderer {
    static func render(_ markdown: String, baseURL: URL? = nil, enableReview: Bool = false) -> String {
        // Extract front matter if present
        let (rawYAML, content) = extractFrontMatter(from: markdown)
        let frontMatterHTML = rawYAML.map { renderFrontMatterCard($0) } ?? ""

        let document = Document(parsing: content, options: [.parseBlockDirectives, .parseSymbolLinks])
        var htmlVisitor = HTMLVisitor()
        let bodyHTML = htmlVisitor.visit(document)

        return wrapInHTML(body: frontMatterHTML + bodyHTML, baseURL: baseURL, enableReview: enableReview)
    }

    // MARK: - Front Matter Parsing

    private static func extractFrontMatter(from markdown: String) -> (rawYAML: String?, content: String) {
        let trimmed = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("---") else {
            return (nil, markdown)
        }

        let lines = markdown.components(separatedBy: "\n")
        var frontMatterLines: [String] = []
        var contentStartIndex = 0
        var foundStart = false
        var foundEnd = false

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine == "---" {
                if !foundStart {
                    foundStart = true
                    continue
                } else {
                    foundEnd = true
                    contentStartIndex = index + 1
                    break
                }
            }
            if foundStart && !foundEnd {
                frontMatterLines.append(line)
            }
        }

        guard foundEnd else {
            return (nil, markdown)
        }

        let rawYAML = frontMatterLines.joined(separator: "\n")
        let content = lines.dropFirst(contentStartIndex).joined(separator: "\n")

        return (rawYAML, content)
    }

    private static func renderFrontMatterCard(_ rawYAML: String) -> String {
        guard !rawYAML.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }

        return """
        <details class="front-matter">
        <summary>Front Matter</summary>
        <pre><code class="language-yaml">\(escapeHTML(rawYAML))</code></pre>
        </details>
        """
    }

    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func wrapInHTML(body: String, baseURL: URL?, enableReview: Bool) -> String {
        let css = loadCSS()
        let reviewCSS = enableReview ? reviewStyles : ""
        let reviewJS = enableReview ? reviewScript : ""
        let baseTag = baseURL.map { "<base href=\"\($0.absoluteString)\">" } ?? ""

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            \(baseTag)
            <style>\(css)\(reviewCSS)</style>
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/styles/github.min.css" media="(prefers-color-scheme: light)">
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/styles/github-dark.min.css" media="(prefers-color-scheme: dark)">
            <script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/highlight.min.js"></script>
            <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
            <script>
                document.addEventListener('DOMContentLoaded', function() {
                    // Syntax highlighting
                    hljs.highlightAll();
                    // Mermaid diagrams
                    mermaid.initialize({
                        startOnLoad: true,
                        theme: window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default'
                    });
                });
            </script>
            \(reviewJS)
        </head>
        <body class="markdown-body">
            \(body)
        </body>
        </html>
        """
    }

    private static let reviewStyles = """

    ::selection {
        background: rgba(255, 220, 0, 0.4);
    }
    .review-btn {
        position: fixed;
        bottom: 20px;
        right: 20px;
        background: #238636;
        color: white;
        border: none;
        padding: 8px 16px;
        border-radius: 6px;
        cursor: pointer;
        font-size: 14px;
        display: none;
        z-index: 1000;
        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
    }
    .review-btn:hover {
        background: #2ea043;
    }
    """

    private static let reviewScript = """
    <script>
    (function() {
        document.addEventListener('DOMContentLoaded', function() {
            // Add review button
            const btn = document.createElement('button');
            btn.className = 'review-btn';
            btn.textContent = '+ Add Comment';
            btn.onclick = addComment;
            document.body.appendChild(btn);

            // Show button when text is selected
            document.addEventListener('mouseup', function() {
                setTimeout(updateButton, 10);
            });

            document.addEventListener('selectionchange', function() {
                setTimeout(updateButton, 10);
            });
        });

        function updateButton() {
            const selection = window.getSelection();
            const btn = document.querySelector('.review-btn');

            if (selection && selection.toString().trim().length > 0) {
                btn.style.display = 'block';
            } else {
                btn.style.display = 'none';
            }
        }

        function getLineFromElement(el) {
            while (el && el !== document.body) {
                if (el.dataset && (el.dataset.line || el.dataset.lineStart)) {
                    return {
                        start: parseInt(el.dataset.lineStart || el.dataset.line),
                        end: parseInt(el.dataset.lineEnd || el.dataset.line)
                    };
                }
                el = el.parentElement;
            }
            return null;
        }

        function addComment() {
            const selection = window.getSelection();
            if (!selection || selection.toString().trim().length === 0) return;

            const text = selection.toString().trim();

            // Get line range from selection
            const range = selection.getRangeAt(0);
            const startLine = getLineFromElement(range.startContainer.parentElement);
            const endLine = getLineFromElement(range.endContainer.parentElement);

            let minLine = 1, maxLine = 1;

            if (startLine && endLine) {
                minLine = Math.min(startLine.start, endLine.start);
                maxLine = Math.max(startLine.end, endLine.end);
            } else if (startLine) {
                minLine = startLine.start;
                maxLine = startLine.end;
            } else if (endLine) {
                minLine = endLine.start;
                maxLine = endLine.end;
            }

            // Send to Swift
            window.webkit.messageHandlers.review.postMessage({
                action: 'addComment',
                startLine: minLine,
                endLine: maxLine,
                text: text
            });

            // Clear selection
            selection.removeAllRanges();
            updateButton();
        }
    })();
    </script>
    """

    private static func loadCSS() -> String {
        // Use embedded CSS directly - Bundle.module doesn't work in distributed .app bundles
        return defaultCSS
    }

    private static let defaultCSS = """
    :root {
        color-scheme: light dark;
    }
    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
        line-height: 1.6;
        padding: 32px;
        max-width: 900px;
        margin: 0 auto;
        color: #24292f;
        background: #ffffff;
    }
    @media (prefers-color-scheme: dark) {
        body {
            color: #c9d1d9;
            background: #0d1117;
        }
        a { color: #58a6ff; }
        code { background: #161b22; }
        pre { background: #161b22; }
        blockquote { border-left-color: #3b434b; color: #8b949e; }
        table th, table td { border-color: #30363d; }
        hr { background: #21262d; }
    }
    h1, h2, h3, h4, h5, h6 { margin-top: 24px; margin-bottom: 16px; font-weight: 600; }
    h1 { font-size: 2em; border-bottom: 1px solid #d0d7de; padding-bottom: 0.3em; }
    h2 { font-size: 1.5em; border-bottom: 1px solid #d0d7de; padding-bottom: 0.3em; }
    a { color: #0969da; text-decoration: none; }
    a:hover { text-decoration: underline; }
    code {
        background: #f6f8fa;
        padding: 0.2em 0.4em;
        border-radius: 6px;
        font-family: ui-monospace, SFMono-Regular, 'SF Mono', Menlo, monospace;
        font-size: 85%;
    }
    pre {
        background: #f6f8fa;
        padding: 16px;
        border-radius: 6px;
        overflow: auto;
    }
    pre code { background: none; padding: 0; }
    blockquote {
        border-left: 4px solid #d0d7de;
        padding-left: 16px;
        margin-left: 0;
        color: #57606a;
    }
    ul, ol { padding-left: 2em; }
    table { border-collapse: collapse; width: 100%; }
    table th, table td { border: 1px solid #d0d7de; padding: 6px 13px; }
    table tr:nth-child(2n) { background: #f6f8fa; }
    @media (prefers-color-scheme: dark) {
        table tr:nth-child(2n) { background: #161b22; }
    }
    hr { height: 4px; background: #d0d7de; border: 0; margin: 24px 0; }
    img { max-width: 100%; }
    .mermaid { text-align: center; margin: 16px 0; }

    /* Front Matter */
    .front-matter {
        margin-bottom: 20px;
        border: 1px solid #d0d7de;
        border-radius: 6px;
        font-size: 0.9em;
    }
    .front-matter summary {
        padding: 8px 12px;
        cursor: pointer;
        color: #57606a;
        background: #f6f8fa;
        border-radius: 6px;
    }
    .front-matter[open] summary {
        border-bottom: 1px solid #d0d7de;
        border-radius: 6px 6px 0 0;
    }
    .front-matter pre {
        margin: 0;
        border-radius: 0 0 6px 6px;
    }
    @media (prefers-color-scheme: dark) {
        .front-matter { border-color: #30363d; }
        .front-matter summary { background: #161b22; color: #8b949e; }
        .front-matter[open] summary { border-bottom-color: #30363d; }
    }
    """
}

private struct HTMLVisitor: MarkupVisitor {
    typealias Result = String

    mutating func defaultVisit(_ markup: Markup) -> String {
        markup.children.map { visit($0) }.joined()
    }

    mutating func visitDocument(_ document: Document) -> String {
        document.children.map { visit($0) }.joined()
    }

    mutating func visitHeading(_ heading: Heading) -> String {
        let content = heading.children.map { visit($0) }.joined()
        let lineAttr = lineAttribute(for: heading)
        return "<h\(heading.level)\(lineAttr)>\(content)</h\(heading.level)>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> String {
        let content = paragraph.children.map { visit($0) }.joined()
        let lineAttr = lineAttribute(for: paragraph)
        return "<p\(lineAttr)>\(content)</p>\n"
    }

    mutating func visitText(_ text: Text) -> String {
        escapeHTML(text.string)
    }

    mutating func visitStrong(_ strong: Strong) -> String {
        "<strong>\(strong.children.map { visit($0) }.joined())</strong>"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        "<em>\(emphasis.children.map { visit($0) }.joined())</em>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        "<code>\(escapeHTML(inlineCode.code))</code>"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let language = codeBlock.language ?? ""
        let code = codeBlock.code
        let lineAttr = lineAttribute(for: codeBlock)

        // Handle Mermaid diagrams
        if language.lowercased() == "mermaid" {
            return "<div class=\"mermaid\"\(lineAttr)>\(escapeHTML(code))</div>\n"
        }

        return "<pre\(lineAttr)><code class=\"language-\(language)\">\(escapeHTML(code))</code></pre>\n"
    }

    mutating func visitLink(_ link: Link) -> String {
        let content = link.children.map { visit($0) }.joined()
        let href = link.destination ?? ""
        return "<a href=\"\(escapeHTML(href))\">\(content)</a>"
    }

    mutating func visitImage(_ image: Image) -> String {
        let src = image.source ?? ""
        let alt = image.plainText
        return "<img src=\"\(escapeHTML(src))\" alt=\"\(escapeHTML(alt))\">"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> String {
        let items = unorderedList.children.map { visit($0) }.joined()
        let lineAttr = lineAttribute(for: unorderedList)
        return "<ul\(lineAttr)>\n\(items)</ul>\n"
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) -> String {
        let items = orderedList.children.map { visit($0) }.joined()
        let lineAttr = lineAttribute(for: orderedList)
        return "<ol start=\"\(orderedList.startIndex)\"\(lineAttr)>\n\(items)</ol>\n"
    }

    mutating func visitListItem(_ listItem: ListItem) -> String {
        let content = listItem.children.map { visit($0) }.joined()
        let lineAttr = lineAttribute(for: listItem)
        return "<li\(lineAttr)>\(content)</li>\n"
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        let content = blockQuote.children.map { visit($0) }.joined()
        let lineAttr = lineAttribute(for: blockQuote)
        return "<blockquote\(lineAttr)>\n\(content)</blockquote>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String {
        "<hr>\n"
    }

    mutating func visitTable(_ table: Table) -> String {
        let content = table.children.map { visit($0) }.joined()
        let lineAttr = lineAttribute(for: table)
        return "<table\(lineAttr)>\n\(content)</table>\n"
    }

    mutating func visitTableHead(_ tableHead: Table.Head) -> String {
        let cells = tableHead.children.map { cell -> String in
            let content = cell.children.map { visit($0) }.joined()
            return "<th>\(content)</th>"
        }.joined()
        return "<thead><tr>\(cells)</tr></thead>\n"
    }

    mutating func visitTableBody(_ tableBody: Table.Body) -> String {
        let rows = tableBody.children.map { visit($0) }.joined()
        return "<tbody>\n\(rows)</tbody>\n"
    }

    mutating func visitTableRow(_ tableRow: Table.Row) -> String {
        let cells = tableRow.children.map { cell -> String in
            let content = cell.children.map { visit($0) }.joined()
            return "<td>\(content)</td>"
        }.joined()
        let lineAttr = lineAttribute(for: tableRow)
        return "<tr\(lineAttr)>\(cells)</tr>\n"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        "\n"
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String {
        "<br>\n"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        "<del>\(strikethrough.children.map { visit($0) }.joined())</del>"
    }

    private func lineAttribute(for markup: Markup) -> String {
        guard let range = markup.range else { return "" }
        let start = range.lowerBound.line
        let end = range.upperBound.line
        if start == end {
            return " data-line=\"\(start)\""
        } else {
            return " data-line-start=\"\(start)\" data-line-end=\"\(end)\""
        }
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
