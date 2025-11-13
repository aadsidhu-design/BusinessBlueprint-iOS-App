# Project Structure

## Root Organization

```
businessapp/                    # Main application target
businessappTests/              # Unit tests
businessappUITests/            # UI tests
businessapp.xcodeproj/         # Xcode project configuration
Resources/                     # App resources (Info.plist)
```

## Application Structure (businessapp/)

### Core Files
- `businessappApp.swift` - App entry point, Firebase configuration
- `ContentView.swift` - Root view with auth routing
- `Config.swift` - API keys and configuration constants
- `GoogleService-Info.plist` - Firebase configuration

### Models/ - Data structures
- `BusinessIdea.swift` - Core business idea model with DailyGoal, Milestone, UserProfile
- `IslandTimeline.swift` - Gamification journey models
- `Questions.swift` - Quiz/onboarding questions
- `UserContext.swift` - User context tracking

### Services/ - Business logic & API integration
- `GoogleAIService.swift` - Google Gemini AI integration (1667 lines)
- `FirebaseService.swift` - Firebase Auth & Firestore operations
- `IntelligentContextManager.swift` - Context-aware AI prompting
- `UserContextManager.swift` - User behavior tracking
- `NotesReminderManager.swift` - Notes and reminders management

### ViewModels/ - State management (MVVM)
- `AuthViewModel.swift` - Authentication state
- `BusinessIdeaViewModel.swift` - Business ideas management
- `BusinessPlanStore.swift` - Central state store
- `DashboardViewModel.swift` - Dashboard data
- `IslandTimelineViewModel.swift` - Journey progression
- `QuizViewModel.swift` - Onboarding quiz logic
- `OnboardingViewModel.swift` - Onboarding flow
- `EventViewModel.swift` - Event tracking
- `ExperienceViewModel.swift` - User experience state

### Views/ - UI components
Main screens:
- `AuthView.swift` / `AuthViewNew.swift` - Authentication
- `DashboardView.swift` / `DashboardViewNew.swift` - Main dashboard
- `IslandTimelineView.swift` - Gamified journey view
- `IslandDetailView.swift` - Individual island details
- `BusinessIdeasView.swift` - Business ideas list
- `AIAssistantView.swift` / `NewAIAssistantView.swift` - AI chat
- `AIProgressAssistantView.swift` - Progress-focused AI chat
- `ProfileView.swift` - User profile
- `SettingsView.swift` - App settings
- `OnboardingView.swift` / `OnboardingQuestionaireView.swift` - Onboarding
- `LaunchView.swift` / `LaunchViewNew.swift` - Launch screen
- `MainTabViewNew.swift` - Tab navigation

Supporting views:
- `QuizView.swift` - Quiz interface
- `BrainDumpView.swift` - Idea brainstorming
- `FocusPlannerView.swift` - Goal planning
- `PlannerNotesView.swift` - Notes management
- `ReminderCenterView.swift` / `ReminderComposerView.swift` - Reminders
- `AddNoteView.swift` / `AddReminderView.swift` - Add forms
- `ProgressBarView.swift` - Progress visualization
- `RootView.swift` - Root navigation

Experience views:
- `HomeExperienceView.swift` - Home experience
- `AssistantExperienceView.swift` - AI assistant experience
- `ProgressExperienceView.swift` - Progress tracking experience
- `JourneyHomeView.swift` - Journey home
- `DiscoverView.swift` - Discovery interface
- `TimelineFinal.swift` - Timeline visualization

#### Views/Components/ - Reusable UI components
- `AnimatedBottomBar.swift` - Animated tab bar
- `ConfettiView.swift` - Celebration animations
- `EmptyStateView.swift` - Empty state placeholders
- `SelectionCardView.swift` - Selection cards

#### Views/Shared/ - Shared UI elements
- `ModernComponents.swift` - Modern UI components
- `EnhancedStates.swift` - Enhanced state views
- `VisionBackground.swift` - Background effects
- `AISettingsCard.swift` - AI settings UI

#### Views/Modern/ - Modern design components
(Empty folder for future modern UI components)

### Utils/ - Utilities & helpers
Design system:
- `DesignSystem.swift` - Typography, spacing, shadows, button styles
- `ModernDesignSystem.swift` - Modern design tokens
- `AppColors.swift` - Color palette
- `AppConstants.swift` - App-wide constants
- `CleanComponents.swift` - Clean UI components
- `GlassModifier.swift` - Glassmorphism effects

Animation & interaction:
- `AnimationExtensions.swift` - Animation utilities
- `AnimationHelpers.swift` - Animation helpers
- `HapticManager.swift` - Haptic feedback

State management:
- `ThemeManager.swift` - Theme management
- `OnboardingManager.swift` - Onboarding state
- `PerformanceMonitor.swift` - Performance tracking

### Assets.xcassets/ - Visual assets
- App icons and accent colors
- Character images (duoHappy, duoInterested, duoReading, duoWithName)
- UI elements (flashCards, graph1-4)
- Language flags (arabic, china, france, germany, italy, japan, portugal, south-korea, spain)

## Architecture Patterns

### MVVM Pattern
- **Models**: Pure data structures (Codable, Identifiable)
- **ViewModels**: ObservableObject classes with @Published properties
- **Views**: SwiftUI views with @StateObject/@EnvironmentObject

### State Management
- `BusinessPlanStore` - Central state store (EnvironmentObject)
- ViewModels sync with store via Combine publishers
- Two-way binding with `isSyncingFromStore` flag to prevent loops

### Service Layer
- Singleton pattern for services (`.shared`)
- Async completion handlers for API calls
- Error handling with custom error types (e.g., `GoogleAIError`)

### Naming Conventions
- ViewModels: `*ViewModel.swift`
- Views: `*View.swift`
- Services: `*Service.swift` or `*Manager.swift`
- Models: Descriptive nouns (e.g., `BusinessIdea.swift`)
- Extensions: `*Extensions.swift`

## Code Style

### SwiftUI Patterns
- Prefer `@StateObject` for view-owned state
- Use `@EnvironmentObject` for shared state
- Extract subviews for complex layouts
- Use view modifiers for reusable styling

### Async Patterns
- Completion handlers for Firebase/AI operations
- `DispatchQueue.main.async` for UI updates
- URLSession with custom timeout configurations

### Error Handling
- Custom error enums conforming to `LocalizedError`
- User-friendly error messages with recovery suggestions
- Graceful fallbacks for AI failures

## File Organization Rules

1. Group related files in folders (Models, Views, ViewModels, Services, Utils)
2. Keep view components in Views/Components/ or Views/Shared/
3. Place reusable utilities in Utils/
4. Store design tokens in dedicated files (AppColors, DesignSystem)
5. Separate concerns: UI (Views) vs Logic (ViewModels) vs Data (Services)
