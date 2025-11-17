//
//  AppConstants.swift
//  VentureVoyage
//
//  Application-wide constants and configurations
//  Centralized location for all app constants, keys, and configuration values
//

import Foundation
import SwiftUI

// MARK: - User Defaults Keys
enum UserDefaultsKeys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let businessIdeasData = "businessIdeasData"
    static let userProfileData = "userProfileData"
    static let selectedBusinessIdeaID = "selectedBusinessIdeaID"
    static let savedIslands = "saved_islands"
    static let journeyProgress = "journey_progress"
    static let progressNotes = "progress_notes"
    static let appReminders = "app_reminders"
    static let googleAIAPIKey = "GOOGLE_AI_API_KEY"
    static let googleAIModel = "GOOGLE_AI_MODEL"
}

// MARK: - Analytics Event Names
enum AnalyticsEvents {
    static let signUpEmail = "sign_up_email"
    static let loginEmail = "login_email"
    static let loginAnonymous = "login_anonymous"
    static let loginGoogle = "login_google"
    static let loginApple = "login_apple"
    static let ideaGenerated = "idea_generated"
    static let goalCompleted = "goal_completed"
    static let milestoneReached = "milestone_reached"
}

// MARK: - UI Constants
enum UIConstants {
    static let animationDuration: Double = 0.3
    static let longAnimationDuration: Double = 0.6
    static let cornerRadius: CGFloat = 12
    static let largeCornerRadius: CGFloat = 20
    static let defaultPadding: CGFloat = 16
    static let largePadding: CGFloat = 24
}

// MARK: - App Branding
enum AppBranding {
    static let appName = "VentureVoyage"
    static let tagline = "Navigate Your Entrepreneurial Journey"
    static let welcomeMessage = "Welcome to VentureVoyage"
    static let poweredBy = "Powered by AI"
}

// MARK: - Onboarding Text
enum OnboardingText {
    static let welcome = "Welcome to VentureVoyage! 🚀"
    static let subtitle = "Your AI-powered companion for entrepreneurial success"
    static let quiz1 = "Let's discover your perfect business opportunity"
    static let quiz2 = "Answer a few questions to personalize your journey"
    static let quiz3 = "We'll use AI to generate ideas tailored to you"
    static let completion = "Great! You're ready to start your voyage"
    static let getStarted = "Get Started"
    static let continueButton = "Continue"
    static let skipButton = "Skip for now"
}

// MARK: - Feature Names
enum FeatureNames {
    static let aiAssistant = "AI Mentor"
    static let ideaHub = "Idea Hub"
    static let journeyMap = "Journey Map"
    static let progressTracker = "Progress Tracker"
    static let goalsPlanner = "Goals Planner"
    static let timeline = "Voyage Timeline"
}

// MARK: - Error Messages
enum ErrorMessages {
    static let networkError = "Unable to connect. Please check your internet connection."
    static let apiKeyMissing = "API key not configured. Please configure in Settings."
    static let authenticationFailed = "Authentication failed. Please try again."
    static let genericError = "Something went wrong. Please try again."
    static let noIdeasFound = "No business ideas found. Try generating new ideas!"
    static let saveFailed = "Failed to save. Please try again."
}

// MARK: - Success Messages
enum SuccessMessages {
    static let ideaGenerated = "Ideas generated successfully! 🎉"
    static let goalCompleted = "Goal completed! Keep up the great work! 🎯"
    static let milestonereached = "Milestone reached! You're making progress! 🏆"
    static let profileSaved = "Profile saved successfully!"
    static let accountCreated = "Welcome aboard! Your account is ready. ⚡"
}
