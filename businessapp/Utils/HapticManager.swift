import SwiftUI
import UIKit

// MARK: - Duolingo-Style Haptic Feedback Manager

class HapticManager {
    static let shared = HapticManager()
    
    private let generator = UINotificationFeedbackGenerator()
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    enum HapticType {
        // Duolingo-inspired patterns
        case tap               // Light tap feedback
        case selection         // Selection changed
        case success           // Celebration/success
        case error             // Error/failure
        case warning           // Warning state
        case light             // Subtle feedback
        case medium            // Standard feedback
        case heavy             // Strong feedback
        
        // Duolingo-specific patterns
        case correctAnswer     // User got answer right
        case wrongAnswer       // User got answer wrong
        case levelUp           // Achievement unlocked
        case celebration       // Celebrate achievement
        case countdown         // Timer/countdown
        case swipe             // Swipe gesture
        case impact            // Generic impact
    }
    
    func trigger(_ type: HapticType) {
        switch type {
        // Standard feedback
        case .tap:
            impactLight.impactOccurred()
            
        case .selection:
            selectionGenerator.selectionChanged()
            
        case .light:
            impactLight.impactOccurred()
            
        case .medium:
            impactMedium.impactOccurred()
            
        case .heavy:
            impactHeavy.impactOccurred()
            
        case .impact:
            impactMedium.impactOccurred()
            
        // Notification feedback
        case .success:
            generator.notificationOccurred(.success)
            
        case .warning:
            generator.notificationOccurred(.warning)
            
        case .error:
            generator.notificationOccurred(.error)
            
        // Duolingo-specific patterns
        case .correctAnswer:
            // Double tap pattern for correct answer
            triggerPattern([0, 40, 40, 100])
            
        case .wrongAnswer:
            // Error pattern for wrong answer
            triggerPattern([0, 30, 50, 80])
            
        case .levelUp:
            // Celebration pattern for level up
            triggerPattern([0, 50, 100, 50, 150])
            
        case .celebration:
            // Double celebration for major achievement
            triggerPattern([0, 30, 80, 30, 80, 30, 150])
            
        case .countdown:
            // Quick pulses for countdown
            triggerPattern([0, 20, 40, 20, 40, 20])
            
        case .swipe:
            // Swipe gesture feedback
            triggerPattern([0, 50, 80])
        }
    }
    
    /// Creates a custom haptic pattern with delays
    /// - Parameter pattern: Array of millisecond timings for haptic pulses
    private func triggerPattern(_ pattern: [Int]) {
        DispatchQueue.main.async {
            var delay: UInt64 = 0
            for (index, timing) in pattern.enumerated() {
                if index == 0 { continue } // Skip first timing
                
                delay += UInt64(timing) * 1_000_000 // Convert ms to nanoseconds
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .nanoseconds(Int(delay))) {
                    if index % 2 == 1 {
                        self.impactMedium.impactOccurred()
                    }
                }
            }
        }
    }
    
    /// Creates a quick double tap effect
    func doubleTap() {
        impactLight.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impactLight.impactOccurred()
        }
    }
    
    /// Creates a triple tap celebration effect
    func tripleTap() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                self.impactMedium.impactOccurred()
            }
        }
    }
    
    /// Creates a pulse effect
    func pulse(count: Int = 3) {
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) {
                self.impactLight.impactOccurred()
            }
        }
    }
    
    /// Creates a success rhythm pattern
    func successRhythm() {
        impactMedium.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impactMedium.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.impactHeavy.impactOccurred()
        }
    }
    
    /// Convenience methods for common patterns
    func selection() {
        trigger(.selection)
    }
    
    func success() {
        trigger(.success)
    }
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .rigid:
            impactMedium.impactOccurred()
        case .soft:
            impactLight.impactOccurred()
        @unknown default:
            impactMedium.impactOccurred()
        }
    }
}

// MARK: - Haptic Modifiers

extension View {
    func hapticOnTap(_ type: HapticManager.HapticType = .medium) -> some View {
        self.modifier(HapticModifier(hapticType: type))
    }
}

struct HapticModifier: ViewModifier {
    let hapticType: HapticManager.HapticType
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                HapticManager.shared.trigger(hapticType)
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        Button("Light Haptic") {
            HapticManager.shared.trigger(.light)
        }
        .buttonStyle(.bordered)
        
        Button("Medium Haptic") {
            HapticManager.shared.trigger(.medium)
        }
        .buttonStyle(.bordered)
        
        Button("Success Haptic") {
            HapticManager.shared.trigger(.success)
        }
        .buttonStyle(.bordered)
    }
    .padding()
}
