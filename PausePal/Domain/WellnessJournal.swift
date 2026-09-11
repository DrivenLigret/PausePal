import Foundation

/// An optional feeling recorded after watching short videos.
enum ViewingMood: String, Codable, CaseIterable, Identifiable {
    case relaxed, bored, tired, restless

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .relaxed: return "leaf"
        case .bored: return "cloud"
        case .tired: return "moon"
        case .restless: return "wind"
        }
    }
}

/// A viewing estimate entered by the user, with an optional mood.
///
/// Each record must contain 1–1,440 minutes and cannot end in the future when added.
/// The same end time and duration cannot be recorded twice.
struct ViewingSession: Codable, Identifiable, Equatable {
    let id: UUID
    let durationMinutes: Int
    let endedAt: Date
    let mood: ViewingMood?
}

/// An activity the user can choose for a break from viewing.
///
/// Stretching, drinking water, walking and connecting with a friend take
/// 2, 3, 5 and 10 minutes respectively before completion is allowed.
enum RestorativeActivity: String, Codable, CaseIterable, Identifiable {
    case stretch, drinkWater, outdoorWalk, connectWithFriend
    var id: String { rawValue }
    var title: String {
        switch self {
        case .stretch: return "Stretch gently"
        case .drinkWater: return "Get a drink of water"
        case .outdoorWalk: return "Take a short walk"
        case .connectWithFriend: return "Connect with a friend"
        }
    }
    var minutes: Int {
        switch self {
        case .stretch: return 2
        case .drinkWater: return 3
        case .outdoorWalk: return 5
        case .connectWithFriend: return 10
        }
    }
    var symbol: String {
        switch self {
        case .stretch: return "figure.flexibility"
        case .drinkWater: return "drop"
        case .outdoorWalk: return "figure.walk"
        case .connectWithFriend: return "person.2"
        }
    }
    var detail: String {
        switch self {
        case .stretch: return "Move at a pace that feels comfortable."
        case .drinkWater: return "Step away from your screen for a moment."
        case .outdoorWalk: return "Choose a safe, comfortable place nearby."
        case .connectWithFriend: return "Have a conversation away from the feed."
        }
    }
}

/// A break with a countdown that determines when its required rest time has elapsed.
protocol TimedWellnessBreak {
    func remainingSeconds(at date: Date) -> Int
}

/// A chosen activity break, timed from its recorded start.
///
/// Completion is allowed only after the activity's full duration has elapsed.
/// An unfinished break has no completion date. Cancelling it does not count as completion.
struct HealthyBreak: Codable, Identifiable, Equatable, TimedWellnessBreak {
    let id: UUID
    let activity: RestorativeActivity
    let startedAt: Date
    var completedAt: Date?

    /// The earliest time this break can be completed.
    var eligibleCompletionAt: Date {
        startedAt.addingTimeInterval(TimeInterval(activity.minutes * 60))
    }

    /// The remaining whole seconds, rounded up and never below zero.
    func remainingSeconds(at date: Date) -> Int {
        let seconds = eligibleCompletionAt.timeIntervalSince(date)
        if seconds <= 0 { return 0 }
        return Int(ceil(seconds))
    }
}

/// The user's chosen weekly viewing budget in minutes.
///
/// The budget must be 1–10,080 minutes for a seven-day window.
/// Saving a new budget replaces the previous one.
struct WeeklyViewingGoal: Codable, Equatable {
    let budgetMinutes: Int
    let updatedAt: Date
}

/// The user's viewing records, breaks and optional weekly goal.
///
/// At most one break may be active, and it must be unfinished.
/// A completed break cannot also be active or appear twice in the completed records.
/// Viewing records must have unique identifiers.
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
