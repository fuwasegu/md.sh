import SwiftUI
import WebKit

struct ReviewWebView: NSViewRepresentable {
    let html: String
    let baseURL: URL?
    var onLinkClick: ((URL) -> Void)?
    var onAddComment: ((Int, Int, String) -> Void)?

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        // Add message handler for review
        let contentController = configuration.userContentController
        contentController.add(context.coordinator, name: "review")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")

        // Initial load
        context.coordinator.lastHTML = html
        webView.loadHTMLString(html, baseURL: baseURL)

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Only reload if HTML actually changed (prevents scroll reset on sheet dismiss)
        if context.coordinator.lastHTML != html {
            context.coordinator.lastHTML = html
            webView.loadHTMLString(html, baseURL: baseURL)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLinkClick: onLinkClick, onAddComment: onAddComment)
    }

    @MainActor
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let onLinkClick: ((URL) -> Void)?
        let onAddComment: ((Int, Int, String) -> Void)?
        var lastHTML: String = ""

        init(onLinkClick: ((URL) -> Void)?, onAddComment: ((Int, Int, String) -> Void)?) {
            self.onLinkClick = onLinkClick
            self.onAddComment = onAddComment
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
