import Foundation

// MARK: - Configuration
// ⚠️ IMPORTANT: Sensitive credentials should NEVER be hardcoded
// Store in environment variables, Xcode build settings, or Keychain
// Never commit API keys to version control

struct Config {
    /// Google AI API Key - Read from UserDefaults, env, or Info.plist
    /// Set via Settings screen, environment, or Info.plist
    /// SECURITY: Never hardcode API keys. Always use secure configuration methods.
    static var googleAIKey: String {
        // Priority 1: Info.plist (recommended for build-time configuration)
        // Info.plist entries can be substituted at build time using Xcode build settings or .xcconfig
        if let key = Bundle.main.infoDictionary?["GOOGLE_AI_API_KEY"] as? String, !key.isEmpty {
            print("🔍 Config: GOOGLE_AI_API_KEY found in Info.plist (len: \(key.count))")
            return key
        }

        // Priority 2: Environment variables (for CI/CD and local development)
        if let key = ProcessInfo.processInfo.environment["GOOGLE_AI_API_KEY"], !key.isEmpty {
            print("🔍 Config: GOOGLE_AI_API_KEY found in ENV (len: \(key.count))")
            return key
        }

        // Priority 3: UserDefaults (for runtime configuration via Settings)
        if let saved = UserDefaults.standard.string(forKey: "GOOGLE_AI_API_KEY"), !saved.isEmpty {
            print("🔍 Config: GOOGLE_AI_API_KEY found in UserDefaults (len: \(saved.count))")
            return saved
        }

        // No key found - user must configure via Settings or build configuration
        print("⚠️ Config: GOOGLE_AI_API_KEY not configured. Please set in Settings or build configuration.")
        return ""
    }

    /// Google AI model identifier - override via Settings, env or Info.plist
    static var googleAIModel: String {
        if let saved = UserDefaults.standard.string(forKey: "GOOGLE_AI_MODEL"), !saved.isEmpty {
            return saved
        }
        if let model = ProcessInfo.processInfo.environment["GOOGLE_AI_MODEL"], !model.isEmpty {
            return model
        }
        if let model = Bundle.main.infoDictionary?["GOOGLE_AI_MODEL"] as? String, !model.isEmpty {
            return model
        }
    // Default to a modern Gemini model. Change in Settings or env if needed.
    return "gemini-2.5-flash"
    }

    static func printDebugInfo() {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            print("🔎 Info.plist path: \(path)")
        } else {
            print("🔎 Info.plist path: not found")
        }

        if let val = Bundle.main.infoDictionary?["GOOGLE_AI_API_KEY"] as? String {
            print("🔎 GOOGLE_AI_API_KEY in Info.plist present (len: \(val.count))")
        } else {
            print("🔎 GOOGLE_AI_API_KEY not present in Info.plist")
        }
    }

    /// Return the key source for the GOOGLE_AI_API_KEY
    static func googleAIKeySource() -> String {
        if let key = Bundle.main.infoDictionary?["GOOGLE_AI_API_KEY"] as? String, !key.isEmpty {
            return "Info.plist"
        }
        if let _ = ProcessInfo.processInfo.environment["GOOGLE_AI_API_KEY"], !(ProcessInfo.processInfo.environment["GOOGLE_AI_API_KEY"] ?? "").isEmpty {
            return "Environment"
        }
        if let _ = UserDefaults.standard.string(forKey: "GOOGLE_AI_API_KEY"), !(UserDefaults.standard.string(forKey: "GOOGLE_AI_API_KEY") ?? "").isEmpty {
            return "UserDefaults"
        }
        return "None"
    }
    
    /// Firebase Project Configuration
    /// These are public identifiers safe to commit
    static let firebaseProjectID = "businessapp-b9a38"
    static let firebaseProjectNumber = "375175320585"
    static let firebaseStorageBucket = "businessapp-b9a38.firebasestorage.app"
    
    /// Firebase Web API Key - Load from Info.plist or env
    static var firebaseWebAPIKey: String {
        if let key = Bundle.main.infoDictionary?["FIREBASE_WEB_API_KEY"] as? String, !key.isEmpty {
            return key
        }
        return ProcessInfo.processInfo.environment["FIREBASE_WEB_API_KEY"] ?? ""
    }
    
    /// App Settings
    static let appName = "VentureVoyage"
    static let appDisplayName = "VentureVoyage"
    static let appTagline = "Navigate Your Entrepreneurial Journey"
    static let appDescription = "AI-powered business idea generation and progress tracking"
    static let appVersion = "2.0.0"
    static let minimumIOSVersion = "16.0"

    /// App Theme
    static let primaryBrandColor = "voyageBlue"  // Modern blue for trust and innovation
    static let accentBrandColor = "voyageOrange"  // Energetic orange for action
    static let successColor = "voyageGreen"  // Success and growth

    /// Feature Flags
    static let enableHapticFeedback = true
    static let enableAdvancedAnalytics = true
    static let enableOfflineMode = true
}
