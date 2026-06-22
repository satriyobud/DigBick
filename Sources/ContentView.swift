import SwiftUI
import AppKit

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
    
    @State private var scrollToHeading: String? = nil
    @State private var dragStartWidth: CGFloat = 280
    @State private var isFirstScanAfterWorkspaceOpen: Bool = false

    var colors: AppColors { AppColors(scheme: colorScheme) }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(colors.divider)
                    .frame(height: 1)
                    
                HStack(spacing: 0) {
                    // Left File Sidebar
                    if !appState.isReadingMode && appState.showFileSidebar && documentManager.workspaceURL != nil {
                        FileSidebarView(nodes: documentManager.fileNodes)
                            .frame(width: appState.sidebarWidth)
                        
                        // Draggable Divider
                        Rectangle()
                            .fill(colors.divider)
                            .frame(width: 1)
                            .overlay(
                                Color.clear
                                    .frame(width: 8)
                                    .contentShape(Rectangle())
                            )
                            .onHover { isHovered in
                                if isHovered {
                                    NSCursor.resizeLeftRight.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        if gesture.translation == .zero {
                                            dragStartWidth = appState.sidebarWidth
                                        }
                                        let newWidth = dragStartWidth + gesture.translation.width
                                        appState.sidebarWidth = Swift.max(220, Swift.min(480, newWidth))
                                        appState.hasUserResizedSidebar = true
                                    }
                            )
                    }
                    
                    // Main Content
                    ZStack(alignment: .topTrailing) {
                        colors.docBg.edgesIgnoringSafeArea(.all)
                        
                        if let content = documentManager.content, let baseURL = documentManager.baseURL, let currentURL = documentManager.currentURL {
                            WebView(
                                htmlContent: content,
                                baseURL: baseURL,
                                searchText: $appState.findQuery,
                                isSearching: $appState.isFindBarVisible,
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
                                },
                                onFindResults: { total, current in
                                    appState.findMatchCount = total
                                    appState.findCurrentIndex = current
                                }
                            )
                            .edgesIgnoringSafeArea(.all)
                            
                            if appState.isFindBarVisible {
                                FindBarView(
                                    onFind: { _ in
                                        // The WebView already observes $appState.findQuery
                                    },
                                    onNext: {
                                        NotificationCenter.default.post(name: NSNotification.Name("DigBickFindNext"), object: nil)
                                    },
                                    onPrev: {
                                        NotificationCenter.default.post(name: NSNotification.Name("DigBickFindPrev"), object: nil)
                                    },
                                    onClose: {
                                        appState.isFindBarVisible = false
                                        appState.findQuery = ""
                                    }
                                )
                                .padding(.top, 10)
                                .padding(.trailing, 20)
                            }
                        } else if let errMsg = documentManager.error {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 28))
                                    .foregroundColor(colors.sidebarSecondary)
                                Text(errMsg)
                                    .foregroundColor(colors.sidebarSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if documentManager.workspaceURL == nil && documentManager.currentURL == nil {
                            WelcomeView()
                        } else {
                            Color.clear
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Right TOC Sidebar
                    if !appState.isReadingMode && appState.showTOCSidebar && documentManager.currentURL != nil {
                        Rectangle()
                            .fill(colors.divider)
                            .frame(width: 1)
                        
                        TOCSidebarView(headings: documentManager.tocHeadings, onSelect: { id in
                            scrollToHeading = id
                        })
                        .frame(width: 260)
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
                    Menu {
                        Button("Copy all as Text") {
                            NotificationCenter.default.post(name: NSNotification.Name("DigBickCopyAllText"), object: nil)
                        }
                        Button("Copy all as Markdown") {
                            if let raw = documentManager.rawMarkdown {
                                let pb = NSPasteboard.general
                                pb.clearContents()
                                pb.setString(raw, forType: .string)
                                appState.copyToast = "Copied as Markdown"
                            }
                        }
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .disabled(documentManager.currentURL == nil)
                    .help("Copy document")
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { appState.showTOCSidebar.toggle() }) {
                        Image(systemName: "list.bullet.indent")
                    }
                    .help("Toggle Table of Contents")
                }
            }
            .onChange(of: documentManager.currentURL) { _ in
                appState.activeHeadingId = nil
                appState.isFindBarVisible = false
                appState.findQuery = ""
                appState.findMatchCount = 0
                appState.findCurrentIndex = 0
            }
            
            if appState.isQuickOpenVisible {
                QuickOpenView(isPresented: $appState.isQuickOpenVisible)
            }
            
            // Invisible keyboard shortcut hooks for reliability
            Button("") { appState.isQuickOpenVisible = true }
                .keyboardShortcut("p", modifiers: .command)
                .opacity(0)
            
            Button("") { appState.isFindBarVisible = true }
                .keyboardShortcut("f", modifiers: .command)
                .opacity(0)
                
            Button("") {
                if appState.isFindBarVisible {
                    NotificationCenter.default.post(name: NSNotification.Name("DigBickFindNext"), object: nil)
                }
            }
            .keyboardShortcut("g", modifiers: .command)
            .opacity(0)
            
            Button("") {
                if appState.isFindBarVisible {
                    NotificationCenter.default.post(name: NSNotification.Name("DigBickFindPrev"), object: nil)
                }
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
            .opacity(0)
            
            // Toast Notification Overlay
            if let msg = appState.copyToast {
                VStack {
                    Spacer()
                    CopyToastView(message: msg)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                .edgesIgnoringSafeArea(.bottom)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            if appState.copyToast == msg {
                                appState.copyToast = nil
                            }
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DigBickShowToast"))) { notif in
            if let msg = notif.object as? String {
                withAnimation {
                    appState.copyToast = msg
                }
            }
        }
        .onChange(of: documentManager.workspaceURL) { newURL in
            if newURL != nil {
                appState.showFileSidebar = true
                isFirstScanAfterWorkspaceOpen = true
            }
        }
        .onChange(of: documentManager.flatMarkdownFiles) { newFiles in
            if isFirstScanAfterWorkspaceOpen && !newFiles.isEmpty {
                isFirstScanAfterWorkspaceOpen = false
                if !appState.hasUserResizedSidebar {
                    performAutoFit()
                }
            }
        }
    }

    private func getVisibleNodesAndLevels(nodes: [FileNode], level: Int, expandedFolders: Set<URL>) -> [(node: FileNode, level: Int)] {
        var result: [(node: FileNode, level: Int)] = []
        for node in nodes {
            result.append((node, level))
            if node.isDirectory && expandedFolders.contains(node.url) {
                if let children = node.children {
                    result.append(contentsOf: getVisibleNodesAndLevels(nodes: children, level: level + 1, expandedFolders: expandedFolders))
                }
            }
        }
        return result
    }

    private func estimateTextWidth(text: String, isSelected: Bool) -> CGFloat {
        let font = isSelected ? NSFont.systemFont(ofSize: 13, weight: .semibold) : NSFont.systemFont(ofSize: 13)
        let attributes = [NSAttributedString.Key.font: font]
        return (text as NSString).size(withAttributes: attributes).width
    }

    private func performAutoFit() {
        let visibleNodes = getVisibleNodesAndLevels(nodes: documentManager.fileNodes, level: 0, expandedFolders: documentManager.expandedFolders)
        var maxRowWidth: CGFloat = 220
        for (node, level) in visibleNodes {
            let isSelected = node.url == documentManager.currentURL
            let textWidth = estimateTextWidth(text: node.url.lastPathComponent, isSelected: isSelected)
            let rowWidth = 98 + CGFloat(level * 14) + textWidth
            if rowWidth > maxRowWidth {
                maxRowWidth = rowWidth
            }
        }
        
        appState.sidebarWidth = Swift.max(220, Swift.min(380, maxRowWidth))
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
            // Header with Quick Open button
            HStack {
                Text("Explorer")
                    .font(.headline)
                    .foregroundColor(colors.sidebarPrimary)
                Spacer()
                Button(action: { appState.isQuickOpenVisible = true }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(colors.sidebarSecondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Quick Open (Cmd+P)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(colors.leftSidebarBg)
            
            Divider().background(colors.divider)
            
            ScrollView(showsIndicators: true) {
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
    
    var colors: AppColors { AppColors(scheme: colorScheme) }
    var isSelected: Bool { documentManager.currentURL == node.url }
    var isExpanded: Bool { documentManager.expandedFolders.contains(node.url) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button(action: {
                if node.isDirectory {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if isExpanded {
                            documentManager.expandedFolders.remove(node.url)
                        } else {
                            documentManager.expandedFolders.insert(node.url)
                        }
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
                        .help(node.url.lastPathComponent)
                    
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

// Visual Effect for overlays
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
