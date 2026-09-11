import SwiftUI

@main
struct PausePalApp: App {
    @StateObject private var model = WellnessViewModel(
        repository: FileWellnessJournalRepository(fileURL: FileWellnessJournalRepository.defaultURL())
    )
    var body: some Scene {
        WindowGroup { PausePalRootView().environmentObject(model) }
    }
}
