import SwiftUI

struct AnimationHelpers {
    // Spring Animation Presets
    static let playfulSpring = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let smoothSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let defaultSpring = Animation.spring(response: 0.5, dampingFraction: 0.7)
    
    // Entrance Animations
    static func fadeInSlideUp(delay: Double = 0) -> Animation {
        Animation.easeOut(duration: 0.5).delay(delay)
    }
    
    static func scaleBounce(delay: Double = 0) -> Animation {
        Animation.spring(response: 0.5, dampingFraction: 0.6).delay(delay)
    }
    
    // Interaction Animations
    static let buttonPress = Animation.spring(response: 0.3, dampingFraction: 0.6)
    static let cardTap = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let celebration = Animation.spring(response: 0.5, dampingFraction: 0.5)
}

// View Modifiers for Animations
extension View {
    func bounceEntrance(delay: Double = 0) -> some View {
        self.modifier(BounceEntranceModifier(delay: delay))
    }
    
    func fadeInUp(delay: Double = 0) -> some View {
        self.modifier(FadeInUpModifier(delay: delay))
    }
    
    func scaleIn(delay: Double = 0) -> some View {
        self.modifier(ScaleInModifier(delay: delay))
    }
}

struct BounceEntranceModifier: ViewModifier {
    let delay: Double
    @State private var animate = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(animate ? 1.0 : 0.8)
            .opacity(animate ? 1.0 : 0.0)
            .onAppear {
                withAnimation(AnimationHelpers.scaleBounce(delay: delay)) {
                    animate = true
                }
            }
    }
}

struct FadeInUpModifier: ViewModifier {
    let delay: Double
    @State private var animate = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1.0 : 0.0)
            .onAppear {
                withAnimation(AnimationHelpers.fadeInSlideUp(delay: delay)) {
                    animate = true
                }
            }
    }
}

struct ScaleInModifier: ViewModifier {
    let delay: Double
    @State private var animate = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(animate ? 1.0 : 0.5)
            .opacity(animate ? 1.0 : 0.0)
            .onAppear {
                withAnimation(AnimationHelpers.fadeInSlideUp(delay: delay)) {
                    animate = true
                }
            }
    }
}

