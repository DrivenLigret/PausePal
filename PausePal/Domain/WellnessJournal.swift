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
}

/// The user's chosen weekly viewing budget in minutes.
struct WeeklyViewingGoal: Codable, Equatable {
    let budgetMinutes: Int
    let updatedAt: Date
}

/// The user's viewing records, breaks and optional weekly goal.
struct WellnessJournal: Codable, Equatable {
    var viewingSessions: [ViewingSession] = []
    var activeBreak: HealthyBreak?
    var completedBreaks: [HealthyBreak] = []
    var weeklyGoal: WeeklyViewingGoal?
}
