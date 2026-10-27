import SwiftUI
import TesseraCore
import TesseraTess

// MARK: - The plan as a state of Home

/// Plan my day as a state of TODAY (plan-home.md, m4-steers §6): the rules plan draws at once in wet cobalt rows,
/// Claude may reorder and word it, a swipe keeps or skips a row, and the hold on START WITH keeps the rest as his act.
/// Nothing is written by showing it. One shared instance, so paging Home never loses the offer.
@MainActor @Observable
final class HomePlanModel {
    static let shared = HomePlanModel()

    enum State { case offered, worded, kept }

    private(set) var plan: DayPlan?
    private(set) var state = State.offered
    private(set) var worded: WordedPlan?
    /// Claude's order, said once as Tess's line.
    private(set) var viaClaude = false
    private(set) var skipped: Set<UUID> = []
    /// Rows already kept by a swipe, with the op each wrote.
    private(set) var kept: [UUID: OpRecord] = [:]
    /// Any swipe, edit or the hold: a reply that lands after this is dropped.
    private(set) var touched = false
    /// The first time a plan comes via Claude, one line says what was sent; never again after that plan.
    private(set) var showsPrivacy = false
    private var day: Date?
    private var wording: Task<Void, Never>?
    /// How many times the plan went to Claude (zero while `AppModel.planWordingReady` is false).
    private(set) var wordingCalls = 0

    static let spentKey = "plan.offerSpentDay"
    static let privacyKey = "plan.privacyShown"

    init() {
        #if DEBUG
            // `-resetDemo` (simulator only) starts the demo day fresh: the offer is open again.
            if LaunchFlags.has("-resetDemo") {
                UserDefaults.standard.removeObject(forKey: Self.spentKey)
                UserDefaults.standard.removeObject(forKey: Self.privacyKey)
            }
        #endif
    }

    /// The ghost rows still on offer, in plan order.
    var rows: [DayPlan.Block] {
        (worded?.plan ?? plan)?.ghosts.filter { block in block.object.map { !skipped.contains($0) } ?? true } ?? []
    }

    var first: DayPlan.Block? {
        rows.first { block in block.object.map { kept[$0] == nil } ?? true } ?? rows.first
    }

    var isShowing: Bool {
        plan != nil && state != .kept && !rows.isEmpty
    }

    /// The planned workout's block, for the hero ("Push A at 6").
    var workout: DayPlan.Block? {
        (worded?.plan ?? plan)?.blocks.first { $0.kind == .workout }
    }

    /// Builds today's plan when the offer is open (08:00 to 21:00, or pulled from 07:00) and not yet spent; the plan
    /// is read once per offer, so Claude's order and his swipes hold.
    func refresh(model: AppModel, now: Date, calendar: Calendar, restDay: Bool, pulled: Bool = false) {
        let tesseraDay = TesseraDay(calendar: calendar)
        let today = tesseraDay.day(of: now)
        if day != today {
            reset()
            day = today
        }
        let hour = calendar.component(.hour, from: now)
        let open = pulled || (hour >= 8 && hour < 21)
        guard open, !isSpent(today), state != .kept else {
            if state != .kept {
                plan = nil
            }
            return
        }
        guard plan == nil else { return }
        let fresh = DayPlanner.plan(store: model.store, classes: model.classes, plan: model.plan, now: now,
                                    calendar: calendar)
        guard !fresh.ghosts.isEmpty else { return }
        plan = fresh
        state = .offered
        word(model: model, now: now, calendar: calendar, restDay: restDay)
    }

    private func isSpent(_ today: Date) -> Bool {
        UserDefaults.standard.double(forKey: Self.spentKey) == today.timeIntervalSinceReferenceDate
    }

    private func spend() {
        if let day {
            UserDefaults.standard.set(day.timeIntervalSinceReferenceDate, forKey: Self.spentKey)
        }
    }

    private func reset() {
        wording?.cancel()
        plan = nil
        worded = nil
        state = .offered
        viaClaude = false
        skipped = []
        kept = [:]
        touched = false
        showsPrivacy = false
    }

