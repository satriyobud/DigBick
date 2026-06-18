import SwiftUI
import WebKit

class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    
    init(_ delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

struct WebView: NSViewRepresentable {
    let htmlContent: String
    let baseURL: URL
    
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @Binding var scrollToHeading: String?
    
    var savedScrollY: Double?
    
    var onHeadingsReceived: (([HeadingNode]) -> Void)?
    var onScroll: ((Double) -> Void)?
    var onActiveHeading: ((String) -> Void)?
    
    func makeNSView(context: Context) -> WKWebView {
        let prefs = WKPreferences()
        prefs.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        let config = WKWebViewConfiguration()
        config.preferences = prefs
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        let weakHandler = WeakScriptMessageHandler(context.coordinator)
        config.userContentController.add(weakHandler, name: "digbickTOC")
        config.userContentController.add(weakHandler, name: "digbickHeading")
        config.userContentController.add(weakHandler, name: "digbickScroll")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsMagnification = true
        
        webView.setValue(false, forKey: "drawsBackground")
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        if context.coordinator.lastLoadedContent != htmlContent {
            context.coordinator.didRestoreScroll = false
            nsView.loadHTMLString(htmlContent, baseURL: baseURL)
            context.coordinator.lastLoadedContent = htmlContent
        }
        
        if isSearching && !searchText.isEmpty {
            let config = WKFindConfiguration()
            config.caseSensitive = false
            config.wraps = true
            nsView.find(searchText, configuration: config) { _ in }
        }
        
        if let headingId = scrollToHeading {
            nsView.evaluateJavaScript("window.digbickScrollToHeading('\(headingId)')")
            DispatchQueue.main.async {
                self.scrollToHeading = nil
            }
        }
    }
    
    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        nsView.configuration.userContentController.removeScriptMessageHandler(forName: "digbickTOC")
        nsView.configuration.userContentController.removeScriptMessageHandler(forName: "digbickHeading")
        nsView.configuration.userContentController.removeScriptMessageHandler(forName: "digbickScroll")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView
        var lastLoadedContent: String?
        var didRestoreScroll = false
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if !didRestoreScroll {
                if let y = parent.savedScrollY {
                    webView.evaluateJavaScript("if (window.digbickRestoreScroll) { window.digbickRestoreScroll(\(y)); }")
                }
                didRestoreScroll = true
            }
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
            } else if message.name == "digbickHeading", let id = message.body as? String {
                DispatchQueue.main.async {
                    self.parent.onActiveHeading?(id)
                }
            } else if message.name == "digbickScroll", let y = message.body as? Double {
                DispatchQueue.main.async {
                    self.parent.onScroll?(y)
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                if url.absoluteString == "about:blank" || url == parent.baseURL || url.isFileURL && url.path == parent.baseURL.path {
                    decisionHandler(.allow)
                    return
                }
                
                if navigationAction.navigationType == .linkActivated {
                    if url.isFileURL {
                        if ["md", "markdown", "mdown"].contains(url.pathExtension.lowercased()) {
                            DispatchQueue.main.async {
                                NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
                            }
                        } else {
                            NSWorkspace.shared.open(url)
                        }
                    } else if url.scheme == "http" || url.scheme == "https" {
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
