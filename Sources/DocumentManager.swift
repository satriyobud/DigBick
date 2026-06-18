import Foundation
import AppKit

class DocumentManager: ObservableObject {
    @Published var currentURL: URL?
    @Published var content: String?
    @Published var baseURL: URL?
    @Published var error: String?
    
    @Published var wordCount: Int = 0
    @Published var readingTime: Int = 0
    
    // Workspaces & sidebars
    @Published var workspaceURL: URL?
    @Published var fileNodes: [FileNode] = []
    @Published var tocHeadings: [HeadingNode] = []
    
    private var fileWatcher: FileWatcher?
    
    // Scroll state
    private var savedScrollPositions: [String: ScrollEntry] = [:]
    var currentScrollY: Double? = nil
    
    init() {
        loadScrollPositions()
        restoreLastSession()
    }
    
    private func restoreLastSession() {
        if let workspacePath = UserDefaults.standard.string(forKey: "lastWorkspaceURL"),
           let url = URL(string: workspacePath) {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                openWorkspace(at: url)
            } else {
                UserDefaults.standard.removeObject(forKey: "lastWorkspaceURL")
            }
        }
        
        if let filePath = UserDefaults.standard.string(forKey: "lastFileURL"),
           let url = URL(string: filePath) {
            if FileManager.default.fileExists(atPath: url.path) {
                openFile(at: url)
            } else {
                UserDefaults.standard.removeObject(forKey: "lastFileURL")
            }
        }
    }
    
    func openWorkspace(at url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        DispatchQueue.main.async {
            self.workspaceURL = url
            UserDefaults.standard.set(url.absoluteString, forKey: "lastWorkspaceURL")
        }
        
        FileScanner.shared.scan(workspaceURL: url) { [weak self] nodes in
            self?.fileNodes = nodes
        }
    }
    
    func openFile(at url: URL) {
        // Save previous file's scroll position before switching
        if let prevURL = currentURL, let prevY = currentScrollY {
            saveScrollPosition(y: prevY, for: prevURL)
        }
        
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            
            // Simple word count and reading time (approx 250 wpm)
            let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
            let time = max(1, Int(ceil(Double(words) / 250.0)))
            
            DispatchQueue.main.async {
                self.wordCount = words
                self.readingTime = time
                self.tocHeadings.removeAll() // Clear TOC immediately
                self.currentScrollY = nil // Reset current scroll for new file
                self.currentURL = url
                self.baseURL = url.deletingLastPathComponent()
                self.error = nil
                self.render(markdown: text)
                self.setupWatcher(for: url)
                UserDefaults.standard.set(url.absoluteString, forKey: "lastFileURL")
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to open file: \(error.localizedDescription)"
                self.content = nil
                self.currentURL = nil
                self.baseURL = nil
            }
        }
    }
    
    func reload() {
        guard let url = currentURL else { return }
        openFile(at: url)
    }
    
    func openInExternalEditor() {
        guard let url = currentURL else { return }
        NSWorkspace.shared.open(url)
    }
    
    private func setupWatcher(for url: URL) {
        fileWatcher?.stop()
        fileWatcher = FileWatcher(url: url) { [weak self] in
            DispatchQueue.main.async {
                self?.reload()
            }
        }
        fileWatcher?.start()
    }
    
    private func render(markdown: String) {
        guard let templateURL = Bundle.main.url(forResource: "template", withExtension: "html"),
              let templateContent = try? String(contentsOf: templateURL, encoding: .utf8),
              let cssURL = Bundle.main.url(forResource: "github-markdown", withExtension: "css"),
              let cssContent = try? String(contentsOf: cssURL, encoding: .utf8),
              let jsURL = Bundle.main.url(forResource: "marked.min", withExtension: "js"),
              let jsContent = try? String(contentsOf: jsURL, encoding: .utf8) else {
            self.error = "Could not load internal renderer components."
            return
        }
        
        let escapedMarkdown = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
        
        let html = templateContent
            .replacingOccurrences(of: "{{CSS}}", with: cssContent)
            .replacingOccurrences(of: "{{JS}}", with: jsContent)
            .replacingOccurrences(of: "{{MARKDOWN_CONTENT}}", with: escapedMarkdown)
            
        self.content = html
    }
    
    // MARK: - Scroll State Management
    
    private func loadScrollPositions() {
        if let data = UserDefaults.standard.data(forKey: "savedScrollPositions"),
           let decoded = try? JSONDecoder().decode([String: ScrollEntry].self, from: data) {
            self.savedScrollPositions = decoded
        }
    }
    
    func saveScrollPosition(y: Double, for url: URL) {
        let key = url.standardizedFileURL.path
        savedScrollPositions[key] = ScrollEntry(y: y, updatedAt: Date())
        
        // Limit to 100 entries to prevent unbounded growth
        if savedScrollPositions.count > 100 {
            let sorted = savedScrollPositions.sorted { $0.value.updatedAt < $1.value.updatedAt }
            let toRemove = sorted.prefix(savedScrollPositions.count - 100)
            for (k, _) in toRemove {
                savedScrollPositions.removeValue(forKey: k)
            }
        }
        
        if let encoded = try? JSONEncoder().encode(savedScrollPositions) {
            UserDefaults.standard.set(encoded, forKey: "savedScrollPositions")
        }
    }
    
    func getScrollPosition(for url: URL) -> Double? {
        let key = url.standardizedFileURL.path
        return savedScrollPositions[key]?.y
    }
}
