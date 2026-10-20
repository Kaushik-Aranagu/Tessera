import SwiftUI
import TesseraCore

// Shutdown at 9 pm (Batch 4; shutdown-grammar mockup on sheet 41's Home frame): the clock as the context line,
// "Shutdown" as the hero, the rows that roll under a count label with TOMORROW as each row's value (a tap makes it
// LATER), one writing line for tomorrow, and CLOSE THE DAY as a 0.7 s hold. Tess says the opener and the close.
// Counts only, never what didn't happen. Behind the Review switch `shutdown` (Off: Now as it was).

/// What Shutdown shows on Now, if anything.
enum ShutdownStage: Equatable {
    /// The page, before the close.
    case open
    /// Closed tonight with a line for tomorrow: his line is the hero until the day changes.
    case closed(line: String)
}

/// One row that rolls: the task and its name as it may be shown ("Private task" when private).
struct ShutdownRow: Identifiable, Equatable {
    let id: UUID
    let title: String
}

/// Shutdown's state for the evening: which rows he sent to Later and his line. One shared instance, so paging Home
/// never loses what he typed. Nothing is written until the hold.
@MainActor
@Observable
final class ShutdownModel {
    static let shared = ShutdownModel()

    private(set) var later: Set<UUID> = []
    var line = ""
    @ObservationIgnored private var day: Date?
    @ObservationIgnored private var openerSaidDay: Date?

    /// The stage on Now: nil with the switch off, outside 21:00 to 04:00, or on a day closed with no line.
    static func stage(switchOn: Bool, now: Date, calendar: Calendar, closed: Bool, closedLine: String?)
        -> ShutdownStage?
    {
        guard switchOn, MyDayWindow.shutdownIsOpen(at: now, calendar: calendar) else { return nil }
        guard closed else { return .open }
        let line = closedLine?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return line.isEmpty ? nil : .closed(line: line)
    }

    func stage(model: AppModel, now: Date, calendar: Calendar,
               switches: MyDaySwitches = MyDaySwitches()) -> ShutdownStage?
    {
        guard switches.shutdown else { return nil }
        resetIfNewDay(now: now, calendar: calendar)
        let mark = ShutdownDay(store: model.store, classes: model.classes, calendar: calendar).closedMark(for: now)
        let line = mark.flatMap { model.store.value("tomorrowLine", of: $0)?.stringValue }
        let shown = line.map { ObjectPrivacy.isPrivateTitle($0, lastWeightKg: BodyWeight.lastKg(in: model.store))
            ? ObjectPrivacy.taskLabel : $0
        }
        return Self.stage(switchOn: true, now: now, calendar: calendar, closed: mark != nil, closedLine: shown)
    }

    private func resetIfNewDay(now: Date, calendar: Calendar) {
        let today = TesseraDay(calendar: calendar).day(of: now)
        guard day != today else { return }
        day = today
        // Only a real change is written, so reading the stage during a body update never invalidates it.
        if !later.isEmpty {
            later = []
        }
        if !line.isEmpty {
            line = ""
        }
    }

    func toggle(_ id: UUID) {
        if later.contains(id) {
            later.remove(id)
        } else {
            later.insert(id)
        }
    }

    /// The day's counts, with last night's sleep and a private workout's name masked.
    static func inputs(model: AppModel, now: Date, calendar: Calendar) -> ShutdownInputs {
        var inputs = ShutdownDay(store: model.store, classes: model.classes, calendar: calendar).inputs(at: now)
        inputs.workoutName = inputs.workoutName.map { ObjectPrivacy.routineTitle($0, in: model.store) }
        inputs.sleep = LastNightSleep.asleepMinutes(store: model.store, classes: model.classes, now: now,
                                                    calendar: calendar).map(LastNightSleep.short)
        return inputs
    }

    /// Today's open tasks, in Core's order, each with its shown name.
    static func rows(model: AppModel, now: Date, calendar: Calendar) -> [ShutdownRow] {
        TaskList(store: model.store, classes: model.classes).today(now, calendar: calendar)
            .filter { !$0.isDone }
            .map { item in
                ShutdownRow(id: item.id,
                            title: ObjectPrivacy.label(of: item.task, in: model.store, classes: model.classes)
                                ?? item.title)
            }
    }

