import XCTest
import Foundation
#if SWIFT_PACKAGE
@testable import PausePalCore
#endif

final class InMemoryWellnessJournalRepository: WellnessJournalRepository {
    var journal = WellnessJournal()
    var failLoad = false
    var failSave = false
    func load() throws -> WellnessJournal {
        if failLoad { throw JournalStorageError.unreadable }
        return journal
    }
    func save(_ journal: WellnessJournal) throws {
        if failSave { throw JournalStorageError.saveFailed }
        self.journal = journal
    }
}

final class WellnessUseCaseTests: XCTestCase {
    private var repository: InMemoryWellnessJournalRepository!
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    override func setUp() {
        super.setUp()
        repository = InMemoryWellnessJournalRepository()
    }
    private func record(_ minutes: Int, endedAt: Date? = nil) throws {
        try RecordViewingSessionUseCase(repository: repository).execute(minutes: minutes, endedAt: endedAt ?? now, mood: .bored, now: now)
    }
    private func start() throws -> HealthyBreak {
        let journal = try StartHealthyBreakUseCase(repository: repository).execute(activity: .stretch, now: now)
        return try XCTUnwrap(journal.activeBreak)
    }
    func test_recordViewing_savesDurationAndOptionalMood() throws {
        try record(25)
        XCTAssertEqual(repository.journal.viewingSessions.count, 1)
        XCTAssertEqual(repository.journal.viewingSessions.first?.durationMinutes, 25)
        XCTAssertEqual(repository.journal.viewingSessions.first?.mood, .bored)
    }
    func test_recordViewing_acceptsMinimumAndMaximumMinutes() throws {
        try record(1)
        try record(1440)
        XCTAssertEqual(repository.journal.viewingSessions.map(\.durationMinutes), [1, 1440])
    }
    func test_recordViewing_rejectsZeroNegativeAndOverOneDay() {
        for minutes in [0, -1, 1441, Int.max] {
            XCTAssertThrowsError(try record(minutes)) {
                XCTAssertEqual($0 as? RecordViewingSessionUseCase.Failure, .invalidDuration)
            }
        }
        XCTAssertTrue(repository.journal.viewingSessions.isEmpty)
    }
    func test_recordViewing_rejectsFutureEnd() {
        XCTAssertThrowsError(try record(20, endedAt: now.addingTimeInterval(1))) {
            XCTAssertEqual($0 as? RecordViewingSessionUseCase.Failure, .futureEnd)
        }
    }
    func test_recordViewing_doesNotInsertIdenticalRecordTwice() throws {
        try record(20)
        XCTAssertThrowsError(try record(20)) {
            XCTAssertEqual($0 as? RecordViewingSessionUseCase.Failure, .duplicateRecord)
        }
        XCTAssertEqual(repository.journal.viewingSessions.count, 1)
    }
    func test_recordViewing_allowsPersonToSkipMood() throws {
        try RecordViewingSessionUseCase(repository: repository).execute(minutes: 10, endedAt: now, mood: nil, now: now)
        XCTAssertNil(repository.journal.viewingSessions.first?.mood)
    }
    func test_recordViewing_reportsWriteFailureWithoutAddingRecord() {
        repository.failSave = true
        XCTAssertThrowsError(try record(20)) {
            XCTAssertEqual($0 as? RecordViewingSessionUseCase.Failure, .journalUnavailable)
        }
        XCTAssertTrue(repository.journal.viewingSessions.isEmpty)
    }
    func test_recordViewing_doesNotOverwriteUnreadableJournal() {
        repository.failLoad = true
        XCTAssertThrowsError(try record(20)) {
            XCTAssertEqual($0 as? RecordViewingSessionUseCase.Failure, .journalUnavailable)
        }
        XCTAssertTrue(repository.journal.viewingSessions.isEmpty)
    }
    func test_startBreak_persistsChosenActivityAndStartTime() throws {
        let active = try start()
        XCTAssertEqual(active.activity, .stretch)
        XCTAssertEqual(active.startedAt, now)
        XCTAssertNil(active.completedAt)
    }
    func test_startBreak_cannotReplaceExistingBreak() throws {
        let original = try start()
        XCTAssertThrowsError(try StartHealthyBreakUseCase(repository: repository).execute(activity: .outdoorWalk, now: now)) {
            XCTAssertEqual($0 as? StartHealthyBreakUseCase.Failure, .breakAlreadyActive)
        }
        XCTAssertEqual(repository.journal.activeBreak?.id, original.id)
    }
    func test_startBreak_failedSaveLeavesNoActiveBreak() {
        repository.failSave = true
        XCTAssertThrowsError(try start()) {
            XCTAssertEqual($0 as? StartHealthyBreakUseCase.Failure, .journalUnavailable)
        }
        XCTAssertNil(repository.journal.activeBreak)
    }
}
