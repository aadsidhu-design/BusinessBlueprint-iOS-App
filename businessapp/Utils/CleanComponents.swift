import SwiftUI

// MARK: - Modern Button Styles
struct ModernButtonStyle: ButtonStyle {
    var color: Color = AppColors.primary
    var size: ButtonSize = .medium
    var fullWidth: Bool = true
    
    enum ButtonSize {
        case small, medium, large
        
        var height: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 50
            case .large: return 56
            }
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .background(color)
            .cornerRadius(size.height / 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

struct GhostButtonStyle: ButtonStyle {
    var color: Color = AppColors.primary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(color.opacity(0.1))
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

// MARK: - Clean Text Field
struct CleanTextField: View {
    let title: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                }
            }
            .padding(14)
            .background(AppColors.tertiaryBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    var color: Color = AppColors.primary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let value: String
    let label: String
    var color: Color = AppColors.primary
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
