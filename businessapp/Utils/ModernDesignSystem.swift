import SwiftUI
import UIKit

// MARK: - Modern Design System
// Inspired by Apple's Human Interface Guidelines, Linear, Notion, and modern SaaS apps

struct ModernDesign {
    
    // MARK: - Typography Scale
    struct Typography {
        // Display - For hero sections and key headlines
        static let displayLarge = Font.system(size: 32, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
        
        // Headlines - For section headers and important content
        static let headline1 = Font.system(size: 24, weight: .bold, design: .default)
        static let headline2 = Font.system(size: 20, weight: .semibold, design: .default)
        static let headline3 = Font.system(size: 18, weight: .semibold, design: .default)
        
        // Body - For main content and descriptions
        static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
        
        // Labels - For buttons, tags, and metadata
        static let labelLarge = Font.system(size: 15, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
        
        // Caption - For timestamps, helper text
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
    }
    
    // MARK: - Color Palette
    struct Colors {
        // Primary Brand Colors
        static let primary = Color(hex: "6366F1") // Modern purple-blue
        static let primaryLight = Color(hex: "818CF8")
        static let primaryDark = Color(hex: "4F46E5")
        
        // Accent Colors
        static let accent = Color(hex: "F59E0B") // Warm amber
        static let success = Color(hex: "10B981") // Modern green
        static let warning = Color(hex: "F59E0B") // Amber
        static let error = Color(hex: "EF4444") // Modern red
        
        // Neutral Grays
        static let gray50 = Color(hex: "F9FAFB")
        static let gray100 = Color(hex: "F3F4F6")
        static let gray200 = Color(hex: "E5E7EB")
        static let gray300 = Color(hex: "D1D5DB")
        static let gray400 = Color(hex: "9CA3AF")
        static let gray500 = Color(hex: "6B7280")
        static let gray600 = Color(hex: "4B5563")
        static let gray700 = Color(hex: "374151")
        static let gray800 = Color(hex: "1F2937")
        static let gray900 = Color(hex: "111827")
        
        // Semantic Colors (Adaptive)
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        
        static let text = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        static let tertiaryText = Color(.tertiaryLabel)
        
        // Special UI Colors
        static let cardBackground = Color(.secondarySystemBackground)
        static let divider = Color(.separator)
        static let border = Color(.separator).opacity(0.3)
    }
    
    // MARK: - Spacing Scale
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius Scale
    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 1000 // For pill shapes
    }
    
    // MARK: - Shadow Styles
    struct Shadows {
        static let small = ModernShadow(color: .black.opacity(0.05), radius: 2, y: 1)
        static let medium = ModernShadow(color: .black.opacity(0.1), radius: 8, y: 4)
        static let large = ModernShadow(color: .black.opacity(0.15), radius: 16, y: 8)
    }
    
    // MARK: - Animation Durations
    struct Animation {
        static let quick: Double = 0.2
        static let standard: Double = 0.3
        static let gentle: Double = 0.5
        static let slow: Double = 0.8
    }
}

// MARK: - Helper Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ModernShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - Modern UI Components



struct ModernButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let size: Size
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary, ghost, destructive
    }
    
    enum Size {
        case small, medium, large
    }
    
    init(_ title: String, icon: String? = nil, style: ButtonStyle = .primary, size: Size = .medium, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ModernDesign.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(iconFont)
                }
                Text(title)
                    .font(textFont)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: ModernDesign.Radius.md))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textFont: Font {
        switch size {
        case .small: return ModernDesign.Typography.labelMedium
        case .medium: return ModernDesign.Typography.labelLarge
        case .large: return ModernDesign.Typography.headline3
        }
    }
    
    private var iconFont: Font {
        switch size {
        case .small: return .system(size: 14, weight: .medium)
        case .medium: return .system(size: 16, weight: .medium)
        case .large: return .system(size: 18, weight: .medium)
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return ModernDesign.Spacing.md
        case .medium: return ModernDesign.Spacing.lg
        case .large: return ModernDesign.Spacing.xl
        }
    }
    
    private var verticalPadding: CGFloat {
        switch size {
        case .small: return ModernDesign.Spacing.sm
        case .medium: return ModernDesign.Spacing.md
        case .large: return ModernDesign.Spacing.lg
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return ModernDesign.Colors.primary
        case .secondary: return ModernDesign.Colors.gray200
        case .ghost: return .clear
        case .destructive: return ModernDesign.Colors.error
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return ModernDesign.Colors.gray700
        case .ghost: return ModernDesign.Colors.primary
        case .destructive: return .white
        }
    }
}



struct ModernProgressBar: View {
    let progress: Double
    let color: Color
    
    init(progress: Double, color: Color = ModernDesign.Colors.primary) {
        self.progress = progress
        self.color = color
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: ModernDesign.Radius.full)
                    .fill(ModernDesign.Colors.gray200)
                
                RoundedRectangle(cornerRadius: ModernDesign.Radius.full)
                    .fill(color)
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeInOut(duration: ModernDesign.Animation.standard), value: progress)
            }
        }
        .frame(height: 8)
    }
}

struct ModernBadge: View {
    let text: String
    let style: Style
    
    enum Style {
        case primary, success, warning, error, neutral
    }
    
    init(_ text: String, style: Style = .neutral) {
        self.text = text
        self.style = style
    }
    
    var body: some View {
        Text(text)
            .font(ModernDesign.Typography.labelSmall)
            .padding(.horizontal, ModernDesign.Spacing.sm)
            .padding(.vertical, ModernDesign.Spacing.xs)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: ModernDesign.Radius.sm))
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return ModernDesign.Colors.primary.opacity(0.1)
        case .success: return ModernDesign.Colors.success.opacity(0.1)
        case .warning: return ModernDesign.Colors.warning.opacity(0.1)
        case .error: return ModernDesign.Colors.error.opacity(0.1)
        case .neutral: return ModernDesign.Colors.gray100
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return ModernDesign.Colors.primary
        case .success: return ModernDesign.Colors.success
        case .warning: return ModernDesign.Colors.warning
        case .error: return ModernDesign.Colors.error
        case .neutral: return ModernDesign.Colors.gray600
        }
    }
}