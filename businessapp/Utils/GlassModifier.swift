import SwiftUI

// MARK: - Glass Style Variations

enum GlassStyle {
    case standard
    case compact
    case prominent
    case subtle
    case card
    case button
    case navigation
    case overlay
    
    var config: GlassConfig {
        switch self {
        case .standard:
            return GlassConfig(
                cornerRadius: 28,
                backgroundOpacity: 0.12,
                borderOpacity: 0.25,
                shadowOpacity: 0.35,
                padding: 20,
                shadowRadius: 28,
                shadowOffset: CGSize(width: 0, height: 18)
            )
        case .compact:
            return GlassConfig(
                cornerRadius: 16,
                backgroundOpacity: 0.08,
                borderOpacity: 0.2,
                shadowOpacity: 0.25,
                padding: 12,
                shadowRadius: 16,
                shadowOffset: CGSize(width: 0, height: 8)
            )
        case .prominent:
            return GlassConfig(
                cornerRadius: 32,
                backgroundOpacity: 0.18,
                borderOpacity: 0.35,
                shadowOpacity: 0.45,
                padding: 24,
                shadowRadius: 40,
                shadowOffset: CGSize(width: 0, height: 24)
            )
        case .subtle:
            return GlassConfig(
                cornerRadius: 20,
                backgroundOpacity: 0.06,
                borderOpacity: 0.15,
                shadowOpacity: 0.15,
                padding: 16,
                shadowRadius: 12,
                shadowOffset: CGSize(width: 0, height: 4)
            )
        case .card:
            return GlassConfig(
                cornerRadius: 24,
                backgroundOpacity: 0.1,
                borderOpacity: 0.22,
                shadowOpacity: 0.3,
                padding: 18,
                shadowRadius: 24,
                shadowOffset: CGSize(width: 0, height: 12)
            )
        case .button:
            return GlassConfig(
                cornerRadius: 14,
                backgroundOpacity: 0.15,
                borderOpacity: 0.3,
                shadowOpacity: 0.2,
                padding: 8,
                shadowRadius: 8,
                shadowOffset: CGSize(width: 0, height: 2)
            )
        case .navigation:
            return GlassConfig(
                cornerRadius: 26,
                backgroundOpacity: 0.14,
                borderOpacity: 0.28,
                shadowOpacity: 0.4,
                padding: 14,
                shadowRadius: 32,
                shadowOffset: CGSize(width: 0, height: 16)
            )
        case .overlay:
            return GlassConfig(
                cornerRadius: 22,
                backgroundOpacity: 0.2,
                borderOpacity: 0.4,
                shadowOpacity: 0.5,
                padding: 20,
                shadowRadius: 36,
                shadowOffset: CGSize(width: 0, height: 20)
            )
        }
    }
}

struct GlassConfig {
    let cornerRadius: CGFloat
    let backgroundOpacity: Double
    let borderOpacity: Double
    let shadowOpacity: Double
    let padding: CGFloat
    let shadowRadius: CGFloat
    let shadowOffset: CGSize
}

struct GlassModifier: ViewModifier {
    let config: GlassConfig
    
    init(style: GlassStyle = .standard) {
        self.config = style.config
    }
    
    init(
        cornerRadius: CGFloat = 28,
        backgroundOpacity: Double = 0.12,
        borderOpacity: Double = 0.25,
        shadowOpacity: Double = 0.35,
        padding: CGFloat = 20,
        shadowRadius: CGFloat = 28,
        shadowOffset: CGSize = CGSize(width: 0, height: 18)
    ) {
        self.config = GlassConfig(
            cornerRadius: cornerRadius,
            backgroundOpacity: backgroundOpacity,
            borderOpacity: borderOpacity,
            shadowOpacity: shadowOpacity,
            padding: padding,
            shadowRadius: shadowRadius,
            shadowOffset: shadowOffset
        )
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
        
        content
            .padding(config.padding)
            .background {
                ZStack {
                    // Base glass effect
                    shape
                        .fill(.ultraThinMaterial, style: FillStyle())
                        .opacity(config.backgroundOpacity)
                    
                    // Enhanced frosted effect
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .overlay(
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(config.borderOpacity),
                                Color.white.opacity(config.borderOpacity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(config.shadowOpacity),
                radius: config.shadowRadius,
                x: config.shadowOffset.width,
                y: config.shadowOffset.height
            )
    }
}

// MARK: - Animated Glass Effects

struct AnimatedGlassModifier: ViewModifier {
    let style: GlassStyle
    @State private var animationOffset: CGFloat = 0
    @State private var isPressed: Bool = false
    
    init(style: GlassStyle = .standard) {
        self.style = style
    }
    
    func body(content: Content) -> some View {
        content
            .modifier(GlassModifier(style: style))
            .overlay(
                // Subtle shimmer effect
                RoundedRectangle(cornerRadius: style.config.cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .init(x: -0.3 + animationOffset, y: -0.3 + animationOffset),
                            endPoint: .init(x: 0.3 + animationOffset, y: 0.3 + animationOffset)
                        )
                    )
                    .opacity(0.7)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    animationOffset = 1.3
                }
            }
    }
}

// MARK: - Interactive Glass Button

struct GlassButtonStyle: ButtonStyle {
    let glassStyle: GlassStyle
    
    init(_ style: GlassStyle = .button) {
        self.glassStyle = style
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(GlassModifier(style: glassStyle))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func glassBackground(
        _ style: GlassStyle = .standard
    ) -> some View {
        self.modifier(GlassModifier(style: style))
    }
    
    func glassBackground(
        cornerRadius: CGFloat = 28,
        backgroundOpacity: Double = 0.12,
        borderOpacity: Double = 0.25,
        shadowOpacity: Double = 0.35,
        padding: CGFloat = 20,
        shadowRadius: CGFloat = 28,
        shadowOffset: CGSize = CGSize(width: 0, height: 18)
    ) -> some View {
        self.modifier(
            GlassModifier(
                cornerRadius: cornerRadius,
                backgroundOpacity: backgroundOpacity,
                borderOpacity: borderOpacity,
                shadowOpacity: shadowOpacity,
                padding: padding,
                shadowRadius: shadowRadius,
                shadowOffset: shadowOffset
            )
        )
    }
    
    func animatedGlass(_ style: GlassStyle = .standard) -> some View {
        self.modifier(AnimatedGlassModifier(style: style))
    }
    
    func glassButton(_ style: GlassStyle = .button) -> some View {
        self.buttonStyle(GlassButtonStyle(style))
    }
}

// MARK: - Specialized Glass Components

struct GlassCard<Content: View>: View {
    let content: Content
    let style: GlassStyle
    
    init(style: GlassStyle = .card, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        content
            .modifier(GlassModifier(style: style))
    }
}

struct GlassSection<Content: View>: View {
    let title: String?
    let content: Content
    let style: GlassStyle
    
    init(_ title: String? = nil, style: GlassStyle = .standard, @ViewBuilder content: () -> Content) {
        self.title = title
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            content
        }
        .modifier(GlassModifier(style: style))
    }
}

struct GlassNavigationItem<Content: View>: View {
    let content: Content
    let action: () -> Void
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
        }
        .buttonStyle(GlassButtonStyle(.navigation))
    }
}
