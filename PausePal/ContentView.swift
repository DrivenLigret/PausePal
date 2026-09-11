import SwiftUI
import UIKit

private enum Palette {
    static let teal = Color(red: 0.10, green: 0.40, blue: 0.37)
    static let paper = Color(red: 0.97, green: 0.97, blue: 0.94)
    static let mist = Color(red: 0.88, green: 0.94, blue: 0.88)
}

struct PausePalRootView: View {
    @EnvironmentObject private var model: WellnessViewModel
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        Group {
            if model.ready {
                TabView(selection: $model.selectedTab) {
                    NavigationStack { TodayView() }.tabItem { Label("Today", systemImage: "sun.max") }.tag(0)
                    NavigationStack { PauseView() }.tabItem { Label("Pause", systemImage: "pause.circle") }
                        .tag(1)
                    NavigationStack { RestoreView() }.tabItem { Label("Restore", systemImage: "leaf") }.tag(2)
                    NavigationStack { ReflectView() }.tabItem { Label("Reflect", systemImage: "chart.bar") }
                        .tag(3)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "book.closed").font(.largeTitle)
                    Text("Could not open journal").font(.title2.bold())
                    Text("Your records have not been changed. Try opening the journal again.")
                    Button("Retry opening journal", action: model.reload).buttonStyle(PrimaryButton())
                }.padding(28)
            }
        }
        .tint(Palette.teal)
        .preferredColorScheme(.light)
        .alert("Please check", isPresented: $model.showError) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.reload() }
        }
    }
}

private struct ConfirmationView: View {
    @EnvironmentObject private var model: WellnessViewModel
    var body: some View {
        if let notice = model.notice {
            HStack {
                Text(notice)
                Spacer()
                Button {
                    model.notice = nil
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Dismiss confirmation")
                .frame(minWidth: 44, minHeight: 44)
            }
            .font(.subheadline)
            .padding()
            .background(Palette.mist, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(.white).background(
                Palette.teal.opacity(configuration.isPressed ? 0.75 : 1),
                in: RoundedRectangle(cornerRadius: 16))
    }
}
private struct NumberEntry: View {
    let title: String
    @Binding var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            TextField("Minutes", text: $text).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                .accessibilityLabel(title)
        }
    }
}

struct TodayView: View {
    @EnvironmentObject private var model: WellnessViewModel
    private var todayEntries: [ViewingSession] {
        var entries: [ViewingSession] = []
        for session in model.journal.viewingSessions {
            if Calendar.current.isDateInToday(session.endedAt) { entries.append(session) }
        }
        entries.sort { first, second in
            return first.endedAt > second.endedAt
        }
        return entries
    }
    private var todayMinutes: Int {
        var total = 0
        for session in todayEntries { total += session.durationMinutes }
        return total
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Today").font(.largeTitle.bold())
                Text("Record your short-video viewing.").foregroundStyle(.secondary)
                ConfirmationView()
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("TODAY’S LOGGED VIEWING").font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text("\(todayMinutes) min").font(
                                    .system(size: 44, weight: .bold, design: .rounded))
                            }
                            Spacer()
                            Image(systemName: "sun.max.fill").font(.system(size: 38)).foregroundStyle(
                                Palette.teal)
                        }
                        Text("Based on your entries, not automatic tracking.").font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Record a viewing session").font(.title3.bold())
                        NumberEntry(title: "How many minutes did you watch?", text: $model.viewingMinutes)
                        DatePicker(
                            "Viewing ended", selection: $model.viewingEndedAt, in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute])
                        Picker("How did you feel?", selection: $model.selectedMood) {
                            Text("Prefer not to say").tag(Optional<ViewingMood>.none)
                            ForEach(ViewingMood.allCases) { mood in Text(mood.title).tag(Optional(mood)) }
                        }
                        Text("Mood is optional.").font(.footnote).foregroundStyle(.secondary)
                        Button("Save & choose a pause", action: model.recordViewing).buttonStyle(
                            PrimaryButton())
                    }
                }
                if todayEntries.isEmpty {
                    Text("No entries today.").font(.subheadline).foregroundStyle(.secondary)
                } else {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today’s entries").font(.headline)
                            ForEach(todayEntries) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(entry.durationMinutes) minutes").font(.headline)
                                        Text(entry.endedAt, style: .time).font(.caption).foregroundStyle(
                                            .secondary)
                                    }
                                    Spacer()
                                    if let mood = entry.mood {
                                        Label(mood.title, systemImage: mood.symbol).font(.caption)
                                    }
                                }.padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Palette.paper)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}

struct PauseView: View {
    @EnvironmentObject private var model: WellnessViewModel
    private var latest: ViewingSession? {
        var latestSession: ViewingSession? = nil
        for session in model.journal.viewingSessions {
            if let current = latestSession {
                if session.endedAt > current.endedAt { latestSession = session }
            } else {
                latestSession = session
            }
        }
        return latestSession
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Take a break").font(.largeTitle.bold())
                Text("Choose a break when you are ready.").foregroundStyle(.secondary)
                ConfirmationView()
                VStack(spacing: 20) {
                    Image(systemName: "pause.fill").font(.system(size: 50, weight: .light))
                        .frame(width: 135, height: 135).background(Palette.mist, in: Circle())
                        .foregroundStyle(Palette.teal)
                        .accessibilityHidden(true)
                    if let latest = latest {
                        Text("Your latest entry: \(latest.durationMinutes) minutes").font(.title3.bold())
                            .multilineTextAlignment(.center)
                        Text(latest.endedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption)
                            .foregroundStyle(.secondary)
                        if let mood = latest.mood {
                            Label("You felt \(mood.rawValue)", systemImage: mood.symbol)
                        }
                    } else {
                        Text("You can take a break anytime.").font(.title3.bold())
                    }
                }.frame(maxWidth: .infinity).padding(.vertical, 14)
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What would help right now?").font(.title3.bold())
                        Text("Try stretching, getting water or talking to a friend.")
                        Button(model.journal.activeBreak == nil ? "Choose an activity" : "Return to my break")
                        { model.selectedTab = 2 }.buttonStyle(PrimaryButton())
                        Button("Not now") {
                            model.selectedTab = 0
                            model.notice = nil
                        }.frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }
            .padding(20)
        }
        .background(Palette.paper)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}

