import Foundation

/// One local calendar day's self-reported viewing. No entries is missing observation, not proof of no use.
struct DailyViewingTotal: Identifiable {
    let date: Date
    let minutes: Int
    let entryCount: Int
    var id: Date { date }
}

/// A read-only seven-day projection, including today and excluding future entries.
/// The previous window is the immediately preceding seven local calendar days.
struct WeeklyReflection {
    let days: [DailyViewingTotal]
    let completedBreakCount: Int
    let previousMinutes: Int
    let previousEntryCount: Int
    let goal: WeeklyViewingGoal?
    var loggedMinutes: Int {
        var total = 0
        for day in days { total += day.minutes }
        return total
    }
    var entryCount: Int {
        var total = 0
        for day in days { total += day.entryCount }
        return total
    }
    var changePercent: Double? {
        guard entryCount > 0, previousEntryCount > 0, previousMinutes > 0 else { return nil }
        return Double(loggedMinutes - previousMinutes) / Double(previousMinutes) * 100
    }
    init(journal: WellnessJournal, now: Date = Date(), calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -6, to: today)!
        let previousStart = calendar.date(byAdding: .day, value: -7, to: start)!
        var dailyTotals: [DailyViewingTotal] = []
        for offset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: offset, to: start)!
            let next = calendar.date(byAdding: .day, value: 1, to: date)!
            var minutes = 0
            var count = 0
            for session in journal.viewingSessions {
                if session.endedAt >= date && session.endedAt < next && session.endedAt <= now {
                    minutes += session.durationMinutes
                    count += 1
                }
            }
            let total = DailyViewingTotal(date: date, minutes: minutes, entryCount: count)
            dailyTotals.append(total)
        }
        days = dailyTotals

        var earlierMinutes = 0
        var earlierCount = 0
        for session in journal.viewingSessions {
            if session.endedAt >= previousStart && session.endedAt < start {
                earlierMinutes += session.durationMinutes
                earlierCount += 1
            }
        }
        previousMinutes = earlierMinutes
        previousEntryCount = earlierCount

        var breakCount = 0
        for healthyBreak in journal.completedBreaks {
            if let completed = healthyBreak.completedAt {
                if completed >= start && completed <= now { breakCount += 1 }
            }
        }
        completedBreakCount = breakCount
        goal = journal.weeklyGoal
    }
}
