import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var recents = RecentsManager.shared

    var colors: AppColors { AppColors(scheme: colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo + name
            VStack(spacing: 10) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 64, height: 64)
                    .cornerRadius(14)

                Text("DigBick")
                    .font(.system(size: 26, weight: .semibold, design: .default))
                    .foregroundColor(colors.sidebarPrimary)

                Text("A fast, beautiful Markdown viewer for macOS")
                    .font(.system(size: 13))
                    .foregroundColor(colors.sidebarSecondary)
            }

            Spacer().frame(height: 40)

            // Recents columns (only if any exist)
            if !recents.workspaces.isEmpty || !recents.files.isEmpty {
                HStack(alignment: .top, spacing: 40) {
                    if !recents.workspaces.isEmpty {
                        recentSection(
                            title: "Recent Workspaces",
                            icon: "folder",
                            entries: recents.workspaces,
                            action: { entry in
                                documentManager.openWorkspace(at: entry.url)
                                appState.showFileSidebar = true
                            }
                        )
                    }

                    if !recents.files.isEmpty {
                        recentSection(
                            title: "Recent Files",
                            icon: "doc.text",
                            entries: recents.files,
                            action: { entry in
                                documentManager.openFile(at: entry.url)
                            }
                        )
                    }
                }
                .padding(.horizontal, 48)

                Spacer().frame(height: 32)
            }

            // Action buttons
            HStack(spacing: 12) {
                welcomeButton(label: "Open File…", icon: "doc.text") {
                    openFilePanel()
                }
                welcomeButton(label: "Open Folder…", icon: "folder") {
                    openFolderPanel()
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.docBg)
    }

    // MARK: - Recent Section

    @ViewBuilder
    private func recentSection(
        title: String,
        icon: String,
        entries: [RecentEntry],
        action: @escaping (RecentEntry) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(colors.sidebarSecondary)
                .padding(.bottom, 2)

            ForEach(entries.prefix(6)) { entry in
                Button(action: { action(entry) }) {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 12))
                            .foregroundColor(colors.sidebarSecondary)
                            .frame(width: 16)

                        Text(entry.displayName)
                            .font(.system(size: 13))
                            .foregroundColor(colors.sidebarPrimary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(WelcomeRowButtonStyle(colors: colors))
                .help(entry.path)
            }
        }
        .frame(minWidth: 200, maxWidth: 260, alignment: .leading)
    }

    // MARK: - Action Button

    @ViewBuilder
    private func welcomeButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(colorScheme == .dark ? Color(hex: "#2A2C30") : Color(hex: "#EDEDEB"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(colorScheme == .dark ? Color(hex: "#3A3C40") : Color(hex: "#D8D4CC"), lineWidth: 1)
                    )
            )
            .foregroundColor(colors.sidebarPrimary)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Panels

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

// MARK: - Row Button Style

struct WelcomeRowButtonStyle: ButtonStyle {
    let colors: AppColors
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(configuration.isPressed ? colors.selectedRow : Color.clear)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