    /// Tess's opener, once an evening.
    func sayOpener(_ inputs: ShutdownInputs, now: Date, calendar: Calendar) {
        let today = TesseraDay(calendar: calendar).day(of: now)
        guard openerSaidDay != today else { return }
        openerSaidDay = today
        TessVoice.shared.say(ShutdownLines.opener(inputs))
    }

    /// The hold: kept rows to tomorrow, LATER rows to Later, his line as a task at 8 am, the day's mark and its Day
    /// log line. One op, so UNDO takes it all back ("Shutdown, taken back.").
    @discardableResult
    func close(model: AppModel, rows: [ShutdownRow], inputs: ShutdownInputs, now: Date, calendar: Calendar) -> Bool {
        let kept = rows.filter { !later.contains($0.id) }.map(\.id)
        let moved = rows.filter { later.contains($0.id) }.map(\.id)
        let written = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let action = CloseDay(tomorrow: kept, later: moved, line: written.isEmpty ? nil : written,
                              dayLine: ShutdownLines.dayLogLine(inputs), closedAt: now, calendar: calendar)
        guard let record = try? model.engine.perform(action, by: .user).record else {
            TessVoice.shared.say(ShutdownCopy.didntClose)
            return false
        }
        var closing = inputs
        closing.wroteTomorrowLine = !written.isEmpty
        model.touch()
        TessVoice.shared.say(ShutdownLines.close(closing), takeBack: {
            _ = model.engine.undo(record)
            model.touch()
            Task { @MainActor in TessVoice.shared.say(ShutdownCopy.takenBack) }
        })
        return true
    }
}

/// Shutdown's own words; the opener, carry-over and close come from Core's `ShutdownLines`.
enum ShutdownCopy {
    static let hero = "Shutdown"
    static let tomorrowFirst = "Tomorrow, first"
    static let closeKey = "Close the day"
    static let closeHint = "Moves the rows, keeps your line and closes the day"
    static let takenBack = "Shutdown, taken back."
    static let didntClose = "Didn't close the day. Try again."
    static let fallbackPlaceholder = "One line for tomorrow, if you want."

    /// Where a kept row goes: tomorrow, or the weekday by name past midnight ("Friday").
    static func destination(_ inputs: ShutdownInputs) -> String {
        inputs.pastMidnight && !inputs.nextWeekday.isEmpty ? inputs.nextWeekday : "tomorrow"
    }

    /// The count label over the rows: "3 moving to tomorrow", "2 moving to Friday". Counts only.
    static func moving(_ count: Int, _ inputs: ShutdownInputs) -> String {
        "\(count) moving to \(destination(inputs))"
    }

    /// A row's value word: where it goes.
    static func value(later: Bool, _ inputs: ShutdownInputs) -> String {
        later ? "Later" : destination(inputs).prefix(1).uppercased() + destination(inputs).dropFirst()
    }

    /// "3 more", under the three rows shown; they roll too.
    static func more(_ count: Int) -> String {
        "\(count) more"
    }
}

// MARK: - The page on Now

/// Shutdown in Now's hero place, or the closed day's hero (his line) once he has closed with one.
struct ShutdownNow: View {
    let stage: ShutdownStage
    let now: Date

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var writing: Bool
    @State private var closes = 0
    private let shutdown = ShutdownModel.shared
    private let calendar = Calendar.current

    static let rowsShown = 3

    var body: some View {
        switch stage {
        case .open: page
        case let .closed(line): closedDay(line)
        }
    }

    private var page: some View {
        let inputs = ShutdownModel.inputs(model: model, now: now, calendar: calendar)
        let rows = ShutdownModel.rows(model: model, now: now, calendar: calendar)
        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text(HouseTime.clock(now, calendar: calendar))
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.context)
                .entrance(1)
            Text(ShutdownCopy.hero)
                .textRole(.hero)
                .foregroundStyle(Theme.Colors.ink)
                .accessibilityAddTraits(.isHeader)
                .entrance(2, hero: true)
            if !rows.isEmpty {
                rowList(rows, inputs: inputs)
                    .entrance(3)
            }
            tomorrowLine(inputs)
                .padding(.top, Theme.Spacing.s)
                .entrance(4)
            closeKey(rows: rows, inputs: inputs)
                .padding(.top, Theme.Spacing.xl)
                .entrance(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tesseraFeedback(.done, trigger: closes)
        .onAppear { shutdown.sayOpener(inputs, now: now, calendar: calendar) }
    }

