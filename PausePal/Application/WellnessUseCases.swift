import Foundation

private let journalRecovery = "Your journal could not be updated. Your change has not been recorded. Check device storage, then retry."

struct RecordViewingSessionUseCase {
    let repository: WellnessJournalRepository
    enum Failure: Error, LocalizedError, Equatable {
        case invalidDuration, futureEnd, duplicateRecord, journalUnavailable
        var errorDescription: String? {
            switch self {
            case .invalidDuration: return "Enter a whole number from 1 to 1,440 minutes for this viewing record, then save again."
            case .futureEnd: return "This viewing record ends in the future. Choose a time that has already passed."
            case .duplicateRecord: return "A viewing record with this time and duration already exists. Check Today before adding it again."
            case .journalUnavailable: return journalRecovery
            }
        }
    }
    @discardableResult
    func execute(minutes: Int, endedAt: Date, mood: ViewingMood?, now: Date = Date()) throws -> WellnessJournal {
        guard (1...1440).contains(minutes) else { throw Failure.invalidDuration }
        guard endedAt <= now else { throw Failure.futureEnd }
        do {
            var journal = try repository.load()
            for session in journal.viewingSessions {
                if session.endedAt == endedAt && session.durationMinutes == minutes {
                    throw Failure.duplicateRecord
                }
            }
            journal.viewingSessions.append(ViewingSession(id: UUID(), durationMinutes: minutes, endedAt: endedAt, mood: mood))
            try repository.save(journal)
            return journal
        } catch let failure as Failure { throw failure }
        catch { throw Failure.journalUnavailable }
    }
}

struct StartHealthyBreakUseCase {
    let repository: WellnessJournalRepository
    enum Failure: Error, LocalizedError, Equatable {
        case breakAlreadyActive, journalUnavailable
        var errorDescription: String? {
            switch self {
            case .breakAlreadyActive: return "You already have a break in progress. Return to Restore to finish or cancel it first."
            case .journalUnavailable: return journalRecovery
            }
        }
    }
    @discardableResult
    func execute(activity: RestorativeActivity, now: Date = Date()) throws -> WellnessJournal {
        do {
            var journal = try repository.load()
            guard journal.activeBreak == nil else { throw Failure.breakAlreadyActive }
            journal.activeBreak = HealthyBreak(id: UUID(), activity: activity, startedAt: now, completedAt: nil)
            try repository.save(journal)
            return journal
        } catch let failure as Failure { throw failure }
        catch { throw Failure.journalUnavailable }
    }
}
