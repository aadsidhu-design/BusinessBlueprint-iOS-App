import Foundation
import Combine
import FirebaseCrashlytics

/// Central store that keeps the user's quiz profile and generated business plans in sync
/// across the entire application. Persists lightweight state in `UserDefaults` so the
/// experience survives app restarts without requiring a backend.
final class BusinessPlanStore: ObservableObject {
    // MARK: - Published State
    @Published private(set) var businessIdeas: [BusinessIdea] = []
    @Published var selectedIdeaID: String? {
        didSet { persistSelectedIdeaID() }
    }
    @Published var userProfile: UserProfile? {
        didSet { persistProfile() }
    }
    @Published var quizCompleted: Bool {
        didSet {
            if quizCompleted {
                UserDefaults.standard.set(true, forKey: Keys.quizCompleted)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.quizCompleted)
            }
        }
    }
    @Published var isSyncing = false
    @Published var lastSyncError: String?
    
    // MARK: - Private Properties
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let firebase = FirebaseService.shared
    private var currentUserId: String?
    
    private enum Keys {
        static let businessIdeas = "businessIdeasData"
        static let userProfile = "userProfileData"
        static let selectedIdeaID = "selectedBusinessIdeaID"
        static let quizCompleted = "hasCompletedOnboarding"
    }
    
    // MARK: - Lifecycle
    init() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
        
        self.quizCompleted = UserDefaults.standard.bool(forKey: Keys.quizCompleted)
        self.selectedIdeaID = UserDefaults.standard.string(forKey: Keys.selectedIdeaID)
        
        loadPersistedProfile()
        loadPersistedIdeas()
        ensureSelectionIsValid()
    }
    
    // MARK: - Derived Data
    var selectedBusinessIdea: BusinessIdea? {
        if let selectedIdeaID,
           let idea = businessIdeas.first(where: { $0.id == selectedIdeaID }) {
            return idea
        }
        return businessIdeas.first
    }
    
    // MARK: - Public API
    func applyQuizResults(profile: UserProfile, ideas: [BusinessIdea]) {
        userProfile = profile
        setBusinessIdeas(ideas)
        selectedIdeaID = ideas.first?.id
        quizCompleted = true
        currentUserId = profile.id
        Task {
            await syncProfileAndIdeas()
        }
    }
    
    func setBusinessIdeas(_ ideas: [BusinessIdea]) {
        businessIdeas = ideas
        persistIdeas()
        ensureSelectionIsValid()
        Task {
            await pushIdeasToRemote()
        }
    }
    
    func updateIdea(_ idea: BusinessIdea) {
        if let index = businessIdeas.firstIndex(where: { $0.id == idea.id }) {
            businessIdeas[index] = idea
        } else {
            businessIdeas.insert(idea, at: 0)
        }
        persistIdeas()
        ensureSelectionIsValid()
        Task {
            await pushIdeasToRemote()
        }
    }
    
    func updateProgress(for ideaId: String, progress: Int) {
        guard let index = businessIdeas.firstIndex(where: { $0.id == ideaId }) else { return }
        businessIdeas[index].progress = progress
        persistIdeas()
        Task {
            guard let userId = currentUserId else { return }
            try? await firebase.updateBusinessIdeaProgress(userId: userId, ideaId: ideaId, progress: progress)
        }
    }
    
    func markIdeaSaved(_ ideaId: String, saved: Bool = true) {
        guard let index = businessIdeas.firstIndex(where: { $0.id == ideaId }) else { return }
        businessIdeas[index].saved = saved
        persistIdeas()
        Task {
            guard let userId = currentUserId else { return }
            try? await firebase.saveBusinessIdea(businessIdeas[index], userId: userId)
        }
    }
    
    func selectIdea(_ idea: BusinessIdea?) {
        if let idea {
            HapticManager.shared.doubleTap()
            
            selectedIdeaID = idea.id
            
            // Track idea selection event
            UserContextManager.shared.trackEvent(.ideaSelected, context: [
                "ideaId": idea.id,
                "ideaTitle": idea.title,
                "ideaCategory": idea.category,
                "ideaDifficulty": idea.difficulty,
                "estimatedRevenue": idea.estimatedRevenue,
                "timeToLaunch": idea.timeToLaunch
            ])
        } else {
            selectedIdeaID = businessIdeas.first?.id
        }
    }
    
    func resetOnboarding() {
        quizCompleted = false
        selectedIdeaID = nil
        businessIdeas = []
        persistIdeas(clear: true)
        userProfile = nil
        persistProfile(clear: true)
        currentUserId = nil
    }

    // MARK: - Remote Sync
    @MainActor
    func attachUser(userId: String) {
        currentUserId = userId
        isSyncing = true
        lastSyncError = nil
        Task {
            await loadRemoteState()
        }
    }
    
    // MARK: - Persistence
    private func persistIdeas(clear: Bool = false) {
        if clear || businessIdeas.isEmpty {
            UserDefaults.standard.removeObject(forKey: Keys.businessIdeas)
            return
        }
        if let data = try? encoder.encode(businessIdeas) {
            UserDefaults.standard.set(data, forKey: Keys.businessIdeas)
        }
    }
    
    private func persistProfile(clear: Bool = false) {
        if clear || userProfile == nil {
            UserDefaults.standard.removeObject(forKey: Keys.userProfile)
            return
        }
        guard let profile = userProfile,
              let data = try? encoder.encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: Keys.userProfile)
    }
    
    private func persistSelectedIdeaID() {
        if let selectedIdeaID {
            UserDefaults.standard.set(selectedIdeaID, forKey: Keys.selectedIdeaID)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.selectedIdeaID)
        }
    }
    
    private func loadPersistedIdeas() {
        guard let data = UserDefaults.standard.data(forKey: Keys.businessIdeas),
              let ideas = try? decoder.decode([BusinessIdea].self, from: data) else {
            businessIdeas = []
            return
        }
        businessIdeas = ideas
    }
    
    private func loadPersistedProfile() {
        guard let data = UserDefaults.standard.data(forKey: Keys.userProfile),
              let profile = try? decoder.decode(UserProfile.self, from: data) else {
            userProfile = nil
            return
        }
        userProfile = profile
    }
    
    private func ensureSelectionIsValid() {
        if let selectedIdeaID,
           !businessIdeas.contains(where: { $0.id == selectedIdeaID }) {
            self.selectedIdeaID = businessIdeas.first?.id
        } else if selectedIdeaID == nil {
            self.selectedIdeaID = businessIdeas.first?.id
        }
    }

    private func loadRemoteState() async {
        guard let userId = currentUserId else {
            await MainActor.run {
                self.isSyncing = false
            }
            return
        }
        do {
            let profile = try await firebase.fetchUserProfile(userId: userId)
            let ideas = try await firebase.fetchBusinessIdeas(userId: userId)
            await MainActor.run {
                self.userProfile = profile
                self.businessIdeas = ideas
                self.ensureSelectionIsValid()
                self.persistIdeas()
                self.persistProfile()
                self.isSyncing = false
            }
        } catch {
            Crashlytics.crashlytics().record(error: error)
            await MainActor.run {
                self.lastSyncError = error.localizedDescription
                self.isSyncing = false
            }
        }
    }

    private func syncProfileAndIdeas() async {
        guard (currentUserId ?? userProfile?.id) != nil else { return }
        do {
            if let profile = userProfile {
                try await firebase.saveUserProfile(profile)
            }
            await pushIdeasToRemote()
        } catch {
            Crashlytics.crashlytics().record(error: error)
        }
    }

    private func pushIdeasToRemote() async {
        guard let userId = currentUserId ?? userProfile?.id else { return }
        do {
            for idea in businessIdeas {
                try await firebase.saveBusinessIdea(idea, userId: userId)
            }
        } catch {
            Crashlytics.crashlytics().record(error: error)
        }
    }
}
