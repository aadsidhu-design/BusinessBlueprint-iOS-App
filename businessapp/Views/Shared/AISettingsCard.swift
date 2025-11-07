import SwiftUI

struct AISettingsCard: View {
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "GOOGLE_AI_API_KEY") ?? ""
    @State private var model: String = UserDefaults.standard.string(forKey: "GOOGLE_AI_MODEL") ?? Config.googleAIModel
    @State private var testStatus: String = ""
    @State private var isTesting = false
    
    var body: some View {
        ModernCard(padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(AppColors.primary)
                    Text("Google AI Configuration")
                        .font(.headline)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("Enter Google AI API Key", text: $apiKey)
                        .textFieldStyle(AppTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("gemini-2.5-flash", text: $model)
                        .textFieldStyle(AppTextFieldStyle())
                }
                
                HStack(spacing: 12) {
                    Button("Save") {
                        UserDefaults.standard.setValue(apiKey, forKey: "GOOGLE_AI_API_KEY")
                        UserDefaults.standard.setValue(model, forKey: "GOOGLE_AI_MODEL")
                        testStatus = "Saved."
                        HapticManager.shared.trigger(.success)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button(isTesting ? "Testing..." : "Test AI") {
                        isTesting = true
                        testStatus = ""
                        GoogleAIService.shared.makeAIRequest(prompt: "Reply with the single word: PONG") { result in
                            DispatchQueue.main.async {
                                isTesting = false
                                switch result {
                                case .success(let text):
                                    testStatus = text.uppercased().contains("PONG") ? "AI OK" : "Unexpected response"
                                case .failure(let error):
                                    testStatus = error.localizedDescription
                                }
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(isLoading: isTesting))
                }
                
                if !testStatus.isEmpty {
                    Text(testStatus)
                        .font(.caption)
                        .foregroundColor(testStatus == "AI OK" ? AppColors.success : .red)
                }
            }
        }
    }
}
