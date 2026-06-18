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
                                        appState.showFileSidebar = true
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
                        appState.showFileSidebar = true
                    } else {
                        documentManager.openFile(at: url)
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    openFilePanel()
                }
                .keyboardShortcut("o", modifiers: [.command])
                
                Button("Open Folder...") {
                    openFolderPanel()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
            CommandGroup(after: .newItem) {
                Button("Reload Current File") {
                    documentManager.reload()
                }
                .keyboardShortcut("r", modifiers: [.command])
                
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
    
    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.plainText] // UTTypes for md, txt, markdown
        
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
