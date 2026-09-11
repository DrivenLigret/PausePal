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
    @Published var weeklyBudget = ""
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
            if weeklyBudget.isEmpty, let goal = journal.weeklyGoal {
                weeklyBudget = String(goal.budgetMinutes)
            }
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
    func startBreak(_ activity: RestorativeActivity) {
        guard ready else { return }
        notice = nil
        do {
            let useCase = StartHealthyBreakUseCase(repository: repository)
            journal = try useCase.execute(activity: activity)
            notice = "Break started."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    func completeBreak(_ id: UUID) {
        guard ready else { return }
        notice = nil
        do {
            let useCase = CompleteHealthyBreakUseCase(repository: repository)
            journal = try useCase.execute(breakID: id)
            notice = "Break completed."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    func cancelBreak(_ id: UUID) {
        guard ready else { return }
        notice = nil
        do {
            let useCase = CancelHealthyBreakUseCase(repository: repository)
            journal = try useCase.execute(breakID: id)
            notice = "Break cancelled."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    func saveGoal() {
        guard ready else { return }
        notice = nil
        let input = weeklyBudget.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let minutes = Int(input) else {
            errorMessage = SetWeeklyViewingGoalUseCase.Failure.invalidBudget.localizedDescription
            return
        }
        do {
            let useCase = SetWeeklyViewingGoalUseCase(repository: repository)
            journal = try useCase.execute(budgetMinutes: minutes)
            notice = "Weekly budget saved."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
