import XCTest
import Foundation
@testable import MdShCore

final class MarkdownRendererTests: XCTestCase {
    func testEscapeHTML() {
        let input = "<script>alert('xss')</script>"
        let escaped = MarkdownRenderer.escapeHTML(input)

        XCTAssertEqual(escaped, "&lt;script&gt;alert('xss')&lt;/script&gt;")
    }

    func testEscapeHTMLWithAmpersand() {
        let input = "Tom & Jerry"
        let escaped = MarkdownRenderer.escapeHTML(input)

        XCTAssertEqual(escaped, "Tom &amp; Jerry")
    }

    func testEscapeHTMLWithQuotes() {
        let input = "He said \"hello\""
        let escaped = MarkdownRenderer.escapeHTML(input)

        XCTAssertEqual(escaped, "He said &quot;hello&quot;")
    }

    func testRenderBasicMarkdown() {
        let markdown = "# Hello World"
        let html = MarkdownRenderer.render(markdown)

        XCTAssertTrue(html.contains("<h1"))
        XCTAssertTrue(html.contains("Hello World"))
        XCTAssertTrue(html.contains("</h1>"))
    }

    func testRenderWithCodeBlock() {
        let markdown = """
        ```swift
        let x = 1
        ```
        """
        let html = MarkdownRenderer.render(markdown)

        XCTAssertTrue(html.contains("language-swift"))
        XCTAssertTrue(html.contains("let x = 1"))
    }

    func testRenderWithMermaid() {
        let markdown = """
        ```mermaid
        graph TD
            A --> B
        ```
        """
        let html = MarkdownRenderer.render(markdown)

        XCTAssertTrue(html.contains("class=\"mermaid\""))
        XCTAssertTrue(html.contains("graph TD"))
    }

    func testRenderFrontMatter() {
        let markdown = """
        ---
        title: Test
        author: Me
        ---
        # Content
        """
        let html = MarkdownRenderer.render(markdown)

        XCTAssertTrue(html.contains("front-matter"))
        XCTAssertTrue(html.contains("title: Test"))
    }

    func testRenderWithReviewEnabled() {
        let markdown = "# Test"
        let html = MarkdownRenderer.render(markdown, enableReview: true)

        XCTAssertTrue(html.contains("review-btn"))
        XCTAssertTrue(html.contains("applyCommentHighlights"))
    }

    func testRenderWithReviewDisabled() {
        let markdown = "# Test"
        let html = MarkdownRenderer.render(markdown, enableReview: false)

        XCTAssertFalse(html.contains("review-btn"))
        XCTAssertFalse(html.contains("applyCommentHighlights"))
    }

    func testRenderLink() {
        let markdown = "[Click me](https://example.com)"
        let html = MarkdownRenderer.render(markdown)

        XCTAssertTrue(html.contains("href=\"https://example.com\""))
        XCTAssertTrue(html.contains("Click me"))
    }

    func testRenderLinkWithSpecialCharacters() {
        let markdown = "[Test](https://example.com?foo=bar&baz=qux)"
        let html = MarkdownRenderer.render(markdown)

        // URL should be escaped
        XCTAssertTrue(html.contains("href=\"https://example.com?foo=bar&amp;baz=qux\""))
    }

    func testRenderImage() {
        let markdown = "![Alt text](image.png)"
        let html = MarkdownRenderer.render(markdown)

        XCTAssertTrue(html.contains("src=\"image.png\""))
        XCTAssertTrue(html.contains("alt=\"Alt text\""))
    }

    func testRenderTable() {
        let markdown = """
        | Header |
        |--------|
        | Cell   |
        """
        let html = MarkdownRenderer.render(markdown)

        XCTAssertTrue(html.contains("<table"))
        XCTAssertTrue(html.contains("<th>"))
        XCTAssertTrue(html.contains("<td>"))
    }

    func testDataLineAttributes() {
        let markdown = """
        # Heading

        Paragraph text.
        """
        let html = MarkdownRenderer.render(markdown)

        XCTAssertTrue(html.contains("data-line"))
    }
}
