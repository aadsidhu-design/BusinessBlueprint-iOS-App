import Foundation
import SwiftUI
import Combine

class BusinessIdeaViewModel: ObservableObject {
    @Published var businessIdeas: [BusinessIdea] = [] {
        didSet {
            guard !isSyncingFromStore else { return }
            store?.setBusinessIdeas(businessIdeas)
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedIdea: BusinessIdea? {
        didSet {
            guard !isSyncingFromStore else { return }
            store?.selectIdea(selectedIdea)
        }
    }
    
    private var userId: String?
    private var store: BusinessPlanStore?
    private var cancellables = Set<AnyCancellable>()
    private var isSyncingFromStore = false
    
    init(userId: String? = nil) {
        self.userId = userId
    }
    
    func attachStore(_ store: BusinessPlanStore) {
        if self.store === store { return }
        self.store = store
        userId = userId ?? store.userProfile?.id
        
        cancellables.removeAll()
        
        store.$businessIdeas
            .receive(on: RunLoop.main)
            .sink { [weak self] ideas in
                self?.syncIdeasFromStore(ideas)
            }
            .store(in: &cancellables)
        
        store.$selectedIdeaID
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncSelectedIdeaFromStore()
            }
            .store(in: &cancellables)
        
        store.$userProfile
            .receive(on: RunLoop.main)
            .sink { [weak self] profile in
                if let profile { self?.userId = profile.id }
            }
            .store(in: &cancellables)
        
        syncIdeasFromStore(store.businessIdeas)
        syncSelectedIdeaFromStore()
    }
    
    private func syncIdeasFromStore(_ ideas: [BusinessIdea]) {
        isSyncingFromStore = true
        businessIdeas = ideas
        isSyncingFromStore = false
    }
    
    private func syncSelectedIdeaFromStore() {
        guard let store else { return }
        isSyncingFromStore = true
        selectedIdea = store.selectedBusinessIdea
        isSyncingFromStore = false
    }
    
    func generateIdeas(skills: [String], personality: [String], interests: [String]) {
        isLoading = true
        errorMessage = nil
        
        GoogleAIService.shared.generateBusinessIdeas(
            skills: skills,
            personality: personality,
            interests: interests
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let ideas):
                    self.businessIdeas = ideas
                    self.selectedIdea = ideas.first
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func saveIdea(_ idea: BusinessIdea) {
        FirebaseService.shared.saveBusinessIdea(idea) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    if let index = self.businessIdeas.firstIndex(where: { $0.id == idea.id }) {
                        let updatedIdea = self.businessIdeas[index].updating(saved: true)
                        self.businessIdeas[index] = updatedIdea
                        self.selectedIdea = updatedIdea
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func fetchIdeas(forceRefresh: Bool = false) {
        if !forceRefresh, let store, !store.businessIdeas.isEmpty {
            businessIdeas = store.businessIdeas
            selectedIdea = store.selectedBusinessIdea
            return
        }
        guard let userId = userId ?? store?.userProfile?.id else { return }
        isLoading = true
        
        FirebaseService.shared.fetchBusinessIdeas(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let ideas):
                    if !ideas.isEmpty {
                        self.businessIdeas = ideas
                        self.selectedIdea = ideas.first
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func getAISuggestions(for idea: BusinessIdea, completion: @escaping (String) -> Void) {
        GoogleAIService.shared.getAISuggestions(businessIdea: idea) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let suggestions):
                    completion(suggestions)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion("Focus on validating demand with quick customer interviews, build a scrappy pilot, and document the learnings each week.")
                }
            }
        }
    }
    
    func updateProgress(ideaId: String, progress: Int) {
        FirebaseService.shared.updateBusinessIdeaProgress(ideaId, progress: progress) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    if let index = self.businessIdeas.firstIndex(where: { $0.id == ideaId }) {
                        let updatedIdea = self.businessIdeas[index].updating(progress: progress)
                        self.businessIdeas[index] = updatedIdea
                        if self.selectedIdea?.id == ideaId {
                            self.selectedIdea = updatedIdea
                        }
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func selectIdea(_ idea: BusinessIdea) {
        selectedIdea = idea
    }
}
