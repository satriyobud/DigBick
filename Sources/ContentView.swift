import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct AppColors {
    let scheme: ColorScheme
    
    var appBg: Color { scheme == .dark ? Color(hex: "#121314") : Color(hex: "#F9F8F7") }
    var docBg: Color { scheme == .dark ? Color(hex: "#161719") : Color(hex: "#FEFEFE") }
    var leftSidebarBg: Color { scheme == .dark ? Color(hex: "#1D1E20") : Color(hex: "#F2F0EE") }
    var leftSidebarFooterBg: Color { scheme == .dark ? Color(hex: "#1D1E20") : Color(hex: "#F1F0EE") }
    var rightSidebarBg: Color { scheme == .dark ? Color(hex: "#191A1C") : Color(hex: "#F9F9F9") }
    var toolbarBg: Color { scheme == .dark ? Color(hex: "#1A1B1D") : Color(hex: "#F9F8F7") }
    var divider: Color { scheme == .dark ? Color(hex: "#2C2D30") : Color(hex: "#DEDCD8") }
    var selectedRow: Color { scheme == .dark ? Color(hex: "#2B2D31") : Color(hex: "#E5E2DF") }
    var selectedText: Color { scheme == .dark ? Color(hex: "#F2F3F5") : Color(hex: "#1F2328") }
    var sidebarPrimary: Color { scheme == .dark ? Color(hex: "#E6E7E9") : Color(hex: "#1F2328") }
    var sidebarSecondary: Color { scheme == .dark ? Color(hex: "#9A9DA3") : Color(hex: "#6F7478") }
    var outlineNormal: Color { scheme == .dark ? Color(hex: "#C8CAD0") : Color(hex: "#6F7478") }
    var outlineMuted: Color { scheme == .dark ? Color(hex: "#8D9096") : Color(hex: "#8A8F94") }
    var outlineActiveText: Color { scheme == .dark ? Color(hex: "#6EA8FF") : Color(hex: "#286BC3") }
    var outlineActiveBg: Color { scheme == .dark ? Color(hex: "#6EA8FF").opacity(0.1) : Color(hex: "#EBF0F4") }
}

struct ContentView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingSearch = false
    @State private var searchText = ""
    @State private var scrollToHeading: String? = nil

    var colors: AppColors { AppColors(scheme: colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(colors.divider)
                .frame(height: 1)
                
            HSplitView {
                // Left File Sidebar
                if !appState.isReadingMode && appState.showFileSidebar && documentManager.workspaceURL != nil {
                    FileSidebarView(nodes: documentManager.fileNodes)
                        .frame(minWidth: 200, idealWidth: 240, maxWidth: 300)
                }
                
                // Main Content
                ZStack {
                    colors.docBg.edgesIgnoringSafeArea(.all)
                    
                    if let content = documentManager.content, let baseURL = documentManager.baseURL, let currentURL = documentManager.currentURL {
                        WebView(
                            htmlContent: content,
                            baseURL: baseURL,
                            searchText: $searchText,
                            isSearching: $showingSearch,
                            scrollToHeading: $scrollToHeading,
                            savedScrollY: documentManager.getScrollPosition(for: currentURL),
                            onHeadingsReceived: { headings in
                                documentManager.tocHeadings = headings
                            },
                            onScroll: { y in
                                documentManager.currentScrollY = y
                            },
                            onActiveHeading: { id in
                                appState.activeHeadingId = id
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
                                .foregroundColor(colors.sidebarPrimary)
                            
                            Text(documentManager.error ?? "Drop a Markdown file or folder here")
                                .foregroundColor(colors.sidebarSecondary)
                                .multilineTextAlignment(.center)
                                
                            HStack(spacing: 20) {
                                Button("Open File...") {
                                    openFilePanel()
                                }
                                Button("Open Folder...") {
                                    openFolderPanel()
                                }
                            }
                            .padding(.top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minWidth: 400, idealWidth: 860, maxWidth: .infinity, minHeight: 300, idealHeight: 600, maxHeight: .infinity)
                
                // Right TOC Sidebar
                if !appState.isReadingMode && appState.showTOCSidebar && documentManager.currentURL != nil {
                    TOCSidebarView(headings: documentManager.tocHeadings, onSelect: { id in
                        scrollToHeading = id
                    })
                    .frame(minWidth: 220, idealWidth: 260, maxWidth: 340)
                }
            }
        }
        .background(colors.appBg)
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
        .onChange(of: documentManager.currentURL) { _ in
            appState.activeHeadingId = nil
        }
    }
    
    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.plainText]
        
        if panel.runModal() == .OK, let url = panel.url {
            documentManager.openFile(at: url)
        }
    }
    
    private func openFolderPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        if panel.runModal() == .OK, let url = panel.url {
            documentManager.openWorkspace(at: url)
            appState.showFileSidebar = true
        }
    }
}

