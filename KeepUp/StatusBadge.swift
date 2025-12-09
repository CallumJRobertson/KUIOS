import SwiftUI

struct StatusBadge: View {
    let status: String
    
    var badgeColor: Color {
        switch status.lowercased() {
        case "renewed", "confirmed", "filming", "released", "in production": return .green
        case "cancelled", "ended": return .red
        case "ending": return .orange
        case "unknown": return .gray
        default: return .blue
        }
    }
    
    var body: some View {
        Text(status.uppercased())
            .font(.caption2)
            .fontWeight(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.2))
            .foregroundColor(badgeColor)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(badgeColor, lineWidth: 1).opacity(0.3)
            )
    }
}
