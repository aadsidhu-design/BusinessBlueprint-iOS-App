import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics
import FirebaseCrashlytics

// MARK: - Firestore Collection Names
private enum FirestorePath {
    static let users = "users"
    static let businessIdeas = "businessIdeas"
    static let dailyGoals = "dailyGoals"
    static let milestones = "milestones"
    static let reminders = "reminders"
    static let notes = "notes"
    static let journey = "journey"
}

// MARK: - Firebase Service
final class FirebaseService {
    static let shared = FirebaseService()
    
    let auth: Auth
    let firestore: Firestore
    
    private init() {
        auth = Auth.auth()
        firestore = Firestore.firestore()
        let settings = firestore.settings
        settings.cacheSettings = PersistentCacheSettings()
        firestore.settings = settings
    }
    
    // MARK: - Auth Helpers
    func listenToAuthChanges(_ handler: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle {
        auth.addStateDidChangeListener { _, user in
            handler(user)
        }
    }
    
    func removeAuthListener(_ handle: AuthStateDidChangeListenerHandle?) {
        guard let handle else { return }
        auth.removeStateDidChangeListener(handle)
    }
    
    func signUpUser(email: String, password: String) async throws -> String {
        let result = try await auth.createUser(withEmail: email, password: password)
        Analytics.logEvent("sign_up_email", parameters: nil)
        return result.user.uid
    }

    func signUpUser(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let uid = try await signUpUser(email: email, password: password)
                await MainActor.run { completion(.success(uid)) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func signInUser(email: String, password: String) async throws -> String {
        let result = try await auth.signIn(withEmail: email, password: password)
        Analytics.logEvent("login_email", parameters: nil)
        return result.user.uid
    }

    func signInUser(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let uid = try await signInUser(email: email, password: password)
                await MainActor.run { completion(.success(uid)) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func signInAnonymously() async throws -> String {
        let result = try await auth.signInAnonymously()
        Analytics.logEvent("login_anonymous", parameters: nil)
        return result.user.uid
    }

    func signInAnonymously(completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let uid = try await signInAnonymously()
                await MainActor.run { completion(.success(uid)) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func signInWithCredential(_ credential: AuthCredential, provider: String) async throws -> String {
        let result = try await auth.signIn(with: credential)
        Analytics.logEvent("login_\(provider)", parameters: nil)
        return result.user.uid
    }

    func signInWithCredential(_ credential: AuthCredential, provider: String, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let uid = try await signInWithCredential(credential, provider: provider)
                await MainActor.run { completion(.success(uid)) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func signOutUser() throws {
        try auth.signOut()
    }

    func signOutUser(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try signOutUser()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - User Profile
    func saveUserProfile(_ profile: UserProfile) async throws {
        try firestore.collection(FirestorePath.users)
            .document(profile.id)
            .setData(from: profile, merge: true)
    }
    
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        let snapshot = try await firestore.collection(FirestorePath.users).document(userId).getDocument()
        let profile = try snapshot.data(as: UserProfile.self)
        return profile
    }
    
    // MARK: - Business Ideas
    func saveBusinessIdea(_ idea: BusinessIdea, userId: String) async throws {
        try firestore.collection(FirestorePath.users)
            .document(userId)
            .collection(FirestorePath.businessIdeas)
            .document(idea.id)
            .setData(from: idea, merge: true)
    }

    func saveBusinessIdea(_ idea: BusinessIdea, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await saveBusinessIdea(idea, userId: userId)
                await MainActor.run { completion(.success(())) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func fetchBusinessIdeas(userId: String) async throws -> [BusinessIdea] {
        let snapshot = try await firestore.collection(FirestorePath.users)
            .document(userId)
            .collection(FirestorePath.businessIdeas)
            .order(by: "created_at", descending: true)
            .getDocuments()
        return try snapshot.documents.compactMap { document in
            try document.data(as: BusinessIdea.self)
        }
    }

    func fetchBusinessIdeas(userId: String, completion: @escaping (Result<[BusinessIdea], Error>) -> Void) {
        Task {
            do {
                let ideas = try await fetchBusinessIdeas(userId: userId)
                await MainActor.run { completion(.success(ideas)) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func updateBusinessIdeaProgress(userId: String, ideaId: String, progress: Int) async throws {
        try await firestore.collection(FirestorePath.users)
            .document(userId)
            .collection(FirestorePath.businessIdeas)
            .document(ideaId)
            .setData(["progress": progress], merge: true)
    }

    func updateBusinessIdeaProgress(_ ideaId: String, progress: Int, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await updateBusinessIdeaProgress(userId: userId, ideaId: ideaId, progress: progress)
                await MainActor.run { completion(.success(())) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    // MARK: - Daily Goals
    func saveDailyGoal(_ goal: DailyGoal, userId: String) async throws {
        try firestore.collection(FirestorePath.users)
            .document(userId)
            .collection(FirestorePath.dailyGoals)
            .document(goal.id)
            .setData(from: goal, merge: true)
    }

    func saveDailyGoal(_ goal: DailyGoal, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in."])) )
            return
        }
        Task {
            do {
                try await saveDailyGoal(goal, userId: userId)
                await MainActor.run { completion(.success(())) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func fetchDailyGoals(userId: String) async throws -> [DailyGoal] {
        let snapshot = try await firestore.collection(FirestorePath.users)
            .document(userId)
            .collection(FirestorePath.dailyGoals)
            .order(by: "due_date")
            .getDocuments()
        return try snapshot.documents.compactMap { document in
            try document.data(as: DailyGoal.self)
        }
    }

    func fetchDailyGoals(userId: String, completion: @escaping (Result<[DailyGoal], Error>) -> Void) {
        Task {
            do {
                let goals = try await fetchDailyGoals(userId: userId)
                await MainActor.run { completion(.success(goals)) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func toggleGoalCompletion(userId: String, goalId: String, completed: Bool) async throws {
        try await firestore.collection(FirestorePath.users)
            .document(userId)
            .collection(FirestorePath.dailyGoals)
            .document(goalId)
            .updateData(["completed": completed])
    }

    func toggleGoalCompletion(goalId: String, completed: Bool, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await toggleGoalCompletion(userId: userId, goalId: goalId, completed: completed)
                await MainActor.run { completion(.success(())) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    // MARK: - Milestones
    func saveMilestone(_ milestone: Milestone, userId: String) async throws {
        try firestore.collection(FirestorePath.users)
            .document(userId)
            .collection(FirestorePath.milestones)
            .document(milestone.id)
            .setData(from: milestone, merge: true)
    }

    func saveMilestone(_ milestone: Milestone, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in."])) )
            return
        }
        Task {
            do {
                try await saveMilestone(milestone, userId: userId)
                await MainActor.run { completion(.success(())) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func fetchMilestones(userId: String) async throws -> [Milestone] {
        let snapshot = try await firestore.collection(FirestorePath.users)
            .document(userId)
            .collection(FirestorePath.milestones)
            .order(by: "order")
            .getDocuments()
        return try snapshot.documents.compactMap { document in
            try document.data(as: Milestone.self)
        }
    }

    func fetchMilestones(userId: String, completion: @escaping (Result<[Milestone], Error>) -> Void) {
        Task {
            do {
                let milestones = try await fetchMilestones(userId: userId)
                await MainActor.run { completion(.success(milestones)) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func toggleMilestoneCompletion(userId: String, milestoneId: String, completed: Bool) async throws {
        try await firestore.collection(FirestorePath.users)
            .document(userId)
            .collection(FirestorePath.milestones)
            .document(milestoneId)
            .updateData(["completed": completed])
    }

    func toggleMilestoneCompletion(milestoneId: String, completed: Bool, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await toggleMilestoneCompletion(userId: userId, milestoneId: milestoneId, completed: completed)
                await MainActor.run { completion(.success(())) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    // MARK: - Reminders & Notes
    func saveReminder(_ reminder: AppReminder, userId: String) async throws {
        try firestore.collection(FirestorePath.users)
            .document(userId)
            .collection(FirestorePath.reminders)
            .document(reminder.id)
            .setData(from: reminder, merge: true)
    }

    func saveReminder(_ reminder: AppReminder, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in."])) )
            return
        }
        Task {
            do {
                try await saveReminder(reminder, userId: userId)
                await MainActor.run { completion(.success(())) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func fetchReminders(userId: String) async throws -> [AppReminder] {
        let snapshot = try await firestore.collection(FirestorePath.users)
            .document(userId)
            .collection(FirestorePath.reminders)
            .order(by: "scheduledDate")
            .getDocuments()
        return try snapshot.documents.compactMap { document in
            try document.data(as: AppReminder.self)
        }
    }

    func fetchReminders(userId: String, completion: @escaping (Result<[AppReminder], Error>) -> Void) {
        Task {
            do {
                let reminders = try await fetchReminders(userId: userId)
                await MainActor.run { completion(.success(reminders)) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func saveNote(_ note: ProgressNote, userId: String) async throws {
        try firestore.collection(FirestorePath.users)
            .document(userId)
            .collection(FirestorePath.notes)
            .document(note.id)
            .setData(from: note, merge: true)
    }

    func saveNote(_ note: ProgressNote, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in."])) )
            return
        }
        Task {
            do {
                try await saveNote(note, userId: userId)
                await MainActor.run { completion(.success(())) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func fetchNotes(userId: String) async throws -> [ProgressNote] {
        let snapshot = try await firestore.collection(FirestorePath.users)
            .document(userId)
            .collection(FirestorePath.notes)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return try snapshot.documents.compactMap { document in
            try document.data(as: ProgressNote.self)
        }
    }

    func fetchNotes(userId: String, completion: @escaping (Result<[ProgressNote], Error>) -> Void) {
        Task {
            do {
                let notes = try await fetchNotes(userId: userId)
                await MainActor.run { completion(.success(notes)) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    // MARK: - Journey Progress
    func saveJourney(islands: [Island], progress: JourneyProgress, userId: String) async throws {
        let batch = firestore.batch()
        let journeyRef = firestore.collection(FirestorePath.users).document(userId).collection(FirestorePath.journey).document("progress")
        try batch.setData(from: progress, forDocument: journeyRef, merge: true)
        let islandsCollection = journeyRef.collection("islands")
        for (index, island) in islands.enumerated() {
            var mutableIsland = island
            mutableIsland.order = index
            let ref = islandsCollection.document(mutableIsland.id)
            try batch.setData(from: mutableIsland, forDocument: ref, merge: true)
        }
        try await batch.commit()
    }

    func saveJourney(islands: [Island], progress: JourneyProgress, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await saveJourney(islands: islands, progress: progress, userId: userId)
                await MainActor.run { completion(.success(())) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
    
    func fetchJourney(userId: String) async throws -> (progress: JourneyProgress, islands: [Island]) {
        let journeyRef = firestore.collection(FirestorePath.users).document(userId).collection(FirestorePath.journey).document("progress")
        let progressSnapshot = try await journeyRef.getDocument()
        let progress = try progressSnapshot.data(as: JourneyProgress.self)
        let islandsSnapshot = try await journeyRef.collection("islands").order(by: "order").getDocuments()
        let islands: [Island] = try islandsSnapshot.documents.compactMap { document in
            try document.data(as: Island.self)
        }
        return (progress, islands)
    }

    func fetchJourney(userId: String, completion: @escaping (Result<(JourneyProgress, [Island]), Error>) -> Void) {
        Task {
            do {
                let result = try await fetchJourney(userId: userId)
                await MainActor.run { completion(.success((result.progress, result.islands))) }
            } catch {
                await MainActor.run { completion(.failure(error)) }
            }
        }
    }
}
