//
//  AccessibilityHelper.swift
//  VentureVoyage
//
//  Utilities for improving app accessibility
//  Supports VoiceOver, Dynamic Type, and other accessibility features
//

import SwiftUI

/// Accessibility utilities for consistent app-wide accessibility
enum AccessibilityHelper {

    // MARK: - Labels

    /// Standard accessibility labels for common UI elements
    enum Labels {
        static let closeButton = "Close"
        static let backButton = "Back"
        static let nextButton = "Next"
        static let submitButton = "Submit"
        static let editButton = "Edit"
        static let deleteButton = "Delete"
        static let saveButton = "Save"
        static let cancelButton = "Cancel"
        static let addButton = "Add"
        static let searchButton = "Search"
        static let filterButton = "Filter"
        static let refreshButton = "Refresh"
        static let settingsButton = "Settings"
        static let profileButton = "Profile"
        static let menuButton = "Menu"
    }

    // MARK: - Hints

    /// Accessibility hints for providing additional context
    enum Hints {
        static let tapToOpen = "Double tap to open"
        static let tapToClose = "Double tap to close"
        static let tapToEdit = "Double tap to edit"
        static let tapToDelete = "Double tap to delete"
        static let tapToSave = "Double tap to save"
        static let tapToComplete = "Double tap to mark as complete"
        static let swipeToDelete = "Swipe left to delete"
    }

    // MARK: - Identifiers

    /// Accessibility identifiers for UI testing
    enum Identifiers {
        static let loginButton = "loginButton"
        static let signUpButton = "signUpButton"
        static let emailField = "emailField"
        static let passwordField = "passwordField"
        static let businessIdeaCard = "businessIdeaCard"
        static let goalItem = "goalItem"
        static let milestoneItem = "milestoneItem"
        static let aiChatInput = "aiChatInput"
        static let aiChatSendButton = "aiChatSendButton"
    }

    // MARK: - Helper Methods

    /// Creates an accessibility label for a goal item
    static func goalLabel(title: String, completed: Bool, dueDate: Date) -> String {
        let status = completed ? "Completed" : "Incomplete"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dueDateString = dateFormatter.string(from: dueDate)
        return "\(title), \(status), due \(dueDateString)"
    }

    /// Creates an accessibility label for a milestone
    static func milestoneLabel(title: String, progress: Int) -> String {
        return "\(title), \(progress) percent complete"
    }

    /// Creates an accessibility label for a business idea
    static func businessIdeaLabel(title: String, category: String, difficulty: String) -> String {
        return "\(title), \(category) category, \(difficulty) difficulty"
    }

    /// Creates an accessibility value for a progress indicator
    static func progressValue(_ percentage: Int) -> String {
        return "\(percentage) percent"
    }
}

// MARK: - Accessibility Modifiers

extension View {
    /// Adds enhanced accessibility support for buttons
    func accessibleButton(
        label: String,
        hint: String? = nil,
        identifier: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? AccessibilityHelper.Hints.tapToOpen)
            .accessibilityIdentifier(identifier ?? "")
            .accessibilityAddTraits(.isButton)
    }

    /// Adds enhanced accessibility support for text fields
    func accessibleTextField(
        label: String,
        hint: String? = nil,
        identifier: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityIdentifier(identifier ?? "")
    }

    /// Adds enhanced accessibility support for cards/interactive elements
    func accessibleCard(
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? AccessibilityHelper.Hints.tapToOpen)
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(.isButton)
    }

    /// Marks content as a heading for better navigation
    func accessibleHeading() -> some View {
        self.accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Dynamic Type Support

/// Helper for managing Dynamic Type scaling
enum DynamicTypeHelper {

    /// Checks if the user has enabled larger text sizes
    static func isAccessibilitySize(_ sizeCategory: ContentSizeCategory) -> Bool {
        sizeCategory >= .accessibilityMedium
    }

    /// Returns a scaled value based on the current Dynamic Type setting
    static func scaled(
        _ value: CGFloat,
        category: ContentSizeCategory,
        min: CGFloat? = nil,
        max: CGFloat? = nil
    ) -> CGFloat {
        let scale = scaleFactor(for: category)
        var scaled = value * scale

        if let min = min {
            scaled = Swift.max(scaled, min)
        }
        if let max = max {
            scaled = Swift.min(scaled, max)
        }

        return scaled
    }

    private static func scaleFactor(for category: ContentSizeCategory) -> CGFloat {
        switch category {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.0
        case .extraLarge: return 1.1
        case .extraExtraLarge: return 1.2
        case .extraExtraExtraLarge: return 1.3
        case .accessibilityMedium: return 1.4
        case .accessibilityLarge: return 1.5
        case .accessibilityExtraLarge: return 1.6
        case .accessibilityExtraExtraLarge: return 1.7
        case .accessibilityExtraExtraExtraLarge: return 1.8
        @unknown default: return 1.0
        }
    }
}
