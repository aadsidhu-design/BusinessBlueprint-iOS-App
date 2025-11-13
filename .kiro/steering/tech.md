# Technical Stack

## Platform & Language

- **Platform**: iOS 16.0+
- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Build System**: Xcode 26.0.1
- **Architecture**: MVVM (Model-View-ViewModel)

## Backend & Services

- **Firebase**: Authentication, Firestore database
- **AI Service**: Google AI Studio (Gemini 2.0 Flash Exp model)
- **Authentication**: Firebase Auth + Google Sign-In

## Dependencies (Swift Package Manager)

### Firebase SDK (v12.5.0)
- FirebaseAuth
- FirebaseFirestore
- FirebaseCore
- FirebaseAnalytics
- FirebaseCrashlytics
- FirebaseStorage
- FirebaseMessaging
- FirebaseRemoteConfig
- FirebasePerformance

### Google Services
- GoogleSignIn (v9.0.0)
- GoogleSignInSwift

### Supporting Libraries
- GTMAppAuth (v5.0.0)
- GTMSessionFetcher (v3.5.0)
- swift-protobuf (v1.33.3)

## Configuration

### API Keys
- Google AI API key stored in `Config.swift` with fallback to UserDefaults/environment variables
- Firebase configuration via `GoogleService-Info.plist`
- Bundle identifier: `com.businessapp.company.businessapp`

### Build Settings
- Development Team: Z28V839VF6
- Deployment Target: iOS 16.0+
- Supported Platforms: iPhone, iPad (no Mac Catalyst)
- Swift Concurrency: Enabled with MainActor isolation

## Common Commands

### Build & Run
```bash
# Open project in Xcode
open businessapp.xcodeproj

# Build from command line
xcodebuild -project businessapp.xcodeproj -scheme businessapp -configuration Debug

# Run tests
xcodebuild test -project businessapp.xcodeproj -scheme businessapp -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Package Management
```bash
# Resolve package dependencies
xcodebuild -resolvePackageDependencies

# Update packages
# File → Packages → Update to Latest Package Versions (in Xcode)
```

### Clean Build
```bash
# Clean build folder
xcodebuild clean -project businessapp.xcodeproj -scheme businessapp

# Or use Xcode: Cmd + Shift + K
```

## Development Notes

- Firebase App Check is disabled to avoid 403 errors (only Auth + Firestore used)
- Minimum services configured for optimal performance
- Dark mode is the preferred color scheme
- Timeout intervals: 30s for requests, 60s for resources
