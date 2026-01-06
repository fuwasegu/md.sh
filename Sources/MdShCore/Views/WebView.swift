import SwiftUI
import WebKit

// Weak wrapper to avoid retain cycle between WKUserContentController and Coordinator
private class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

struct ReviewWebView: NSViewRepresentable {
    let html: String
    let baseURL: URL?
    let comments: [ReviewComment]
    var onLinkClick: ((URL) -> Void)?
    var onAddComment: ((Int, Int, String) -> Void)?
    var onFocusComment: ((UUID) -> Void)?

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        // Add message handler using weak wrapper to avoid retain cycle
        let contentController = configuration.userContentController
        let weakHandler = WeakScriptMessageHandler(delegate: context.coordinator)
        contentController.add(weakHandler, name: "review")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")

        // Initial load
        context.coordinator.lastHTML = html
        context.coordinator.webView = webView
        webView.loadHTMLString(html, baseURL: baseURL)

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Prepare highlights data
        let commentsData: [[String: Any]] = comments.map { comment in
            [
                "id": comment.id.uuidString,
                "startLine": comment.startLine,
                "endLine": comment.endLine,
                "comment": comment.comment
            ]
        }
        context.coordinator.pendingHighlights = commentsData

        // Only reload if HTML actually changed (prevents scroll reset on sheet dismiss)
        if context.coordinator.lastHTML != html {
            context.coordinator.lastHTML = html
            webView.loadHTMLString(html, baseURL: baseURL)
            // Highlights will be applied in didFinish delegate callback
        } else {
            // HTML didn't change, just update highlights immediately
            applyHighlightsNow(to: webView, commentsData: commentsData)
        }
    }

    private func applyHighlightsNow(to webView: WKWebView, commentsData: [[String: Any]]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: commentsData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        webView.evaluateJavaScript("if (window.applyCommentHighlights) { window.applyCommentHighlights(\(jsonString)); }")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLinkClick: onLinkClick, onAddComment: onAddComment, onFocusComment: onFocusComment)
    }

    @MainActor
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let onLinkClick: ((URL) -> Void)?
        let onAddComment: ((Int, Int, String) -> Void)?
        let onFocusComment: ((UUID) -> Void)?
        var lastHTML: String = ""
        weak var webView: WKWebView?
        var pendingHighlights: [[String: Any]]?

        init(onLinkClick: ((URL) -> Void)?, onAddComment: ((Int, Int, String) -> Void)?, onFocusComment: ((UUID) -> Void)?) {
            self.onLinkClick = onLinkClick
            self.onAddComment = onAddComment
            self.onFocusComment = onFocusComment
        }

        // Note: No deinit needed - WeakScriptMessageHandler pattern prevents retain cycles
        // and the message handler is automatically cleaned up when WKWebView is deallocated

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Apply pending highlights after page loads
            guard let highlights = pendingHighlights else { return }
            applyHighlightsToWebView(webView, highlights: highlights)
        }

        private func applyHighlightsToWebView(_ webView: WKWebView, highlights: [[String: Any]]) {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: highlights),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                return
            }
            webView.evaluateJavaScript("if (window.applyCommentHighlights) { window.applyCommentHighlights(\(jsonString)); }")
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "review",
                  let body = message.body as? [String: Any],
                  let action = body["action"] as? String else {
                return
            }

            if action == "addComment",
               let startLine = body["startLine"] as? Int,
               let endLine = body["endLine"] as? Int,
               let text = body["text"] as? String {
                onAddComment?(startLine, endLine, text)
            } else if action == "focusComment",
                      let commentIdString = body["commentId"] as? String,
                      let commentId = UUID(uuidString: commentIdString) {
                onFocusComment?(commentId)
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Handle relative markdown links
            if url.pathExtension.lowercased() == "md" || url.pathExtension.lowercased() == "markdown" {
                onLinkClick?(url)
                decisionHandler(.cancel)
                return
            }

            // Open external links in browser
            if url.scheme == "http" || url.scheme == "https" {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }
}

// Keep original WebView for non-review usage
struct WebView: NSViewRepresentable {
    let html: String
    let baseURL: URL?
    var onLinkClick: ((URL) -> Void)?

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")

        context.coordinator.lastHTML = html
        webView.loadHTMLString(html, baseURL: baseURL)

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastHTML != html {
            context.coordinator.lastHTML = html
            webView.loadHTMLString(html, baseURL: baseURL)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLinkClick: onLinkClick)
    }

    @MainActor
    class Coordinator: NSObject, WKNavigationDelegate {
        let onLinkClick: ((URL) -> Void)?
        var lastHTML: String = ""

        init(onLinkClick: ((URL) -> Void)?) {
            self.onLinkClick = onLinkClick
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if url.pathExtension.lowercased() == "md" || url.pathExtension.lowercased() == "markdown" {
                onLinkClick?(url)
                decisionHandler(.cancel)
                return
            }

            if url.scheme == "http" || url.scheme == "https" {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }
}
