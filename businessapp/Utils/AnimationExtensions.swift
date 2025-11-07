import SwiftUI

// MARK: - Animation Extensions

extension View {
    /// Bouncy entrance animation
    func bouncyEntrance(delay: Double = 0) -> some View {
        BouncyEntranceView(content: self, delay: delay)
    }
    
    /// Slide in from edge animation
    func slideIn(from edge: Edge, delay: Double = 0, distance: CGFloat = 30) -> some View {
        SlideInView(content: self, edge: edge, delay: delay, distance: distance)
    }
    
    /// Fade in animation with scale
    func fadeInScale(delay: Double = 0, scale: CGFloat = 0.9) -> some View {
        FadeInScaleView(content: self, delay: delay, scale: scale)
    }
    
    /// Shimmer loading effect
    func shimmer(isActive: Bool = true) -> some View {
        self
            .overlay(
                ShimmerView()
                    .opacity(isActive ? 1 : 0)
            )
    }
    
    /// Pulse animation for loading states
    func pulseLoading(isActive: Bool = true) -> some View {
        self
            .scaleEffect(isActive ? 1.05 : 1.0)
            .opacity(isActive ? 0.7 : 1.0)
            .animation(
                isActive ? 
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : 
                    .easeInOut(duration: 0.3),
                value: isActive
            )
    }
    
    /// Interactive press animation
    func interactivePress() -> some View {
        self.scaleEffect(1.0)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    // Scale down briefly on tap
                }
            }
    }
    
    private func offsetForEdge(_ edge: Edge, distance: CGFloat) -> CGSize {
        switch edge {
        case .top: return CGSize(width: 0, height: -distance)
        case .bottom: return CGSize(width: 0, height: distance)
        case .leading: return CGSize(width: -distance, height: 0)
        case .trailing: return CGSize(width: distance, height: 0)
        }
    }
}

// MARK: - Custom Animation Views

struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.clear,
                Color.white.opacity(0.4),
                Color.clear
            ]),
            startPoint: .init(x: -0.3 + phase, y: -0.3 + phase),
            endPoint: .init(x: 0.3 + phase, y: 0.3 + phase)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }
}

struct OldTypingIndicatorView: View {
    @State private var animationOffsets: [CGFloat] = [0, 0, 0]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffsets[index])
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationOffsets[index]
                    )
            }
        }
        .onAppear {
            for i in 0..<3 {
                animationOffsets[i] = -4
            }
        }
    }
}

struct PulseRing: View {
    @State private var pulsate = false
    let color: Color
    let size: CGFloat
    
    init(color: Color = .white, size: CGFloat = 100) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 2)
                .frame(width: size, height: size)
                .scaleEffect(pulsate ? 1.3 : 1.0)
                .opacity(pulsate ? 0 : 1)
                .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulsate)
            
            Circle()
                .stroke(color.opacity(0.6), lineWidth: 3)
                .frame(width: size * 0.7, height: size * 0.7)
                .scaleEffect(pulsate ? 1.2 : 1.0)
                .opacity(pulsate ? 0 : 1)
                .animation(.easeOut(duration: 1.5).delay(0.3).repeatForever(autoreverses: false), value: pulsate)
        }
        .onAppear {
            pulsate = true
        }
    }
}

struct LoadingState: View {
    let message: String
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                PulseRing(color: .blue, size: 80)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: rotationAngle)
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .onAppear {
            rotationAngle = 360
        }
    }
}

struct ErrorState: View {
    let message: String
    let retry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            if let retry = retry {
                Button("Try Again", action: retry)
                    .glassButton(.button)
            }
        }
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        icon: String,
        title: String,
        message: String,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(.white.opacity(0.4))
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let actionTitle = actionTitle {
                Button(actionTitle, action: action)
                    .glassButton(.button)
            }
        }
        .padding(.horizontal, 40)
        .fadeInScale(delay: 0.3)
    }
}

// MARK: - Staggered Animation Modifier

struct StaggeredAnimation: ViewModifier {
    let index: Int
    let total: Int
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .onAppear {
                let delay = Double(index) / Double(total) * 0.6
                withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    func staggered(index: Int, total: Int) -> some View {
        self.modifier(StaggeredAnimation(index: index, total: total))
    }
}

// MARK: - Animation Wrapper Views

struct BouncyEntranceView<Content: View>: View {
    let content: Content
    let delay: Double
    @State private var hasAppeared = false
    
    var body: some View {
        content
            .scaleEffect(hasAppeared ? 1.0 : 0.1)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

struct SlideInView<Content: View>: View {
    let content: Content
    let edge: Edge
    let delay: Double
    let distance: CGFloat
    @State private var hasAppeared = false
    
    var body: some View {
        content
            .offset(hasAppeared ? .zero : offsetForEdge(edge, distance: distance))
            .opacity(hasAppeared ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
    
    private func offsetForEdge(_ edge: Edge, distance: CGFloat) -> CGSize {
        switch edge {
        case .top: return CGSize(width: 0, height: -distance)
        case .bottom: return CGSize(width: 0, height: distance)
        case .leading: return CGSize(width: -distance, height: 0)
        case .trailing: return CGSize(width: distance, height: 0)
        }
    }
}

struct FadeInScaleView<Content: View>: View {
    let content: Content
    let delay: Double
    let scale: CGFloat
    @State private var hasAppeared = false
    
    var body: some View {
        content
            .scaleEffect(hasAppeared ? 1.0 : scale)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}