struct RestoreView: View {
    @EnvironmentObject private var model: WellnessViewModel
    @State private var confirmCancel = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Activities").font(.largeTitle.bold())
                Text("Pick something to do away from the screen.").foregroundStyle(.secondary)
                ConfirmationView()
                if let active = model.journal.activeBreak {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Label(active.activity.title, systemImage: active.activity.symbol).font(
                                .title3.bold())
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                let remaining = active.remainingSeconds(at: context.date)
                                VStack(alignment: .leading, spacing: 14) {
                                    Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                                        .monospacedDigit()
                                        .accessibilityLabel(
                                            "\(remaining / 60) minutes and \(remaining % 60) seconds remaining"
                                        )
                                    Text(
                                        remaining == 0
                                            ? "Finished your activity? Tap Complete break."
                                            : "The timer continues when you leave the app."
                                    )
                                    .font(.subheadline)
                                    Button(remaining == 0 ? "Complete break" : "Break in progress") {
                                        model.completeBreak(active.id)
                                    }
                                    .buttonStyle(PrimaryButton()).disabled(remaining > 0).opacity(
                                        remaining > 0 ? 0.55 : 1)
                                }
                            }
                            Button("Cancel this break", role: .destructive) { confirmCancel = true }.frame(
                                minHeight: 44)
                            Text("Come back to record completion. There is no end notification.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .confirmationDialog(
                        "Cancel this break? It will not count as completed.", isPresented: $confirmCancel,
                        titleVisibility: .visible
                    ) {
                        Button("Cancel break", role: .destructive) { model.cancelBreak(active.id) }
                        Button("Keep resting", role: .cancel) {}
                    }
                } else {
                    ForEach(RestorativeActivity.allCases) { activity in
                        GroupBox {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .top) {
                                    Image(systemName: activity.symbol).font(.title2).foregroundStyle(
                                        Palette.teal
                                    )
                                    .frame(width: 42, height: 42).background(
                                        Palette.mist, in: RoundedRectangle(cornerRadius: 12))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(activity.title).font(.headline)
                                        Text("\(activity.minutes) minute break").font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Text(activity.detail).font(.subheadline)
                                Button("Start \(activity.minutes)-minute break") {
                                    model.startBreak(activity)
                                }.buttonStyle(PrimaryButton())
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Palette.paper)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}

struct ReflectView: View {
    @EnvironmentObject private var model: WellnessViewModel
    private var reflection: WeeklyReflection { WeeklyReflection(journal: model.journal) }
    private var largestDailyMinutes: Int {
        var largest = 1
        for day in reflection.days {
            if day.minutes > largest { largest = day.minutes }
        }
        return largest
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("This week").font(.largeTitle.bold())
                Text("Your records from the last seven days.").foregroundStyle(.secondary)
                ConfirmationView()
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 24) {
                            VStack(alignment: .leading) {
                                Text("\(reflection.loggedMinutes)").font(
                                    .system(.largeTitle, design: .rounded).bold())
                                Text("minutes logged").font(.caption)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("\(reflection.completedBreakCount)").font(
                                    .system(.largeTitle, design: .rounded).bold())
                                Text("breaks completed").font(.caption)
                            }
                        }
                        if let change = reflection.changePercent {
                            Text(
                                "Logged minutes are \(Int(abs(change).rounded()))% \(change < 0 ? "lower" : "higher") than the preceding seven days."
                            ).font(.subheadline)
                        } else {
                            Text("Add entries in both weeks to see a comparison.").font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily viewing entries").font(.headline)
                        ForEach(reflection.days) { day in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(
                                        day.date.formatted(
                                            .dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                                    Spacer()
                                    Text(day.entryCount == 0 ? "No entries" : "\(day.minutes) min")
                                }.font(.caption)
                                ProgressView(value: Double(day.minutes), total: Double(largestDailyMinutes))
                                    .accessibilityLabel(
                                        day.date.formatted(date: .abbreviated, time: .omitted)
                                    )
                                    .accessibilityValue(
                                        day.entryCount == 0 ? "No entries" : "\(day.minutes) minutes logged")
                            }
                        }
                    }
                }
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your seven-day viewing budget").font(.title3.bold())
                        if let goal = reflection.goal {
                            Text("\(reflection.loggedMinutes) / \(goal.budgetMinutes) minutes logged").font(
                                .headline)
                            Text(
                                reflection.loggedMinutes > goal.budgetMinutes
                                    ? "You are above your weekly budget."
                                    : "You are within your weekly budget."
                            ).font(.subheadline)
                        }
                        NumberEntry(title: "Minutes across seven days", text: $model.weeklyBudget)
                        Button("Save my budget", action: model.saveGoal).buttonStyle(PrimaryButton())
                    }
                }
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("About your data", systemImage: "lock.shield").font(.headline)
                        Text(
                            "Records are saved only on this device, without backup. Uninstalling the app deletes them."
                        )
                        .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
        }
        .background(Palette.paper)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}
