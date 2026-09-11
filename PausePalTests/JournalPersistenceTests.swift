import XCTest
import Foundation
#if SWIFT_PACKAGE
@testable import PausePalCore
#endif

final class JournalPersistenceTests: XCTestCase {
    private var directory: URL!
    private var fileURL: URL { directory.appendingPathComponent("journal.json") }
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws {
        if let directory = directory { try FileManager.default.removeItem(at: directory) }
    }
    func test_journal_missingFileStartsEmpty() throws {
        XCTAssertEqual(try FileWellnessJournalRepository(fileURL: fileURL).load(), WellnessJournal())
    }
    func test_journal_roundTripPreservesViewingBreakAndGoalAcrossRepositoryInstances() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var journal = WellnessJournal()
        journal.viewingSessions = [ViewingSession(id: UUID(), durationMinutes: 25, endedAt: now, mood: .relaxed)]
        journal.activeBreak = HealthyBreak(id: UUID(), activity: .stretch, startedAt: now, completedAt: nil)
        journal.weeklyGoal = WeeklyViewingGoal(budgetMinutes: 300, updatedAt: now)
        try FileWellnessJournalRepository(fileURL: fileURL).save(journal)
        XCTAssertEqual(try FileWellnessJournalRepository(fileURL: fileURL).load(), journal)
    }
    func test_journal_corruptFileIsNotReplacedWithEmptyData() throws {
        let original = Data("not a journal".utf8)
        try original.write(to: fileURL)
        XCTAssertThrowsError(try FileWellnessJournalRepository(fileURL: fileURL).load())
        XCTAssertEqual(try Data(contentsOf: fileURL), original)
    }
    func test_journal_unknownSchemaIsRejectedWithoutReplacement() throws {
        var journal = WellnessJournal()
        journal.schemaVersion = 99
        let original = try JSONEncoder().encode(journal)
        try original.write(to: fileURL)
        XCTAssertThrowsError(try FileWellnessJournalRepository(fileURL: fileURL).load()) { error in
            guard case JournalStorageError.incompatible = error else { return XCTFail("Expected unsupported journal format") }
        }
        XCTAssertEqual(try Data(contentsOf: fileURL), original)
    }
    func test_journal_rejectsDecodedRecordWithInvalidDuration() throws {
        var journal = WellnessJournal()
        journal.viewingSessions = [ViewingSession(id: UUID(), durationMinutes: 0, endedAt: Date(), mood: nil)]
        try JSONEncoder().encode(journal).write(to: fileURL)
        XCTAssertThrowsError(try FileWellnessJournalRepository(fileURL: fileURL).load())
    }
    func test_journal_reportsSaveFailureWhenParentIsAFile() throws {
        let blocker = directory.appendingPathComponent("not-a-folder")
        try Data("occupied".utf8).write(to: blocker)
        let repository = FileWellnessJournalRepository(fileURL: blocker.appendingPathComponent("journal.json"))
        XCTAssertThrowsError(try repository.save(WellnessJournal()))
    }
}
