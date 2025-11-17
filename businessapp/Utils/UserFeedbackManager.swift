//
//  UserFeedbackManager.swift
//  VentureVoyage
//
//  Centralized manager for user feedback (toasts, haptics, alerts)
//  Provides consistent feedback experience throughout the app
//

import SwiftUI
import AVFoundation

/// Toast notification style
enum ToastStyle {
    case success
    case error
    case warning
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

/// Toast notification model
struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let style: ToastStyle
    let duration: TimeInterval

    init(message: String, style: ToastStyle, duration: TimeInterval = 3.0) {
        self.message = message
        self.style = style
        self.duration = duration
    }
}

/// Centralized manager for user feedback across the app
@MainActor
final class UserFeedbackManager: ObservableObject {
    static let shared = UserFeedbackManager()

    @Published var currentToast: Toast?

    private let hapticManager = HapticManager.shared

    private init() {}

    // MARK: - Toast Notifications

    /// Shows a success toast message
    func showSuccess(_ message: String, duration: TimeInterval = 3.0) {
        showToast(message, style: .success, duration: duration)
        if Config.enableHapticFeedback {
            hapticManager.notification(type: .success)
        }
    }

    /// Shows an error toast message
    func showError(_ message: String, duration: TimeInterval = 4.0) {
        showToast(message, style: .error, duration: duration)
        if Config.enableHapticFeedback {
            hapticManager.notification(type: .error)
        }
    }

    /// Shows a warning toast message
    func showWarning(_ message: String, duration: TimeInterval = 3.5) {
        showToast(message, style: .warning, duration: duration)
        if Config.enableHapticFeedback {
            hapticManager.notification(type: .warning)
        }
    }

    /// Shows an info toast message
    func showInfo(_ message: String, duration: TimeInterval = 3.0) {
        showToast(message, style: .info, duration: duration)
        if Config.enableHapticFeedback {
            hapticManager.impact(style: .light)
        }
    }

    /// Shows a custom toast message
    private func showToast(_ message: String, style: ToastStyle, duration: TimeInterval) {
        currentToast = Toast(message: message, style: style, duration: duration)

        // Auto-dismiss after duration
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if currentToast?.message == message {
                currentToast = nil
            }
        }
    }

    // MARK: - Haptic Feedback

    /// Triggers success haptic feedback
    func hapticSuccess() {
        guard Config.enableHapticFeedback else { return }
        hapticManager.notification(type: .success)
    }

    /// Triggers error haptic feedback
    func hapticError() {
        guard Config.enableHapticFeedback else { return }
        hapticManager.notification(type: .error)
    }

    /// Triggers warning haptic feedback
    func hapticWarning() {
        guard Config.enableHapticFeedback else { return }
        hapticManager.notification(type: .warning)
    }

    /// Triggers light impact haptic
    func hapticImpactLight() {
        guard Config.enableHapticFeedback else { return }
        hapticManager.impact(style: .light)
    }

    /// Triggers medium impact haptic
    func hapticImpactMedium() {
        guard Config.enableHapticFeedback else { return }
        hapticManager.impact(style: .medium)
    }

    /// Triggers heavy impact haptic
    func hapticImpactHeavy() {
        guard Config.enableHapticFeedback else { return }
        hapticManager.impact(style: .heavy)
    }

    /// Triggers selection haptic
    func hapticSelection() {
        guard Config.enableHapticFeedback else { return }
        hapticManager.selection()
    }

    // MARK: - Common Feedback Scenarios

    /// Feedback for successful goal completion
    func goalCompleted() {
        showSuccess(SuccessMessages.goalCompleted)
        hapticSuccess()
    }

    /// Feedback for milestone reached
    func milestoneReached() {
        showSuccess(SuccessMessages.milestonereached)
        hapticSuccess()
    }

    /// Feedback for idea generated
    func ideaGenerated(count: Int) {
        showSuccess("Generated \(count) personalized business ideas! 🎉")
        hapticSuccess()
    }

    /// Feedback for network error
    func networkError() {
        showError(ErrorMessages.networkError)
        hapticError()
    }

    /// Feedback for authentication error
    func authenticationError() {
        showError(ErrorMessages.authenticationFailed)
        hapticError()
    }

    /// Feedback for API key missing
    func apiKeyMissing() {
        showWarning(ErrorMessages.apiKeyMissing)
        hapticWarning()
    }
}

// MARK: - Toast View

/// SwiftUI view for displaying toast notifications
struct ToastView: View {
    let toast: Toast
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.style.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Text(toast.message)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(toast.style.color)
                .shadow(color: toast.style.color.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1
            }
        }
    }
}

// MARK: - Toast Modifier

/// ViewModifier for adding toast support to any view
struct ToastModifier: ViewModifier {
    @ObservedObject var feedbackManager = UserFeedbackManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content

            VStack {
                if let toast = feedbackManager.currentToast {
                    ToastView(toast: toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1000)
                }
                Spacer()
            }
            .animation(.spring(), value: feedbackManager.currentToast)
        }
    }
}

extension View {
    /// Adds toast notification support to the view
    func withToast() -> some View {
        modifier(ToastModifier())
    }
}
