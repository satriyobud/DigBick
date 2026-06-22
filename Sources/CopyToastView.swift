import SwiftUI

struct CopyToastView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        // Add a subtle border for better contrast on varying backgrounds
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .padding(.bottom, 24)
    }
}
