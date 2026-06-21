import SwiftUI

// MARK: - Palette

struct QuickOpenColors {
    let scheme: ColorScheme

    var panelBg: Color     { scheme == .dark ? Color(hex: "#1C1D1F") : Color(hex: "#FAFAF8") }
    var inputBg: Color     { scheme == .dark ? Color(hex: "#242528") : Color(hex: "#FFFFFF") }
    var inputBorder: Color { scheme == .dark ? Color(hex: "#3A3C40") : Color(hex: "#E7E3DC") }
    var panelBorder: Color { scheme == .dark ? Color(hex: "#34363A") : Color(hex: "#DEDCD8") }
    var divider: Color     { scheme == .dark ? Color(hex: "#2E3033") : Color(hex: "#E7E3DC") }
    var selectedBg: Color  { scheme == .dark ? Color(hex: "#303236") : Color(hex: "#ECE9E3") }
    var primary: Color     { scheme == .dark ? Color(hex: "#F2F3F5") : Color(hex: "#1F2328") }
    var secondary: Color   { scheme == .dark ? Color(hex: "#A0A4AA") : Color(hex: "#6F7478") }
    var placeholder: Color { scheme == .dark ? Color(hex: "#7D828A") : Color(hex: "#8A8F94") }
    var icon: Color        { scheme == .dark ? Color(hex: "#888E96") : Color(hex: "#7A7F85") }
    var footer: Color      { scheme == .dark ? Color(hex: "#777D84") : Color(hex: "#7A7F85") }
    var keycapBg: Color    { scheme == .dark ? Color(hex: "#2E3033") : Color(hex: "#F1EFEB") }
    var keycapBorder: Color { scheme == .dark ? Color(hex: "#44474C") : Color(hex: "#D8D4CC") }
    var backdrop: Color    { scheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.07) }
    var shadow: Color      { Color.black.opacity(scheme == .dark ? 0.45 : 0.13) }
}

// MARK: - Helper

private func strippedName(_ url: URL) -> String {
    let name = url.lastPathComponent
    let mdExts: Set<String> = ["md", "markdown", "mdown"]
    guard mdExts.contains(url.pathExtension.lowercased()) else { return name }
    return String(name.dropLast(url.pathExtension.count + 1))
}

// MARK: - View

