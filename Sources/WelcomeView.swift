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
    @Environment(\.colorScheme) var colorScheme

    var colors: AppColors { AppColors(scheme: colorScheme) }

    // Pick once per view lifetime
    @State private var joke: String = jokes.randomElement()!

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

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
