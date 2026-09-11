import SwiftUI

@MainActor
final class WellnessViewModel: ObservableObject {
    @Published private(set) var journal = WellnessJournal()
    @Published private(set) var ready = false
    @Published var selectedTab = 0
    @Published var showError = false
    @Published var errorMessage: String? {
        didSet { showError = errorMessage != nil }
    }
    @Published var notice: String?
    @Published var viewingMinutes = ""
    @Published var viewingEndedAt = Date()
    @Published var selectedMood: ViewingMood?
    private let repository: WellnessJournalRepository

    init(repository: WellnessJournalRepository) {
        self.repository = repository
        reload()
    }
    func reload() {
        do {
            journal = try repository.load()
            ready = true
            errorMessage = nil
        } catch {
            ready = false
            errorMessage = error.localizedDescription
        }
    }
    func recordViewing() {
        guard ready else { return }
        notice = nil
        guard let minutes = Int(viewingMinutes.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = RecordViewingSessionUseCase.Failure.invalidDuration.localizedDescription
            return
        }
        do {
            let useCase = RecordViewingSessionUseCase(repository: repository)
            journal = try useCase.execute(minutes: minutes, endedAt: viewingEndedAt, mood: selectedMood)
            viewingMinutes = ""
            selectedMood = nil
            viewingEndedAt = Date()
            notice = "Viewing record saved."
            selectedTab = 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
