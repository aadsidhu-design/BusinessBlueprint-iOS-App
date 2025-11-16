import SwiftUI
import AVFoundation

struct NewAIAssistantView: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @StateObject private var contextManager = IntelligentContextManager.shared
    private let aiService = GoogleAIService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var messages: [AssistantMessage] = []
    @State private var inputText = ""
    @State private var isProcessing = false
    @FocusState private var isFocused: Bool
    @State private var showImagePicker = false
    @State private var showFilePicker = false
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var attachments: [AttachmentData] = []
    
    var body: some View {
        ZStack {
            // Full screen background gradient — fills screen for a full-page chat
            AppColors.backgroundGradient
                .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Text("AI Assistant")
                        .font(.title2.bold())
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if messages.isEmpty {
                                VStack(spacing: 20) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 50, weight: .semibold))
                                        .foregroundColor(.gray.opacity(0.3))
                                    
                                    VStack(spacing: 8) {
                                        Text("What can I help you with?")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.black)
                                        
                                        Text("Ask me anything about your business")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(40)
                            }
                            
                            ForEach(messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            if isProcessing {
                                TypingIndicatorView()
                            }
                        }
                        .padding(20)
                    }
                    .onChange(of: messages.count) {
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 0)
                
                // Attachments preview
                if !attachments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(attachments) { attachment in
                                AttachmentPreviewView(attachment: attachment) {
                                    attachments.removeAll { $0.id == attachment.id }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.05))
                }
                
                // Animated Bottom Bar with rounded edges
                let fillColor = Color.gray.opacity(0.15)
                let mintGreen = Color(red: 0.0, green: 0.8, blue: 0.6)
                AnimatedBottomBar(
                    hint: "Ask anything...",
                    tint: mintGreen,
                    text: $inputText,
                    isFocused: $isFocused
                ) {
                    Button {
                        showFilePicker = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.medium)
                            .foregroundColor(Color.primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(fillColor, in: .circle)
                    }
                    
                    Button {
                        showImagePicker = true
                    } label: {
                        Image(systemName: "photo.fill")
                            .foregroundStyle(Color.primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(fillColor, in: .circle)
                    }
                    
                    Button {
                        toggleRecording()
                    } label: {
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .foregroundColor(isRecording ? .red : .primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(fillColor, in: .circle)
                    }
                } trailingAction: {
                    Button {
                        if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                            sendMessage()
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                (!inputText.trimmingCharacters(in: .whitespaces).isEmpty ? mintGreen : Color.gray.opacity(0.3)).gradient,
                                in: .circle
                            )
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                } mainAction: {
                    EmptyView()
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 8)
            .overlay(
                // small non-sensitive status indicator: shows whether a key is present
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Text(Config.googleAIKey.isEmpty ? "API: Not configured" : "API: Configured")
                            Text("(")
                            Text(Config.googleAIKey.isEmpty ? "source: none" : "source: \(Config.googleAIKeySource())")
                                .bold()
                                .foregroundColor(AppColors.primary)
                            Text(")")
                        }
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(8)
                            .padding(.trailing, 12)
                            .padding(.top, 12)
                    }
                    Spacer()
                }
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker { image in
                attachImage(image)
            }
        }
        .sheet(isPresented: $showFilePicker) {
            DocumentPicker { url in
                attachFile(url)
            }
        }
        .onAppear {
            // Quick debug feedback: show whether API key is present (without printing the key)
            print("🔑 NewAIAssistantView: API Key present? \(!Config.googleAIKey.isEmpty)")
            print("🌐 Model in config: \(Config.googleAIModel)")
        }
    }
    
    private func attachImage(_ image: UIImage) {
        let attachment = AttachmentData(type: .image, data: image)
        attachments.append(attachment)
    }
    
    private func attachFile(_ url: URL) {
        if let data = try? Data(contentsOf: url) {
            let attachment = AttachmentData(type: .file, data: data, fileName: url.lastPathComponent)
            attachments.append(attachment)
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            audioRecorder?.stop()
            isRecording = false
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .default)
        try? audioSession.setActive(true)
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentPath.appendingPathComponent("recording.wav")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try? AVAudioRecorder(url: audioURL, settings: settings)
        audioRecorder?.record()
        isRecording = true
    }
    
    private func sendMessage() {
        let messageText = inputText.trimmingCharacters(in: .whitespaces)
        guard !messageText.isEmpty || !attachments.isEmpty else { return }
        
        let userMessage = AssistantMessage(
            content: messageText,
            isFromUser: true,
            attachments: attachments
        )
        messages.append(userMessage)
        inputText = ""
        attachments = []
        isProcessing = true
        
        contextManager.recordAction(
            .aiConversation(message: messageText, response: ""),
            metadata: ["type": "assistant_chat"]
        )
        
        // Simple test prompt first
        let prompt = "You are a helpful business assistant. The user said: '\(messageText)'. Please provide a helpful, conversational response."
        
        print("🤖 Sending AI request with prompt: \(prompt)")
        print("🔑 API Key configured: \(!Config.googleAIKey.isEmpty)")
        print("🌐 Model: \(Config.googleAIModel)")
        
        aiService.makeAIRequest(prompt: prompt) { result in
            Task { @MainActor in
                isProcessing = false
                
                switch result {
                case .success(let response):
                    print("✅ AI Response received: \(response)")
                    let aiMessage = AssistantMessage(content: response, isFromUser: false)
                    messages.append(aiMessage)
                    
                    contextManager.recordAction(
                        .aiConversation(message: messageText, response: response),
                        metadata: ["type": "assistant_response"]
                    )
                    
                case .failure(let error):
                    print("❌ AI Error: \(error)")
                    print("❌ Error description: \(error.localizedDescription)")
                    
                    let errorMessage = AssistantMessage(
                        content: "Error: \(error.localizedDescription)\n\nAPI Key: \(Config.googleAIKey.isEmpty ? "Missing" : "Present")\nModel: \(Config.googleAIModel)",
                        isFromUser: false
                    )
                    messages.append(errorMessage)
                }
            }
        }
    }
    
    private func buildContextPrompt() -> String {
        var context = "Context about the user:\n\n"
        
        if !businessPlanStore.businessIdeas.isEmpty {
            context += "Business Ideas:\n"
            for idea in businessPlanStore.businessIdeas.prefix(3) {
                context += "- \(idea.title): \(idea.description) (Progress: \(Int(idea.progress * 100))%)\n"
            }
            context += "\n"
        }
        
        if let selected = businessPlanStore.selectedBusinessIdea {
            context += "Currently working on: \(selected.title)\n"
            context += "Description: \(selected.description)\n\n"
        }
        
        let insights = contextManager.userInsights
        if !insights.businessFocusAreas.isEmpty {
            context += "Focus areas: \(insights.businessFocusAreas.joined(separator: ", "))\n"
        }
        
        let recentActions = contextManager.contextEntries.suffix(5)
        if !recentActions.isEmpty {
            context += "\nRecent activity:\n"
            for entry in recentActions {
                context += "- \(entry.action.actionType)\n"
            }
        }
        
        return context
    }
}

