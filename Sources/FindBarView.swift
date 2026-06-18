import SwiftUI

struct FindBarColors {
    let scheme: ColorScheme
    
    var panelBg: Color { scheme == .dark ? Color(hex: "#1C1D1F") : Color(hex: "#FAFAF8") }
    var inputBg: Color { scheme == .dark ? Color(hex: "#242528") : Color(hex: "#FFFFFF") }
    var divider: Color { scheme == .dark ? Color(hex: "#34363A") : Color(hex: "#DEDCD8") }
    var primaryText: Color { scheme == .dark ? Color(hex: "#F2F3F5") : Color(hex: "#1F2328") }
    var secondaryText: Color { scheme == .dark ? Color(hex: "#A0A4AA") : Color(hex: "#6F7478") }
    var iconColor: Color { scheme == .dark ? Color(hex: "#A0A4AA") : Color(hex: "#6F7478") }
}

struct FindBarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool
    
    var onFind: (String) -> Void
    var onNext: () -> Void
    var onPrev: () -> Void
    var onClose: () -> Void
    
    var colors: FindBarColors { FindBarColors(scheme: colorScheme) }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(colors.iconColor)
            
            TextField("Find in document...", text: $appState.findQuery, onCommit: {
                onNext()
            })
            .textFieldStyle(PlainTextFieldStyle())
            .focused($isFocused)
            .disableAutocorrection(true)
            .foregroundColor(colors.primaryText)
            .onChange(of: appState.findQuery) { newValue in
                onFind(newValue)
            }
            .frame(width: 150)
            
            if !appState.findQuery.isEmpty {
                Text(appState.findMatchCount > 0 ? "\(appState.findCurrentIndex) / \(appState.findMatchCount)" : "No results")
                    .foregroundColor(appState.findMatchCount > 0 ? colors.secondaryText : .red)
                    .font(.system(size: 12))
                    .padding(.horizontal, 4)
            }
            
            Divider()
                .background(colors.divider)
                .frame(height: 16)
            
            Button(action: onPrev) {
                Image(systemName: "chevron.up")
                    .foregroundColor(appState.findMatchCount == 0 ? colors.divider : colors.iconColor)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(appState.findMatchCount == 0)
            
            Button(action: onNext) {
                Image(systemName: "chevron.down")
                    .foregroundColor(appState.findMatchCount == 0 ? colors.divider : colors.iconColor)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(appState.findMatchCount == 0)
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundColor(colors.iconColor)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.leading, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(colors.panelBg)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(colors.divider, lineWidth: 1)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .background(
            FindBarKeyMonitor(onEscape: onClose)
        )
    }
}

struct FindBarKeyMonitor: NSViewRepresentable {
    var onEscape: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = FindBarKeyView()
        view.onEscape = onEscape
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class FindBarKeyView: NSView {
    var onEscape: (() -> Void)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self = self else { return event }
                if event.keyCode == 53 { // Escape
                    self.onEscape?()
                    return nil
                }
                return event
            }
        } else if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
