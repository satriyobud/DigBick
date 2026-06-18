import SwiftUI

struct ContentView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var appState: AppState
    
    @State private var showingSearch = false
    @State private var searchText = ""
    @State private var scrollToHeading: String? = nil

    var body: some View {
        HSplitView {
            // Left File Sidebar
            if appState.showFileSidebar && documentManager.workspaceURL != nil {
                FileSidebarView(nodes: documentManager.fileNodes)
                    .frame(minWidth: 200, idealWidth: 260, maxWidth: 340)
            }
            
            // Main Content
            ZStack {
                if let content = documentManager.content, let baseURL = documentManager.baseURL {
                    WebView(
                        htmlContent: content,
                        baseURL: baseURL,
                        searchText: $searchText,
                        isSearching: $showingSearch,
                        scrollToHeading: $scrollToHeading,
                        onHeadingsReceived: { headings in
                            documentManager.tocHeadings = headings
                        }
                    )
                    .edgesIgnoringSafeArea(.all)
                    
                    if showingSearch {
                        VStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                TextField("Find...", text: $searchText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 200)
                                Button("Done") {
                                    showingSearch = false
                                    searchText = ""
                                }
                            }
                            .padding()
                            .background(VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow))
                            .cornerRadius(8)
                            .shadow(radius: 5)
                            .padding(.top, 10)
                            
                            Spacer()
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("DigBick")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(documentManager.error ?? "Drop a Markdown file or folder here\nor press ⌘O / ⇧⌘O")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 400, idealWidth: 860, maxWidth: .infinity, minHeight: 300, idealHeight: 600, maxHeight: .infinity)
            
            // Right TOC Sidebar
            if appState.showTOCSidebar && documentManager.currentURL != nil {
                TOCSidebarView(headings: documentManager.tocHeadings, onSelect: { id in
                    scrollToHeading = id
                })
                .frame(minWidth: 200, idealWidth: 260, maxWidth: 320)
            }
        }
        .navigationTitle(documentManager.currentURL != nil ? "DigBick — \(documentManager.currentURL!.lastPathComponent)" : "DigBick")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { appState.showFileSidebar.toggle() }) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle File Sidebar")
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: { appState.showTOCSidebar.toggle() }) {
                    Image(systemName: "list.bullet.indent")
                }
                .help("Toggle Table of Contents")
            }
        }
        .background(EventMonitorView(showingSearch: $showingSearch, searchText: $searchText))
    }
}

struct FileSidebarView: View {
    let nodes: [FileNode]
    @EnvironmentObject var documentManager: DocumentManager
    
    var body: some View {
        List(nodes, children: \.children, selection: Binding(
            get: { documentManager.currentURL },
            set: { newURL in
                if let url = newURL {
                    documentManager.openFile(at: url)
                }
            }
        )) { node in
            if node.isDirectory {
                Label(node.url.lastPathComponent, systemImage: "folder")
            } else {
                Label(node.url.lastPathComponent, systemImage: "doc.plaintext")
                    .tag(node.url) // Tag required for native selection binding
            }
        }
        .listStyle(SidebarListStyle())
    }
}

struct TOCSidebarView: View {
    let headings: [HeadingNode]
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Outline")
                .font(.headline)
                .padding(.horizontal)
                .padding(.vertical, 10)
            
            if headings.isEmpty {
                Text("No headings")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            } else {
                List(headings) { heading in
                    Button(action: {
                        onSelect(heading.id)
                    }) {
                        Text(heading.text)
                            .padding(.leading, CGFloat((heading.level - 1) * 12))
                            .lineLimit(1)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(heading.text)
                }
                .listStyle(SidebarListStyle())
            }
        }
    }
}

// Visual Effect for search bar
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// To capture Cmd+F globally without complex responders in MVP
struct EventMonitorView: NSViewRepresentable {
    @Binding var showingSearch: Bool
    @Binding var searchText: String

    func makeNSView(context: Context) -> NSView {
        let view = KeyCaptureView()
        view.onCmdF = {
            self.showingSearch = true
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class KeyCaptureView: NSView {
    var onCmdF: (() -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "f" {
            onCmdF?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
