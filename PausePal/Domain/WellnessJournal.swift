import Foundation

/// An optional feeling recorded after watching short videos.
enum ViewingMood: String, Codable, CaseIterable {
    case relaxed, bored, tired, restless
}

/// A viewing estimate entered by the user, with an optional mood.
struct ViewingSession: Codable, Identifiable, Equatable {
    let id: UUID
    let durationMinutes: Int
    let endedAt: Date
    let mood: ViewingMood?
}

/// An activity the user can choose for a break from viewing.
enum RestorativeActivity: String, Codable, CaseIterable {
    case stretch, drinkWater, outdoorWalk, connectWithFriend

    /// The planned length of the activity in minutes.
    var minutes: Int {
        switch self {
        case .stretch: return 2
        case .drinkWater: return 3
        case .outdoorWalk: return 5
        case .connectWithFriend: return 10
        }
    }
}

/// A chosen break. A nil completion date means it has not been completed.
struct HealthyBreak: Codable, Identifiable, Equatable {
    let id: UUID
    let activity: RestorativeActivity
    let startedAt: Date
    var completedAt: Date?

    /// The earliest time this break can be completed.
    var eligibleCompletionAt: Date {
        startedAt.addingTimeInterval(TimeInterval(activity.minutes * 60))
    }
}

/// The user's chosen weekly viewing budget in minutes.
struct WeeklyViewingGoal: Codable, Equatable {
    let budgetMinutes: Int
    let updatedAt: Date
}

/// The user's viewing records, breaks and optional weekly goal.
struct WellnessJournal: Codable, Equatable {
    var schemaVersion = 1
    var viewingSessions: [ViewingSession] = []
    var activeBreak: HealthyBreak?
    var completedBreaks: [HealthyBreak] = []
    var weeklyGoal: WeeklyViewingGoal?
}

/// Loads and saves the complete journal.
protocol WellnessJournalRepository {
    func load() throws -> WellnessJournal
    func save(_ journal: WellnessJournal) throws
}

/// A failure to read the journal format or save its contents.
enum JournalStorageError: Error, LocalizedError {
    case unreadable, incompatible, saveFailed

    var errorDescription: String? {
        switch self {
        case .unreadable: return "Your saved journal could not be opened. Your records have not been replaced. Close and reopen PausePal, then try again."
        case .incompatible: return "This journal uses a format PausePal cannot open. Keep your app data and try a compatible app version."
        case .saveFailed: return "Your journal could not be saved. Check your device storage, then retry. This change has not been recorded."
        }
    }
}
