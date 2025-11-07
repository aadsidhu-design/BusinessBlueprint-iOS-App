import SwiftUI

// MARK: - Typography
enum Typography {
    static let title1 = Font.system(size: 32, weight: .bold)
    static let title2 = Font.system(size: 28, weight: .bold)
    static let title3 = Font.system(size: 24, weight: .bold)
    static let headline = Font.system(size: 18, weight: .semibold)
    static let body = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 16, weight: .medium)
    static let bodySemibold = Font.system(size: 16, weight: .semibold)
    static let callout = Font.system(size: 14, weight: .regular)
    static let calloutMedium = Font.system(size: 14, weight: .medium)
    static let caption = Font.system(size: 12, weight: .regular)
    static let captionMedium = Font.system(size: 12, weight: .medium)
    static let label = Font.system(size: 11, weight: .semibold)
}

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner Radius
enum CornerRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let full: CGFloat = 999
}

// MARK: - Shadows
struct AppShadows {
    static let small = Shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    static let medium = Shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    static let large = Shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Card Modifier
struct CardModifier: ViewModifier {
    let shadow: Shadow
    
    func body(content: Content) -> some View {
        content
            .background(AppColors.surface)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

extension View {
    func cardStyle(shadow: Shadow = AppShadows.small) -> some View {
        modifier(CardModifier(shadow: shadow))
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    let isLoading: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.bodySemibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(AppColors.primaryGradient)
            .cornerRadius(CornerRadius.lg)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.bodySemibold)
            .foregroundColor(AppColors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(AppColors.primary.opacity(0.1))
            .cornerRadius(CornerRadius.lg)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// MARK: - Text Field Style
struct AppTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(Typography.body)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(AppColors.surfaceLight)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(AppColors.border, lineWidth: 1)
            )
    }
}
