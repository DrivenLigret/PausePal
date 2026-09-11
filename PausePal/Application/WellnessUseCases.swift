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

struct CompleteHealthyBreakUseCase {
    let repository: WellnessJournalRepository
    enum Failure: Error, LocalizedError, Equatable {
        case noActiveBreak, breakChanged, tooEarly(secondsRemaining: Int), clockMovedBackward, journalUnavailable
        var errorDescription: String? {
            switch self {
            case .noActiveBreak: return "There is no break waiting to be completed. Check your completed breaks in Reflect, or choose a new activity."
            case .breakChanged: return "That break is no longer active. Return to Restore and check your current activity."
            case .tooEarly(let seconds): return "Your break has \(seconds) seconds left. Keep resting, then tap Complete break again."
            case .clockMovedBackward: return "Your device time is earlier than when this break started. Check your date and time settings, or cancel this break and start again."
            case .journalUnavailable: return journalRecovery
            }
        }
    }
    @discardableResult
    func execute(breakID: UUID, now: Date = Date()) throws -> WellnessJournal {
        do {
            var journal = try repository.load()
            guard var active = journal.activeBreak else { throw Failure.noActiveBreak }
            guard active.id == breakID else { throw Failure.breakChanged }
            guard now >= active.startedAt else { throw Failure.clockMovedBackward }
            let remaining = active.remainingSeconds(at: now)
            guard remaining == 0 else { throw Failure.tooEarly(secondsRemaining: remaining) }
            active.completedAt = now
            journal.completedBreaks.append(active)
            journal.activeBreak = nil
            try repository.save(journal)
            return journal
        } catch let failure as Failure { throw failure }
        catch { throw Failure.journalUnavailable }
    }
}

struct CancelHealthyBreakUseCase {
    let repository: WellnessJournalRepository
    enum Failure: Error, LocalizedError, Equatable {
        case noMatchingBreak, journalUnavailable
        var errorDescription: String? {
            switch self {
            case .noMatchingBreak: return "That break is no longer active. Return to Restore to check your current activity."
            case .journalUnavailable: return journalRecovery
            }
        }
    }
    @discardableResult
    func execute(breakID: UUID) throws -> WellnessJournal {
        do {
            var journal = try repository.load()
            guard journal.activeBreak?.id == breakID else { throw Failure.noMatchingBreak }
            journal.activeBreak = nil
            try repository.save(journal)
            return journal
        } catch let failure as Failure { throw failure }
        catch { throw Failure.journalUnavailable }
    }
}