struct FileSidebarView: View {
    let nodes: [FileNode]
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    var colors: AppColors { AppColors(scheme: colorScheme) }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(nodes) { node in
                        FileNodeRow(node: node, level: 0)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
            }
            .background(colors.leftSidebarBg)
            
            Rectangle()
                .fill(colors.divider)
                .frame(height: 1)
                
            HStack {
                Image(systemName: "macwindow")
                    .foregroundColor(colors.sidebarSecondary)
                Text(documentManager.workspaceURL?.lastPathComponent ?? "DigBick")
                    .foregroundColor(colors.sidebarSecondary)
                Spacer()
                Image(systemName: "gearshape")
                    .foregroundColor(colors.sidebarSecondary)
            }
            .font(.caption)
            .padding()
            .background(colors.leftSidebarFooterBg)
        }
        .background(colors.leftSidebarBg)
    }
}

struct FileNodeRow: View {
    @ObservedObject var node: FileNode
    let level: Int
    @EnvironmentObject var documentManager: DocumentManager
    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded: Bool = true
    
    var colors: AppColors { AppColors(scheme: colorScheme) }
    var isSelected: Bool { documentManager.currentURL == node.url }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button(action: {
                if node.isDirectory {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                } else {
                    documentManager.openFile(at: node.url)
                }
            }) {
                HStack(spacing: 6) {
                    Spacer()
                        .frame(width: CGFloat(level * 14))
                    
                    if node.isDirectory {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(colors.sidebarSecondary)
                            .frame(width: 12)
                    } else {
                        Spacer()
                            .frame(width: 12)
                    }
                    
                    Image(systemName: node.isDirectory ? "folder" : "doc.plaintext")
                        .foregroundColor(isSelected ? colors.selectedText : colors.sidebarSecondary)
                        .imageScale(.small)
                        
                    Text(node.url.lastPathComponent)
                        .foregroundColor(isSelected ? colors.selectedText : colors.sidebarPrimary)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .background(isSelected ? colors.selectedRow : Color.clear)
                .cornerRadius(7)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded, let children = node.children, !children.isEmpty {
                ForEach(children) { child in
                    FileNodeRow(node: child, level: level + 1)
                }
            }
        }
    }
}

struct TOCSidebarView: View {
    let headings: [HeadingNode]
    let onSelect: (String) -> Void
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var documentManager: DocumentManager
    @Environment(\.colorScheme) var colorScheme
    var colors: AppColors { AppColors(scheme: colorScheme) }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Outline")
                    .font(.headline)
                    .foregroundColor(colors.sidebarPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                
                if headings.isEmpty {
                    Text("No headings")
                        .foregroundColor(colors.outlineMuted)
                        .padding()
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(headings) { heading in
                                    Button(action: {
                                        onSelect(heading.id)
                                    }) {
                                        HStack(spacing: 0) {
                                            if appState.activeHeadingId == heading.id {
                                                Rectangle()
                                                    .fill(colors.outlineActiveText)
                                                    .frame(width: 2)
                                            } else {
                                                Rectangle()
                                                    .fill(Color.clear)
                                                    .frame(width: 2)
                                            }
                                            
                                            Text(heading.text)
                                                .padding(.leading, CGFloat((heading.level - 1) * 12) + 8)
                                                .lineLimit(1)
                                                .foregroundColor(appState.activeHeadingId == heading.id ? colors.outlineActiveText : colors.outlineNormal)
                                                .fontWeight(appState.activeHeadingId == heading.id ? .semibold : .regular)
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 5)
                                        .background(appState.activeHeadingId == heading.id ? colors.outlineActiveBg : Color.clear)
                                        .cornerRadius(4)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .help(heading.text)
                                    .id(heading.id)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 16)
                        }
                        .background(colors.rightSidebarBg)
                        .onChange(of: appState.activeHeadingId) { newId in
                            if let id = newId {
                                withAnimation {
                                    proxy.scrollTo(id, anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
            .background(colors.rightSidebarBg)
            
            Rectangle()
                .fill(colors.divider)
                .frame(height: 1)
                
            HStack {
                Text("\(documentManager.wordCount) words")
                    .foregroundColor(colors.sidebarSecondary)
                Spacer()
                Text(Date(), style: .time)
                    .foregroundColor(colors.sidebarSecondary)
            }
            .font(.caption)
            .padding()
            .background(colors.rightSidebarBg)
        }
        .background(colors.rightSidebarBg)
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
