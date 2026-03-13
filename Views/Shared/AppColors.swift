import SwiftUI

// MARK: - Dusty Rose Palette
extension Color {
    static let petal        = Color(hex: "#FDF6F4") // Background
    static let blushLight   = Color(hex: "#F5E8E4") // Surface
    static let blush        = Color(hex: "#EDD8D2") // Card
    static let burgundy     = Color(hex: "#A0404A") // Accent
    static let rose         = Color(hex: "#C87A80") // Accent Light
    static let deepWine     = Color(hex: "#2A1418") // Primary text
    static let mauve        = Color(hex: "#8A6060") // Secondary text
    static let blushBorder  = Color(hex: "#E8D4D0") // Border/Divider

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, (int >> 8) & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: 1)
    }
}