// Message and Attachment structs
struct AssistantMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp = Date()
    var attachments: [AttachmentData] = []
}

struct AttachmentData: Identifiable {
    let id = UUID()
    enum AttachmentType {
        case image, file, audio
    }
    let type: AttachmentType
    let data: Any
    var fileName: String = ""
}

// Reuse existing message views from AIAssistantSheet
struct MessageBubbleView: View {
    let message: AssistantMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    if !message.attachments.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(message.attachments) { attachment in
                                Image(systemName: "paperclip.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.bottom, 4)
                    }
                    
                    if !message.content.isEmpty {
                        Text(message.content)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.0, green: 0.8, blue: 0.6),
                                        Color(red: 0.0, green: 0.8, blue: 0.6).opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(18)
                    }
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                        Text("AI Assistant")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.6))
                    
                    if !message.content.isEmpty {
                        Text(message.content)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.gray.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
    }
}

struct TypingIndicatorView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.gray.opacity(0.1))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            isAnimating = true
        }
    }
}

struct AttachmentPreviewView: View {
    let attachment: AttachmentData
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .semibold))
            
            Text(displayName)
                .font(.system(size: 12, weight: .regular))
            
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    var iconName: String {
        switch attachment.type {
        case .image: return "photo.fill"
        case .file: return "doc.fill"
        case .audio: return "mic.fill"
        }
    }
    
    var displayName: String {
        switch attachment.type {
        case .image: return "Image"
        case .file: return attachment.fileName.isEmpty ? "File" : attachment.fileName
        case .audio: return "Audio"
        }
    }
}

// Reuse ImagePicker and DocumentPicker from AIAssistantSheet
struct ImagePicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var onFilePicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .plainText])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onFilePicked(url)
            }
        }
    }
}

#Preview {
    NewAIAssistantView()
        .environmentObject(BusinessPlanStore())
}

