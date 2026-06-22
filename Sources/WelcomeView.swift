import SwiftUI

private let jokes: [String] = [
    "Why did the Markdown file go to therapy?\nIt had too many *issues*.",
    "I have a joke about Markdown.\nBut it's not **bold** enough.",
    "To understand recursion,\nyou must first understand recursion.",
    "My code never has bugs.\nIt just has unexpected features.",
    "Why do programmers prefer dark mode?\nBecause light attracts bugs.",
    "I fixed a bug in my code.\nNow I have two bugs.",
    "A SQL query walks into a bar\nand asks two tables: 'Can I join you?'",
    "Why did the developer quit?\nHe didn't get arrays.",
    "How many programmers does it take\nto change a light bulb?\nNone — that's a hardware problem.",
    "Why do Markdown files never get lonely?\nThey always have *emphasis*.",
    "I asked my code to fix itself.\nIt returned `undefined`.",
    "Oct 31 == Dec 25.\nProgrammers never get Halloween wrong.",
    "There are 10 types of people in the world:\nthose who understand binary, and those who don't.",
    "A byte walks into a bar, limping.\nBartender: 'What happened?'\nByte: 'I got a bit flipped.'",
    "Why was the JavaScript developer sad?\nHe didn't Node how to Express himself.",
    "What's a programmer's favorite hangout spot?\nThe foo bar.",
    "Git push origin main.\nThe last words of many relationships.",
    "// TODO: write a better joke",
]

struct WelcomeView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var recentsManager = RecentsManager.shared

    var colors: AppColors { AppColors(scheme: colorScheme) }

    // Pick once per view lifetime
    @State private var joke: String = jokes.randomElement()!

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 14) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 56, height: 56)
                    .cornerRadius(12)

                Text("DigBick")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(colors.sidebarPrimary)

                Text(joke)
                    .font(.system(size: 13))
                    .foregroundColor(colors.sidebarSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 48)
                    .padding(.top, 4)
                
                HStack(spacing: 12) {
                    Button("Open Folder") {
                        documentManager.selectAndOpenWorkspace()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    if !recentsManager.workspaces.isEmpty {
                        Menu("Open Recent") {
                            ForEach(recentsManager.workspaces.prefix(10)) { entry in
                                Button(entry.displayName) {
                                    documentManager.openRecentWorkspace(entry.url)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                .padding(.top, 8)
                
                if !recentsManager.workspaces.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text("Recent")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(colors.sidebarSecondary)
                            .padding(.leading, 2)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recentsManager.workspaces.prefix(5)) { entry in
                                Button(action: {
                                    documentManager.openRecentWorkspace(entry.url)
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "folder")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color.blue.opacity(0.8))
                                            .frame(width: 20)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(entry.displayName)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(colors.sidebarPrimary)
                                            Text(entry.path)
                                                .font(.system(size: 11))
                                                .foregroundColor(colors.sidebarSecondary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .frame(width: 360)
                }
            }
            
            Spacer()
            
            Text("Drop a file or folder here, or press ⌘O")
                .font(.system(size: 11))
                .foregroundColor(colors.sidebarSecondary.opacity(0.5))
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.docBg)
    }
}