    private func rowList(_ rows: [ShutdownRow], inputs: ShutdownInputs) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(ShutdownCopy.moving(rows.count, inputs))
                .textRole(.label)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .padding(.bottom, Theme.Spacing.xs)
            ForEach(rows.prefix(Self.rowsShown)) { row in
                let isLater = shutdown.later.contains(row.id)
                Button {
                    withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { shutdown.toggle(row.id) }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                        Text(row.title)
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.ink)
                            .lineLimit(2)
                        Spacer(minLength: Theme.Spacing.s)
                        Text(ShutdownCopy.value(later: isLater, inputs))
                            .textRole(.labelStrong)
                            .foregroundStyle(Theme.Colors.ink)
                            .contentTransition(.opacity)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(HandleButtonStyle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.title)
                .accessibilityValue(ShutdownCopy.value(later: isLater, inputs))
                .accessibilityHint(isLater ? "Moves it back to \(ShutdownCopy.destination(inputs))" :
                    "Moves it to Later")
                .accessibilityAddTraits(.isButton)
            }
            if rows.count > Self.rowsShown {
                Text(ShutdownCopy.more(rows.count - Self.rowsShown))
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(minHeight: 44, alignment: .leading)
            }
        }
        .tesseraFeedback(.selection, trigger: shutdown.later)
        .accessibilityElement(children: .contain)
    }

    private func tomorrowLine(_ inputs: ShutdownInputs) -> some View {
        @Bindable var shutdown = shutdown
        let placeholder = ShutdownLines.tomorrowPlaceholder(inputs)
        return VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(ShutdownCopy.tomorrowFirst)
                .textRole(.label)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .accessibilityHidden(true)
            TextField("", text: $shutdown.line,
                      prompt: Text(placeholder).foregroundStyle(Theme.Colors.inkSecondary), axis: .vertical)
                .textRole(.field)
                .foregroundStyle(Theme.Colors.tess)
                .lineLimit(1 ... 3)
                .submitLabel(.done)
                .focused($writing)
                .onChange(of: shutdown.line) { _, new in
                    // One line: a return ends it rather than starting a second.
                    if new.contains("\n") {
                        shutdown.line = new.replacingOccurrences(of: "\n", with: "")
                        writing = false
                    }
                }
                .frame(minHeight: 44)
                .accessibilityLabel(ShutdownCopy.tomorrowFirst)
                .accessibilityHint(placeholder.isEmpty ? ShutdownCopy.fallbackPlaceholder : placeholder)
            RowSeparator()
        }
    }

    private func closeKey(rows: [ShutdownRow], inputs: ShutdownInputs) -> some View {
        PaintKey(paint: Theme.Colors.ink, duration: 0.7, isSilent: true, hint: ShutdownCopy.closeHint, action: {
            close(rows: rows, inputs: inputs)
        }, label: { _ in
            Text(ShutdownCopy.closeKey).textRole(.labelStrong)
        }, meta: { EmptyView() })
            .accessibilityLabel(ShutdownCopy.closeKey)
            .accessibilityAction(named: ShutdownCopy.closeKey) { close(rows: rows, inputs: inputs) }
    }

    private func close(rows: [ShutdownRow], inputs: ShutdownInputs) {
        writing = false
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            if shutdown.close(model: model, rows: rows, inputs: inputs, now: AppClock.now, calendar: calendar) {
                closes += 1
            }
        }
    }

    /// The closed day: "tomorrow, first" as the context line, his line as the hero.
    private func closedDay(_ line: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("tomorrow, first")
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.context)
            HeroText(text: line) { $0 }
                .foregroundStyle(Theme.Colors.ink)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity)
    }
}
