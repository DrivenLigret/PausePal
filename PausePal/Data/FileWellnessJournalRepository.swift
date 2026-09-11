import Foundation

final class FileWellnessJournalRepository: WellnessJournalRepository {
    private let fileURL: URL
    init(fileURL: URL) { self.fileURL = fileURL }
    static func defaultURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PausePal", isDirectory: true)
            .appendingPathComponent("wellness-journal.json")
    }
    func load() throws -> WellnessJournal {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return WellnessJournal() }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let journal = try decoder.decode(WellnessJournal.self, from: data)
            guard journal.schemaVersion == 1 else { throw JournalStorageError.incompatible }
            try validateJournal(journal)
            return journal
        } catch let failure as JournalStorageError { throw failure }
        catch { throw JournalStorageError.unreadable }
    }
    private func validateJournal(_ journal: WellnessJournal) throws {
        var sessionIDs: [UUID] = []
        for session in journal.viewingSessions {
            if sessionIDs.contains(session.id) { throw JournalStorageError.unreadable }
            if session.durationMinutes < 1 || session.durationMinutes > 1440 {
                throw JournalStorageError.unreadable
            }
            sessionIDs.append(session.id)
        }

        var breakIDs: [UUID] = []
        for healthyBreak in journal.completedBreaks {
            if breakIDs.contains(healthyBreak.id) { throw JournalStorageError.unreadable }
            guard let completed = healthyBreak.completedAt else {
                throw JournalStorageError.unreadable
            }
            if completed < healthyBreak.eligibleCompletionAt { throw JournalStorageError.unreadable }
            breakIDs.append(healthyBreak.id)
        }

        if let active = journal.activeBreak {
            if active.completedAt != nil { throw JournalStorageError.unreadable }
            if breakIDs.contains(active.id) { throw JournalStorageError.unreadable }
        }
        if let goal = journal.weeklyGoal {
            if goal.budgetMinutes < 1 || goal.budgetMinutes > 10080 {
                throw JournalStorageError.unreadable
            }
        }
    }

    func save(_ journal: WellnessJournal) throws {
        do {
            var directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try directory.setResourceValues(values)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(journal).write(to: fileURL, options: .atomic)
        } catch { throw JournalStorageError.saveFailed }
    }
}
