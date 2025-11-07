import Foundation

// MARK: - Configuration
// ⚠️ IMPORTANT: Sensitive credentials should NEVER be hardcoded
// Store in environment variables, Xcode build settings, or Keychain
// Never commit API keys to version control

struct Config {
    /// Google AI API Key - Read from UserDefaults, env, or Info.plist
    /// Set via Settings screen, environment, or Info.plist
    static var googleAIKey: String {
        if let saved = UserDefaults.standard.string(forKey: "GOOGLE_AI_API_KEY"), !saved.isEmpty {
            return saved
        }
        if let key = ProcessInfo.processInfo.environment["GOOGLE_AI_API_KEY"], !key.isEmpty {
            return key
        }
        if let key = Bundle.main.infoDictionary?["GOOGLE_AI_API_KEY"] as? String, !key.isEmpty {
            return key
        }
        // Fallback to pre-configured key
        return "AIzaSyAy23CL7PUMQ-KSpdJUvmWV1XMq8p_7-7Q"
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
        return "gemini-2.0-flash-exp" // Updated to faster model
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
    static let appName = "BusinessIdea"
    static let appVersion = "1.0.0"
    static let minimumIOSVersion = "14.0"
}