    /// Claude words the plan when "Tess asks Claude" is on and a key is saved; the rules plan stays readable meanwhile.
    private func word(model: AppModel, now: Date, calendar: Calendar, restDay: Bool) {
        // Claude's wording ships off until its eval passes (AI architecture): rules wording only, no call made.
        guard let plan, model.asksClaude, AppModel.planWordingReady else { return }
        wordingCalls += 1
        let pack = PlanPack(plan: plan, now: now, calendar: calendar, calendarKnown: false, restDay: restDay,
                            otherNames: plan.notPlanned.map(\.title), includesEventTitles: false,
                            lastWeightKg: BodyWeight.lastKg(in: model.store))
        wording?.cancel()
        wording = Task { @MainActor [weak self] in
            let result = await model.planWording.word(plan, pack: pack) { self?.touched ?? true }
            guard let self, !Task.isCancelled, !touched, self.plan == plan else { return }
            switch result {
            case let .worded(worded):
                self.worded = worded
                viaClaude = true
                state = .worded
                if let line = worded.startLine ?? worded.note {
                    TessVoice.shared.say(line)
                }
                if !UserDefaults.standard.bool(forKey: Self.privacyKey) {
                    showsPrivacy = true
                    UserDefaults.standard.set(true, forKey: Self.privacyKey)
                }
            case let .rules(line):
                if let line {
                    TessVoice.shared.say(line)
                }
            }
        }
    }

    // MARK: His acts

    /// Swipe right: the row is kept now, as one op with UNDO.
    func keep(_ block: DayPlan.Block, model: AppModel) {
        guard let id = block.object, kept[id] == nil else { return }
        touched = true
        guard let record = try? model.engine.perform(KeepPlannedTask(task: id, to: block.start), by: .user).record
        else {
            return
        }
        kept[id] = record
        model.touch()
        TessVoice.shared.say(
            "\(PlanWords.shownTitle(block, model: model)), \(Self.spoken(block.start))",
            undo: record
        ) { [weak self] in
            self?.kept[id] = nil
        }
    }

    /// Swipe left: the row goes; nothing is written, so no line and no UNDO.
    func skip(_ block: DayPlan.Block) {
        guard let id = block.object else { return }
        touched = true
        skipped.insert(id)
        if rows.isEmpty {
            skipPlan()
        }
    }

    /// Hold START WITH: every row not skipped is kept, as his act; the first item becomes Now. UNDO brings the plan
    /// back as it was.
    func keepPlan(model: AppModel) {
        guard let first else { return }
        touched = true
        var records: [UUID: OpRecord] = [:]
        for block in rows {
            guard let id = block.object, kept[id] == nil,
                  let record = try? model.engine.perform(KeepPlannedTask(task: id, to: block.start), by: .user).record
            else { continue }
            records[id] = record
        }
        let before = kept
        kept.merge(records) { $1 }
        state = .kept
        spend()
        model.touch()
        TessVoice.shared.say(
            "Plan kept. \(PlanWords.shownTitle(first, model: model)) is up",
            takeBack: { [weak self] in
                for record in records.values {
                    _ = model.engine.undo(record)
                }
                self?.kept = before
                self?.state = self?.worded == nil ? .offered : .worded
                UserDefaults.standard.removeObject(forKey: Self.spentKey)
                model.touch()
            }
        )
    }

    /// Swipe the hero left: the offer is spent until tomorrow; nothing is written and nothing is said.
    func skipPlan() {
        spend()
        plan = nil
        worded = nil
    }

    /// "8:00 am" for Tess's lines.
    static func spoken(_ date: Date) -> String {
        HouseTime.clock(date)
    }
}

// MARK: - Words

enum PlanWords {
    /// A plan row's name as it may be shown or said: a private task's label ("Private task") or "Private workout",
    /// by Core's own checks, else the block's title (hunt 22, plan ghost rows).
    @MainActor
    static func shownTitle(_ block: DayPlan.Block, model: AppModel) -> String {
        if block.kind == .workout {
            return ObjectPrivacy.routineTitle(block.title, in: model.store)
        }
        guard let id = block.object, let object = model.store.object(id: id) else { return block.title }
        return ObjectPrivacy.label(of: object, in: model.store, classes: model.classes) ?? block.title
    }

    /// The hero counts the tasks and the workout, never free, clear or open time (no calendar is read).
    /// Longest first; the page draws the first that fits.
    /// `shown` masks the workout's name: "Private workout" for a private routine (G274).
    static func heroForms(tasks: Int, workout: DayPlan.Block?, calendar: Calendar,
                          shown: (String) -> String = { $0 }) -> [String]
    {
        // Digits in heroes (copy pass rows 52-55): "3 tasks", "1 task".
        let count = tasks == 1 ? "1 task" : "\(tasks) tasks"
        guard let workout else { return [count] }
        // Clock times in heroes carry am or pm, in the one house time (copy pass, Design 62): "Push A, 6 pm".
        let clock = HouseTime.clock(workout.start, calendar: calendar)
        return ["\(count), \(shown(workout.title)), \(clock)", count]
    }

