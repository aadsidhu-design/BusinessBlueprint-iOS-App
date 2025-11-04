import Foundation

// MARK: - Configuration
// ⚠️ IMPORTANT: Sensitive credentials should NEVER be hardcoded
// Store in environment variables, Xcode build settings, or Keychain
// Never commit API keys to version control

struct Config {
    /// Google AI API Key - Set via environment variable
    /// In Xcode: Edit Scheme → Run → Pre-actions → Add user-defined setting
    /// Or set: export GOOGLE_AI_API_KEY="your_key_here"
    static let googleAIKey: String = {
        if let key = ProcessInfo.processInfo.environment["GOOGLE_AI_API_KEY"], !key.isEmpty {
            return key
        }
        // Fallback: Load from Info.plist if available
        if let key = Bundle.main.infoDictionary?["GOOGLE_AI_API_KEY"] as? String {
            return key
        }
        fatalError("❌ GOOGLE_AI_API_KEY not set. Please configure it in your environment.")
    }()
    
    /// Firebase Project Configuration
    /// These are public identifiers safe to commit
    static let firebaseProjectID = "studio-5837146656-10acf"
    static let firebaseProjectNumber = "1095936176351"
    
    /// Firebase Web API Key - Load from Info.plist
    /// This should be added to Info.plist from a secure config file (not in git)
    static let firebaseWebAPIKey: String = {
        if let key = Bundle.main.infoDictionary?["FIREBASE_WEB_API_KEY"] as? String {
            return key
        }
        return ProcessInfo.processInfo.environment["FIREBASE_WEB_API_KEY"] ?? ""
    }()
    
    /// App Settings
    static let appName = "BusinessIdea"
    static let appVersion = "1.0.0"
    static let minimumIOSVersion = "14.0"
}
