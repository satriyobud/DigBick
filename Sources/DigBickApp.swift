import SwiftUI

@main
struct DigBickApp: App {
    @StateObject private var documentManager = DocumentManager()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(documentManager)
                .environmentObject(appState)
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    if let provider = providers.first {
                        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { urlData, error in
                            if let data = urlData as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                                DispatchQueue.main.async {
                                    var isDir: ObjCBool = false
                                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                                        documentManager.openWorkspace(at: url)
                                    } else {
                                        documentManager.openFile(at: url)
                                    }
                                }
                            }
                        }
                        return true
                    }
                    return false
                }
                .onOpenURL { url in
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                        documentManager.openWorkspace(at: url)
                    } else {
                        documentManager.openFile(at: url)
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open…") {
                    documentManager.selectAndOpenFile()
                }
                .keyboardShortcut("o", modifiers: [.command])

                Button("Open Folder…") {
                    documentManager.selectAndOpenWorkspace()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Menu("Open Recent") {
                    let recents = RecentsManager.shared
                    if recents.workspaces.isEmpty && recents.files.isEmpty {
                        Text("No Recent Items")
                            .foregroundColor(.secondary)
                    } else {
                        if !recents.workspaces.isEmpty {
                            Section("Workspaces") {
                                ForEach(recents.workspaces) { entry in
                                    Button(entry.displayName) {
                                        documentManager.openWorkspace(at: entry.url)
                                        appState.showFileSidebar = true
                                    }
                                }
                            }
                        }
                        if !recents.files.isEmpty {
                            Section("Files") {
                                ForEach(recents.files) { entry in
                                    Button(entry.displayName) {
                                        documentManager.openFile(at: entry.url)
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Clear Recents") {
                            RecentsManager.shared.clearAll()
                        }
                    }
                }
            }

            CommandGroup(after: .newItem) {
                Divider()
                Button("Quick Open...") {
                    if appState.showFileSidebar && !appState.isReadingMode {
                        appState.focusSidebarSearch = true
                    } else {
                        appState.isQuickOpenVisible = true
                    }
                }
                .keyboardShortcut("p", modifiers: .command)

                Button("Reload Current File") {
                    documentManager.reload()
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Close File") {
                    documentManager.closeFile()
                }
                .keyboardShortcut("w", modifiers: [.command])
                .disabled(documentManager.currentURL == nil)

                Button("Open in External Editor") {
                    documentManager.openInExternalEditor()
                }
                .keyboardShortcut("e", modifiers: [.command])
                .disabled(documentManager.currentURL == nil)
            }

            CommandMenu("View") {
                Button(appState.showFileSidebar ? "Hide Sidebar" : "Show Sidebar") {
                    appState.showFileSidebar.toggle()
                }
                .keyboardShortcut("b", modifiers: [.command])
                
                Button(appState.showTOCSidebar ? "Hide Table of Contents" : "Show Table of Contents") {
                    appState.showTOCSidebar.toggle()
                }
                .keyboardShortcut("t", modifiers: [.command])
                
                Divider()
                
                Button(appState.isReadingMode ? "Exit Reading Mode" : "Enter Reading Mode") {
                    appState.toggleReadingMode()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
            CommandGroup(after: .appInfo) {
                Button("Support Development") {
                    if let url = URL(string: "https://paypal.me/satriyobud") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
    
}