    /// The plan's first time, never a part of the day under the day label (copy pass): "from 8 am".
    static func context(first: DayPlan.Block?, calendar: Calendar) -> String? {
        first.map { "from \(HouseTime.clock($0.start, calendar: calendar))" }
    }
}

// MARK: - Rows

/// "Plan" where Next sits, VIA CLAUDE on its baseline once Claude's words have landed, then one wet cobalt row per
/// item: the title breathing, the time at the right. At most five rows; the rest are "N MORE".
struct PlanRows: View {
    let model: HomePlanModel
    /// How many rows fit above Tess's band (a two-line hero costs one).
    var capacity = 5
    @Environment(AppModel.self) private var app

    var body: some View {
        let rows = model.rows
        let shown = Array(rows.prefix(capacity))
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Plan")
                    .font(Theme.voice(size: 34))
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                if model.viaClaude {
                    Text("Via Claude")
                        .textRole(.labelStrong)
                        .foregroundStyle(Theme.Colors.ink)
                        .transition(.opacity)
                }
            }
            .frame(height: QueueWindow.headingHeight, alignment: .bottomLeading)
            ForEach(shown, id: \.object) { block in
                PlanRow(block: block, kept: block.object.map { model.kept[$0] != nil } ?? false,
                        keep: { model.keep(block, model: app) }, skip: { model.skip(block) })
                    .frame(minHeight: QueueWindow.rowHeight)
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity))
            }
            if rows.count > shown.count {
                Text("\(rows.count - shown.count) more")
                    .textRole(.labelStrong)
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(height: QueueWindow.rowHeight, alignment: .leading)
            }
            if model.showsPrivacy {
                Text("Titles and counts only. Never notes, places, health or money")
                    .font(Theme.voice(size: 16))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Theme.Spacing.s)
            }
        }
        .tesseraAnimation(Theme.Motion.house, value: rows.map(\.title))
        .accessibilityElement(children: .contain)
    }
}

/// One proposed row: wet cobalt, breathing, until a swipe right keeps it (the words dry into ink left to right, the
/// time 250 ms later) or a swipe left skips it.
struct PlanRow: View {
    let block: DayPlan.Block
    let kept: Bool
    let keep: () -> Void
    let skip: () -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.homePagerIdle) private var pagerIdle
    @Environment(\.homeRowGrab) private var grab
    @State private var drag: CGFloat = 0
    @State private var holding = false
    @State private var dried = false
    @State private var timeDried = false

    private static let threshold: CGFloat = 120

    var body: some View {
        let title = Text(PlanWords.shownTitle(block, model: model)).font(Theme.Typography.font(
            Theme.concept.scale.body,
            weight: .medium
        ))
        let time = Text(Format.clock(block.start)).font(Theme.Typography.font(Theme.concept.scale.label))
            .monospacedDigit()
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion || kept)) { context in
            words(title: title, time: time,
                  breath: (sin(context.date.timeIntervalSinceReferenceDate / 1.6 * .pi) + 1) / 2)
        }
        .offset(x: drag)
        .contentShape(Rectangle())
        .gesture(RowPressDrag(isEnabled: !kept && pagerIdle,
                              began: { holding = true },
                              changed: { drag = $0 },
                              ended: { commit($0) },
                              cancelled: { holding = false; settle() }))
        .onChange(of: holding) { _, now in grab(now) }
        .onChange(of: kept, initial: true) { _, now in
            if now {
                dry()
            } else {
                dried = false
                timeDried = false
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Proposed: \(PlanWords.shownTitle(block, model: model)), \(HomePlanModel.spoken(block.start))"
        )
        .accessibilityHint("Swipe right to keep, left to skip")
        .accessibilityAction(named: "Keep", keep)
        .accessibilityAction(named: "Skip", skip)
    }

    private func words(title: Text, time: Text, breath: Double) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            DryingWords(text: title, dried: dried)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
            Spacer(minLength: Theme.Spacing.s)
            DryingWords(text: time, dried: timeDried)
        }
        .opacity(dried ? 1 : reduceMotion ? 0.6 : 0.5 + 0.16 * breath)
    }

    private func commit(_ distance: CGFloat) {
        holding = false
        if distance >= Self.threshold {
            settle()
            keep()
        } else if -distance >= Self.threshold {
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { drag = -400 }
            skip()
        } else {
            settle()
        }
    }

    private func settle() {
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { drag = 0 }
    }

    private func dry() {
        withTesseraAnimation(.spring(Spring(duration: 0.7, bounce: 0)), reduceMotion: reduceMotion) { dried = true }
        withTesseraAnimation(.spring(Spring(duration: 0.7, bounce: 0)).delay(0.25), reduceMotion: reduceMotion) {
            timeDried = true
        }
    }
}
