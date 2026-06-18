import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let htmlContent: String
    let baseURL: URL
    
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @Binding var scrollToHeading: String?
    
    var onHeadingsReceived: (([HeadingNode]) -> Void)?
    
    func makeNSView(context: Context) -> WKWebView {
        let prefs = WKPreferences()
        prefs.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        let config = WKWebViewConfiguration()
        config.preferences = prefs
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        // Add TOC message handler
        config.userContentController.add(context.coordinator, name: "digbickTOC")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsMagnification = true
        
        // Hide background so native dark mode can blend
        webView.setValue(false, forKey: "drawsBackground")
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        if context.coordinator.lastLoadedContent != htmlContent {
            nsView.loadHTMLString(htmlContent, baseURL: baseURL)
            context.coordinator.lastLoadedContent = htmlContent
        }
        
        // Handle find
        if isSearching && !searchText.isEmpty {
            let config = WKFindConfiguration()
            config.caseSensitive = false
            config.wraps = true
            nsView.find(searchText, configuration: config) { result in
                // Find completed
            }
        }
        
        // Handle scroll to heading
        if let headingId = scrollToHeading {
            nsView.evaluateJavaScript("window.digbickScrollToHeading('\(headingId)')")
            DispatchQueue.main.async {
                self.scrollToHeading = nil
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView
        var lastLoadedContent: String?
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "digbickTOC", let array = message.body as? [[String: Any]] {
                var nodes: [HeadingNode] = []
                for dict in array {
                    if let level = dict["level"] as? Int,
                       let text = dict["text"] as? String,
                       let id = dict["id"] as? String {
                        nodes.append(HeadingNode(id: id, text: text, level: level))
                    }
                }
                DispatchQueue.main.async {
                    self.parent.onHeadingsReceived?(nodes)
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                // If it's the base URL or about:blank, allow it
                if url.absoluteString == "about:blank" || url == parent.baseURL || url.isFileURL && url.path == parent.baseURL.path {
                    decisionHandler(.allow)
                    return
                }
                
                // For other links
                if navigationAction.navigationType == .linkActivated {
                    if url.isFileURL {
                        // If it's a markdown file, we might want to open it in DigBick
                        if ["md", "markdown", "mdown"].contains(url.pathExtension.lowercased()) {
                            // Tell the app to open it
                            DispatchQueue.main.async {
                                NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
                            }
                        } else {
                            // Let the system handle it
                            NSWorkspace.shared.open(url)
                        }
                    } else if url.scheme == "http" || url.scheme == "https" {
                        // Open in default browser
                        NSWorkspace.shared.open(url)
                    }
                    decisionHandler(.cancel)
                    return
                }
            }
            
            decisionHandler(.allow)
        }
    }
}
