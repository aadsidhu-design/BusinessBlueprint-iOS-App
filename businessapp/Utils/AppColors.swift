import SwiftUI

struct AppColors {
    // Primary Colors - Subtle and refined
    static let primary = Color(red: 0.0, green: 0.48, blue: 1.0) // Apple Blue
    static let secondary = Color(red: 0.35, green: 0.34, blue: 0.84) // Indigo
    static let accent = Color(red: 0.5, green: 0.0, blue: 1.0) // Purple
    
    // Legacy Colors (minimal use)
    static let primaryOrange = Color.orange
    static let primaryCoral = Color.orange
    static let primaryPink = Color.pink
    static let duolingoGreen = Color.green
    static let successGreen = Color.green
    static let brightBlue = Color.blue
    
    // Semantic Colors - System aligned
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    
    // Neutral Colors - Use system colors for perfect adaptation
    static let background = Color(uiColor: .systemBackground)
    static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let surfaceLight = Color(uiColor: .tertiarySystemBackground)
    
    static let border = Color(uiColor: .separator)
    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)
    
    // Glass effect colors
    static let glassFill = Color.white.opacity(0.1)
    static let glassFillLight = Color.white.opacity(0.05)
    static let glassStroke = Color.white.opacity(0.2)
    
    // Minimal gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, primary.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let secondaryGradient = LinearGradient(
        colors: [secondary, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [accent, accent.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [success, success.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let blueGradient = primaryGradient
    static let backgroundGradient = LinearGradient(
        colors: [background, background],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let vibrantGradient = secondaryGradient
    
    // Card Colors
    static let cardBackground = surface
    static let cardShadow = Color.black.opacity(0.05)
    static let cardBorder = border
}

