import SwiftUI

struct QuickOpenColors {
    let scheme: ColorScheme
    
    var panelBg: Color { scheme == .dark ? Color(hex: "#1C1D1F") : Color(hex: "#FAFAF8") }
    var inputBg: Color { scheme == .dark ? Color(hex: "#242528") : Color(hex: "#FFFFFF") }
    var resultHoverBg: Color { scheme == .dark ? Color(hex: "#303236") : Color(hex: "#ECE9E3") }
    var divider: Color { scheme == .dark ? Color(hex: "#34363A") : Color(hex: "#DEDCD8") }
    var primaryText: Color { scheme == .dark ? Color(hex: "#F2F3F5") : Color(hex: "#1F2328") }
    var secondaryText: Color { scheme == .dark ? Color(hex: "#A0A4AA") : Color(hex: "#6F7478") }
    var placeholderText: Color { scheme == .dark ? Color(hex: "#7D828A") : Color(hex: "#8A8F94") }
    var iconColor: Color { scheme == .dark ? Color(hex: "#A0A4AA") : Color(hex: "#6F7478") }
    var backdrop: Color { scheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.08) }
}

struct QuickOpenView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    @Binding var isPresented: Bool

    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var isSearchFocused: Bool

    var colors: QuickOpenColors { QuickOpenColors(scheme: colorScheme) }

    // Inline computed — re-runs every time `query` changes because @State triggers body re-evaluation
    private var displayResults: [URL] {
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

    var body: some View {
        ZStack {
            colors.backdrop
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {

                // Search input
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(colors.iconColor)

                    ZStack(alignment: .leading) {
                        if query.isEmpty {
                            Text("Search files by name or path...")
                                .foregroundColor(colors.placeholderText)
                                .font(.system(size: 16))
                                .allowsHitTesting(false)
                        }
                        TextField("", text: $query)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 16))
                            .foregroundColor(colors.primaryText)
                            .focused($isSearchFocused)
                            .disableAutocorrection(true)
                            .onChange(of: query) { _ in
                                selectedIndex = 0
                            }
                    }

                    if !query.isEmpty {
                        Button(action: {
                            query = ""
                            isSearchFocused = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(colors.iconColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(colors.inputBg)
                .cornerRadius(10)
                .padding(10)

                Divider().background(colors.divider)


                // Results
                if documentManager.workspaceURL == nil {
                    VStack(spacing: 12) {
                        Text("Open a folder first.")
                            .foregroundColor(colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if displayResults.isEmpty && !query.isEmpty {
                    Text("No matching files.")
                        .foregroundColor(colors.secondaryText)
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                ForEach(Array(displayResults.enumerated()), id: \.element) { index, url in
                                    resultRow(url: url, index: index)
                                        .id(url)
                                        .onTapGesture { openFile(at: url) }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                        }
                        .onChange(of: selectedIndex) { idx in
                            guard idx < displayResults.count else { return }
                            withAnimation { proxy.scrollTo(displayResults[idx], anchor: .center) }
                        }
                    }
                }
            }
            .frame(width: 560, height: 440)
            .background(colors.panelBg)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(colors.divider, lineWidth: 1))
            .onAppear {
                query = ""
                selectedIndex = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isSearchFocused = true
                }
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
    }

    @ViewBuilder
    private func resultRow(url: URL, index: Int) -> some View {
        let selected = index == selectedIndex
        let rel = documentManager.flatMarkdownEntries.first(where: { $0.url == url })?.relativePath ?? url.lastPathComponent

        HStack(spacing: 12) {
            Image(systemName: "doc.plaintext")
                .foregroundColor(colors.iconColor)
                .font(.system(size: 15))
            VStack(alignment: .leading, spacing: 3) {
                Text(url.lastPathComponent)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(colors.primaryText)
                Text(rel)
                    .font(.system(size: 12))
                    .foregroundColor(colors.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 54)
        .background(selected ? colors.resultHoverBg : Color.clear)
        .cornerRadius(9)
        .contentShape(Rectangle())
    }

    private func move(_ offset: Int) {
        guard !displayResults.isEmpty else { return }
        var next = selectedIndex + offset
        if next < 0 { next = displayResults.count - 1 }
        else if next >= displayResults.count { next = 0 }
        selectedIndex = next
    }

    private func openSelected() {
        guard !displayResults.isEmpty, selectedIndex < displayResults.count else { return }
        openFile(at: displayResults[selectedIndex])
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
