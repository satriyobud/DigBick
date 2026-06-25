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
    var onFindResults: ((Int, Int) -> Void)?
    
    func makeNSView(context: Context) -> WKWebView {
        let prefs = WKPreferences()
        prefs.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let config = WKWebViewConfiguration()
        config.preferences = prefs
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        // Non-persistent store: no disk cache, limits in-memory WebKit storage
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()

        let weakHandler = WeakScriptMessageHandler(context.coordinator)
        config.userContentController.add(weakHandler, name: "digbickTOC")
        config.userContentController.add(weakHandler, name: "digbickHeading")
        config.userContentController.add(weakHandler, name: "digbickScroll")
        config.userContentController.add(weakHandler, name: "digbickFindResults")
        config.userContentController.add(weakHandler, name: "digbickCopy")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsMagnification = false
        webView.allowsBackForwardNavigationGestures = false
        webView.setValue(false, forKey: "drawsBackground")

        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Use hash comparison — avoids keeping a full HTML string copy in the coordinator
        let newHash = htmlContent.hashValue
        if context.coordinator.lastLoadedContentHash != newHash {
            context.coordinator.lastLoadedContentHash = newHash
            context.coordinator.didRestoreScroll = false
            nsView.loadHTMLString(htmlContent, baseURL: baseURL)
        }
        
        let queryChanged = context.coordinator.lastSearchText != searchText
        let visibilityChanged = context.coordinator.lastIsSearching != isSearching
        
        if queryChanged || visibilityChanged {
            context.coordinator.lastSearchText = searchText
            context.coordinator.lastIsSearching = isSearching
            
            if isSearching {
                if !searchText.isEmpty {
                    nsView.evaluateJavaScript("window.digbickFind('\(searchText.replacingOccurrences(of: "'", with: "\\'"))')")
                } else {
                    nsView.evaluateJavaScript("window.digbickClearFind()")
                }
            } else {
                nsView.evaluateJavaScript("window.digbickClearFind()")
            }
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
        nsView.configuration.userContentController.removeScriptMessageHandler(forName: "digbickFindResults")
        nsView.configuration.userContentController.removeScriptMessageHandler(forName: "digbickCopy")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView
        // Hash-based comparison — no full HTML copy stored here
        var lastLoadedContentHash: Int = 0
        var lastSearchText: String?
        var lastIsSearching: Bool?
        var didRestoreScroll = false
        
        init(_ parent: WebView) {
            self.parent = parent
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(handleFindNext), name: NSNotification.Name("DigBickFindNext"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleFindPrev), name: NSNotification.Name("DigBickFindPrev"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleCopyAllText), name: NSNotification.Name("DigBickCopyAllText"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handlePrint), name: NSNotification.Name("DigBickPrint"), object: nil)
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        weak var webViewInstance: WKWebView?
        
        @objc func handleFindNext() {
            webViewInstance?.evaluateJavaScript("window.digbickFindNext()")
        }
        
        @objc func handleFindPrev() {
            webViewInstance?.evaluateJavaScript("window.digbickFindPrevious()")
        }
        
        @objc func handleCopyAllText() {
            webViewInstance?.evaluateJavaScript("if (window.digbickCopyAllText) window.digbickCopyAllText();")
        }
        
        @objc func handlePrint() {
            guard let webView = webViewInstance,
                  let window = webView.window,
                  window.isKeyWindow else { return }
            
            DispatchQueue.main.async {
                let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
                printInfo.horizontalPagination = .clip
                printInfo.verticalPagination = .automatic
                
                let printOperation = webView.printOperation(with: printInfo)
                printOperation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.webViewInstance = webView
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
            } else if message.name == "digbickFindResults", let dict = message.body as? [String: Int], let total = dict["total"], let current = dict["currentIndex"] {
                DispatchQueue.main.async {
                    self.parent.onFindResults?(total, current)
                }
            } else if message.name == "digbickCopy", let dict = message.body as? [String: String], let type = dict["type"], let content = dict["content"] {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(content, forType: .string)
                
                DispatchQueue.main.async {
                    let notificationName = NSNotification.Name("DigBickShowToast")
                    let msg: String
                    if type == "text" { msg = "Copied as Text" }
                    else if type == "markdown" { msg = "Copied as Markdown" }
                    else if type == "code" { msg = "Copied code" }
                    else { msg = "Copied" }
                    
                    NotificationCenter.default.post(name: notificationName, object: msg)
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