struct QuickOpenView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    @Binding var isPresented: Bool

    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var isFocused: Bool

    var c: QuickOpenColors { QuickOpenColors(scheme: colorScheme) }
    @ObservedObject private var recents = RecentsManager.shared

    // MARK: Filter

    private var results: [URL] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        let all = documentManager.flatMarkdownFiles
        guard !q.isEmpty else { return all }

        if q.contains("/") {
            return documentManager.flatMarkdownEntries
                .filter { $0.relativePath.lowercased().contains(q) }
                .map { $0.url }
        } else {
            return all
                .filter { $0.lastPathComponent.lowercased().contains(q) }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
        }
    }

    /// Combined recent URLs (workspace then file) for the empty-query header.
    private var recentURLs: [URL] {
        let ws = recents.workspaces.map { $0.url }
        let fi = recents.files.map { $0.url }
        // Merge, deduplicate, cap at 5
        var seen = Set<URL>()
        return (ws + fi).filter { seen.insert($0).inserted }.prefix(5).map { $0 }
    }

    // MARK: Body

    var body: some View {
        GeometryReader { geo in
            let winW = geo.size.width
            let winH = geo.size.height

            // Responsive dimensions
            let panelW     = min(680, max(560, winW * 0.38))
            let panelMaxH  = min(540, max(420, winH * 0.62))
            let topInset   = max(100, winH * 0.18)

            ZStack(alignment: .top) {
                // ── Backdrop ──────────────────────────────────
                c.backdrop
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { dismiss() }

                // ── Panel ─────────────────────────────────────
                VStack(spacing: 0) {
                    Spacer().frame(height: topInset)

                    panel(width: panelW, maxHeight: panelMaxH)

                    Spacer()
                }
            }
            .frame(width: winW, height: winH)
        }
        .onAppear {
            query = ""
            selectedIndex = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { isFocused = true }
        }
        .background(
            QuickOpenKeyMonitor(
                onUp: { move(-1) },
                onDown: { move(1) },
                onEnter: { openSelected() },
                onEscape: { dismiss() }
            )
        )
    }

    // MARK: - Panel Shell

    @ViewBuilder
    private func panel(width: CGFloat, maxHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            inputBar

            Rectangle()
                .fill(c.divider)
                .frame(height: 1)

            resultList
                .frame(maxHeight: .infinity)

            Rectangle()
                .fill(c.divider)
                .frame(height: 1)

            footerBar
        }
        .frame(width: width)
        .frame(maxHeight: maxHeight)
        .background(c.panelBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(c.panelBorder, lineWidth: 1)
        )
        .shadow(color: c.shadow, radius: 48, x: 0, y: 22)
        // Center horizontally
        .frame(maxWidth: .infinity)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(c.icon)

            ZStack(alignment: .leading) {
                if query.isEmpty {
                    Text("Search files by name or path…")
                        .font(.system(size: 14))
                        .foregroundColor(c.placeholder)
                        .allowsHitTesting(false)
                }
                TextField("", text: $query)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 14))
                    .foregroundColor(c.primary)
                    .focused($isFocused)
                    .disableAutocorrection(true)
                    .onChange(of: query) { _ in selectedIndex = 0 }
            }

            if !query.isEmpty {
                Button(action: { query = ""; isFocused = true }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(c.icon.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(c.inputBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(c.inputBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    // MARK: - Result List

    @ViewBuilder
    private var resultList: some View {
        if documentManager.workspaceURL == nil && results.isEmpty && query.isEmpty {
            // No workspace, no recents — show welcome prompt
            emptyState(icon: "folder.badge.questionmark",
                       text: "Open a workspace folder to search files.")
        } else if results.isEmpty && !query.isEmpty {
            emptyState(icon: "doc.text.magnifyingglass",
                       text: "No files matching \"\(query)\"")
        } else {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 2, pinnedViews: []) {
                        // ── Recents header (empty query only) ──────────
                        if query.isEmpty && !recentURLs.isEmpty {
                            sectionHeader("Recent")
                            ForEach(Array(recentURLs.enumerated()), id: \.element) { index, url in
                                recentRow(url: url, index: index)
                                    .id("recent-\(url)")
                                    .onTapGesture { openRecent(url: url) }
                            }
                            sectionHeader("All Files")
                        }

                        // ── Main results ────────────────────────────────
                        let offset = (query.isEmpty && !recentURLs.isEmpty) ? recentURLs.count : 0
                        ForEach(Array(results.enumerated()), id: \.element) { index, url in
                            row(url: url, index: index + offset)
                                .id(url)
                                .onTapGesture { openFile(at: url) }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .onChange(of: selectedIndex) { idx in
                    guard idx < results.count else { return }
                    withAnimation(.easeInOut(duration: 0.12)) {
                        proxy.scrollTo(results[idx], anchor: .center)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ label: String) -> some View {
        Text(label.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(c.secondary.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func recentRow(url: URL, index: Int) -> some View {
        let isWorkspace = recents.workspaces.contains(where: { $0.url == url })
        let name = isWorkspace ? url.lastPathComponent : strippedName(url)
        let sub  = isWorkspace ? url.path : (recents.files.first(where: { $0.url == url })?.path ?? url.path)

        HStack(spacing: 10) {
            Image(systemName: isWorkspace ? "folder" : "doc.text")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(c.icon)
                .frame(width: 18, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(c.primary)
                    .lineLimit(1)

                Text(sub)
                    .font(.system(size: 11))
                    .foregroundColor(c.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 0)

            Text(isWorkspace ? "workspace" : "file")
                .font(.system(size: 10))
                .foregroundColor(c.secondary.opacity(0.6))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(c.keycapBg)
                )
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
        .help(sub)
    }

    private func openRecent(url: URL) {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            documentManager.openWorkspace(at: url)
            appState.showFileSidebar = true
        } else {
            documentManager.openFile(at: url)
        }
        dismiss()
    }

    // MARK: - Row

    @ViewBuilder
    private func row(url: URL, index: Int) -> some View {
        let selected = index == selectedIndex
        let name = strippedName(url)
        let rel  = documentManager.flatMarkdownEntries
            .first(where: { $0.url == url })?.relativePath ?? url.lastPathComponent

        HStack(spacing: 10) {
            Image(systemName: "doc.text")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(c.icon)
                .frame(width: 18, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(c.primary)
                    .lineLimit(1)

                Text(rel)
                    .font(.system(size: 11))
                    .foregroundColor(c.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(selected ? c.selectedBg : Color.clear)
        )
        .contentShape(Rectangle())
        .help(rel)
    }

    // MARK: - Empty State

    @ViewBuilder
    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .light))
                .foregroundColor(c.icon.opacity(0.5))
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(c.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack {
            Spacer()
            HStack(spacing: 14) {
                keyhint(keys: ["↑", "↓"], label: "Navigate")
                keyhint(keys: ["↵"], label: "Open")
                keyhint(keys: ["esc"], label: "Close")
            }
            .padding(.trailing, 14)
        }
        .frame(height: 36)
        .background(c.panelBg)
    }

    @ViewBuilder
    private func keyhint(keys: [String], label: String) -> some View {
        HStack(spacing: 4) {
            HStack(spacing: 3) {
                ForEach(keys, id: \.self) { k in
                    Text(k)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(c.footer)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(c.keycapBg)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .stroke(c.keycapBorder, lineWidth: 1)
                                )
                        )
                }
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(c.footer)
        }
    }

    // MARK: - Actions

    private func move(_ offset: Int) {
        guard !results.isEmpty else { return }
        var next = selectedIndex + offset
        if next < 0 { next = results.count - 1 }
        else if next >= results.count { next = 0 }
        selectedIndex = next
    }

    private func openSelected() {
        guard !results.isEmpty, selectedIndex < results.count else { return }
        openFile(at: results[selectedIndex])
    }

    private func openFile(at url: URL) {
        documentManager.openFile(at: url)
        dismiss()
    }

    private func dismiss() {
        query = ""
        isPresented = false
    }
}

// MARK: - Key Monitor

struct QuickOpenKeyMonitor: NSViewRepresentable {
    var onUp: () -> Void
    var onDown: () -> Void
    var onEnter: () -> Void
    var onEscape: () -> Void

    func makeNSView(context: Context) -> NSView {
        let v = QuickOpenKeyView()
        v.onUp = onUp; v.onDown = onDown; v.onEnter = onEnter; v.onEscape = onEscape
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let v = nsView as? QuickOpenKeyView else { return }
        v.onUp = onUp; v.onDown = onDown; v.onEnter = onEnter; v.onEscape = onEscape
    }
}

class QuickOpenKeyView: NSView {
    var onUp: (() -> Void)?
    var onDown: (() -> Void)?
    var onEnter: (() -> Void)?
    var onEscape: (() -> Void)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil, monitor == nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self = self else { return event }
                switch event.keyCode {
                case 125: self.onDown?(); return nil
                case 126: self.onUp?(); return nil
                case 36:  self.onEnter?(); return nil
                case 53:  self.onEscape?(); return nil
                default:  return event
                }
            }
        } else if window == nil, let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }
}
