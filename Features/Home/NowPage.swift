import SwiftUI
import TesseraCore

/// TODAY: the day word, one plain line per thing (the time above, the thing and its state as the hero, one key),
/// a short "Next" window. Nothing is ever cut (home-first-review.md 41). Grouping is by space and type alone.
struct NowPage: View {
    /// Pages Home to a sibling (used by the empty state).
    var onShow: (HomeSpatialView.Page) -> Void = { _ in }

    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openHomeLink) private var openLink
    @State private var finishes = 0
    /// The current Now, passed back to the ranker so it holds against equal challengers (no flicker).
    @State private var incumbent: UUID?
    private let planModel = HomePlanModel.shared

    var body: some View {
        let _ = model.revision
        let now = AppClock.now
        let schedule = model.schedule(around: now)
        // Now comes from Core's ranker (rest day, the 15-minute override, re-entry, the scored rank). It re-runs
        // when the data changes (revision) and as the clock moves, never on its own timer.
        let top = rank(now: now).first
        let ranked = top?.item.kind == .task ? schedule.first { $0.id == top?.item.id } : nil
        let current = ranked ?? model.currentTask(around: now)

        let facts = HomeFacts(engine: model.engine)
        let ledger = model.processes.ledger(now: now)
        // A session planned today is the hero (Product on L3), so it never repeats in Next (41.7).
        let heroWorkout = top?.item.kind == .rest && facts.rest(next: top?.item.object, now: now) == nil
            ? facts.plannedSession(on: now) : nil
        // The plan takes Now only in its place (§6): never over a running workout or a timed task within 15 min.
        let planNow = planModel.isShowing && model.session == nil && ledger.isEmpty
            && (!(current.map { $0.start.timeIntervalSince(now) < 15 * 60 } ?? false) || Self.pullsPlan)

        VStack(alignment: .leading, spacing: 0) {
            // The only day word on Home (41.4): the painted stroke lives one tap down now.
            DayLabel(now: now)
                .entrance(0)
                .padding(.bottom, Theme.Spacing.xl)

            Group {
                // A running process is Now (docs/product/whats-running.md); a paused one is Now too (41.7).
                if let session = model.session, let process = model.processes.running(),
                   process.subject?.id == session.workout.id, let fact = facts.fact(process: process)
                {
                    LineHero(line: HomeLines.line(for: fact, now: now)) {
                        PaintKey(paint: Theme.Colors.liveInk, isTap: true, progress: progress(of: process),
                                 action: { model.isWorkoutPresented = true }, label: { _ in
                                     Text("Resume \(session.workout.title)").textRole(.labelStrong)
                                 })
                                 .accessibilityLabel("Resume \(session.workout.title)")
                    }
                } else if let process = ledger.first, let fact = facts.fact(process: process) {
                    LineHero(line: HomeLines.line(for: fact, now: now), opens: .object(fact.id ?? process.id)) {
                        PaintKey(paint: Theme.Colors.ink, isTap: true, progress: progress(of: process),
                                 action: { model.resume(process) }, label: { _ in
                                     Text("Resume \(fact.title)").textRole(.labelStrong)
                                 })
                                 .accessibilityLabel("Resume \(fact.title)")
                    }
                } else if let top, top.item.kind == .rest {
                    let next = top.item.object
                    if let fact = facts.rest(next: next, now: now) {
                        LineHero(line: HomeLines.line(for: fact, now: now)) {
                            // An empty routine has nothing to start, so no key (Builder A's canStart). The key rests
                            // in ink like the planned routine's: colour comes with the moment (Design on #366).
                            if planNow {
                                planKey
                            } else if model.canStart(next) {
                                PaintKey(paint: Theme.Colors.ink, isTap: true, action: { model.startRoutine(next) },
                                         label: { _ in Text("Start \(next.title)").textRole(.labelStrong) })
                                    .accessibilityLabel("Start \(next.title)")
                                    .accessibilityHint("Starts \(next.title) anyway")
                            }
                        }
                    } else if let workout = facts.plannedSession(on: now) {
                        // A session planned today wins over the rest day (Product on L3): "Push A at 7 pm", START.
                        LineHero(line: HomeLines.line(for: facts.fact(scheduled: workout), now: now),
                                 opens: .object(workout.id))
                        {
                            PaintKey(paint: Theme.Colors.ink, isTap: true, action: { model.startWorkout(workout) },
                                     label: { _ in
                                         Text("Start \(model.store.displayTitle(of: workout))").textRole(.labelStrong)
                                     })
                                     .accessibilityLabel("Start \(model.store.displayTitle(of: workout))")
                        }
                    }
                } else if planNow {
                    planHero(now: now)
                } else {
                    hero(current, now: now, facts: facts)
                }
            }
            .padding(.bottom, Theme.Spacing.xl)

            // Anything else left paused (a cook under a paused workout) keeps its ledger row.
            ForEach(Array(ledger.dropFirst())) { process in
                LedgerRow(process: process, now: now)
                    .padding(.bottom, Theme.Spacing.l)
                    .transition(.offset(y: 10).combined(with: .opacity))
            }

            if planNow {
                PlanRows(model: planModel)
                    .entrance(4)
            } else {
                let queue = QueueEntry.split(model: model, schedule: schedule, current: current, now: now)
                // The running or paused thing is the hero too, and never repeats in Next (41.7).
                let heroID = model.processes.running()?.subject?.id ?? ledger.first?.subject?.id ?? heroWorkout?.id
                QueueWindow(next: queue.next.filter { $0.id != heroID }, later: queue.later.filter { $0.id != heroID })
                    .entrance(4)
            }

            Spacer(minLength: 0)
        }
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.8), trigger: finishes)
        .onChange(of: top?.id, initial: true) { _, id in
            incumbent = id
        }
        // The offer is read when the data or the clock moves, never on its own timer.
        .onChange(of: model.revision, initial: true) { _, _ in
            planModel.refresh(model: model, now: AppClock.now, calendar: .current, restDay: top?.item.kind == .rest)
        }
    }

    /// The seeded starter plan stores no weekly count, so the rhythm comes from its routines (PPL x2: 6 a week,
    /// leaving one rest day). Without this, the week never has a rest day and Now never says so (QA E5).
    static func sessionsPerWeek(model: AppModel, plan: ObjectRecord?) -> Int? {
        PlanRhythm.perWeek(cycleCount: plan.map { model.store.linkedObjects("routines", of: $0).count } ?? 0)
    }

    private func rank(now: Date) -> [Pick] {
        let picker = NowPicker(engine: model.engine)
        let plan = model.plan
        return picker.rank(RankContext(
            now: now,
            plan: plan,
            sessionsPerWeek: Self.sessionsPerWeek(model: model, plan: plan),
            incumbent: incumbent,
            lastAction: picker.lastAction(),
            daysAway: picker.daysAway(at: now)
        ))
    }

    // MARK: Hero

    // MARK: Plan my day

    /// `-planNow` (simulator only): the plan takes Now even with a timed task close, as a pull would; the demo day
    /// always has one running, so recordings and UI tests need it.
    static var pullsPlan: Bool {
        #if DEBUG
            LaunchFlags.has("-planNow")
        #else
            false
        #endif
    }

    /// The day as the hero ("Three tasks, Push A at 6"), the time above it, START WITH under it. Swipe it left to
    /// skip the whole plan: nothing written, nothing said.
    private func planHero(now _: Date) -> some View {
        let calendar = Calendar.current
        let forms = PlanWords.heroForms(tasks: planModel.rows.count, workout: planModel.workout, calendar: calendar)
        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            if let context = PlanWords.context(first: planModel.rows.first, calendar: calendar) {
                Text(context)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
                    .entrance(1)
            }
            PlanHeroText(forms: forms)
                .siblingParallax()
                .entrance(2, hero: true)
                .gesture(RowPressDrag(isEnabled: true, began: {}, changed: { _ in }, ended: { distance in
                    if distance <= -120 {
                        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { planModel.skipPlan() }
                    }
                }, cancelled: {}))
                .accessibilityAction(named: "Skip the plan") { planModel.skipPlan() }
            planKey
                .entrance(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// START WITH and the first item, as a hold: it keeps the plan and never starts anything.
    @ViewBuilder private var planKey: some View {
        if let first = planModel.first {
            PaintKey(paint: Theme.Colors.ink, duration: 0.7, hint: "Keeps the plan", action: {
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                    planModel.keepPlan(model: model)
                }
            }, label: { _ in
                Text("Start with \(first.title)")
                    .textRole(.labelStrong)
                    .fixedSize(horizontal: false, vertical: true)
            })
            .accessibilityLabel("Start with \(first.title)")
        }
    }

    /// The workout's progress for the key's ink line (41.5): the share of its sets logged, nil before any.
    private func progress(of process: ProcessSnapshot) -> Double? {
        guard let workout = process.subject else { return nil }
        let entries = workout.orderedChildren.filter { !$0.isDeleted }
        let planned = Self.plannedSets(entries, store: model.store)
        let done = entries.reduce(0) { $0 + $1.orderedChildren.count { !$0.isDeleted } }
        guard planned > 0, done > 0 else { return nil }
        return min(Double(done) / Double(planned), 1)
    }

    /// The sets a workout plans: each entry's "targetSets" (where the plan and the demo write it), 3 when an entry
    /// has none (as WorkoutSession counts it), at least 1 each.
    static func plannedSets(_ entries: [ObjectRecord], store: ObjectStore) -> Int {
        entries.reduce(0) { $0 + max(Int(store.number("targetSets", of: $1) ?? 3), 1) }
    }

    /// The hold that finishes a timed task, with its time left.
    private func finishKey(_ task: ScheduleItem) -> some View {
        PaintKey(duration: 0.7, hint: "Finishes the task", action: { finish(task) }, label: { _ in
            Text("Finish").textRole(.labelStrong)
        }, meta: {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                let lines = Self.timeLeft(task, now: AppClock.adjust(context.date))
                Text("Hold · \(lines.0) \(lines.1)")
                    .monospacedDigit()
            }
        })
        .accessibilityLabel("Finish \(task.title)")
    }

    /// A planned cook's key: GROCERIES while something is left to buy (Design on #700); at zero it becomes COOK
    /// (K87 "5 At zero", C8, B6), but only once cook mode exists, since a Cook key with no cook mode behind it is
    /// worse than none (G55). Until then the hero carries no key at zero.
    enum CookKey: Equatable {
        case groceries, cook, none
    }

    static func cookKey(toBuy: Int?, cookModeReady: Bool = RecipePage.cookModeReady) -> CookKey {
        if (toBuy ?? 0) > 0 {
            return .groceries
        }
        return cookModeReady ? .cook : .none
    }

    /// The recipe a planned cook task is about ("cook tacos thu" links it through `about`), nil for any other task.
    private func cookRecipe(of task: ObjectRecord) -> ObjectRecord? {
        guard let recipeClass = model.classDef(.recipe) else { return nil }
        return model.store.linkedObjects("about", of: task).first { object in
            !object.isDeleted && object.classDef.map { ClassResolver.isSubclass($0, of: recipeClass) } == true
        }
    }

    @ViewBuilder
    private func hero(_ task: ScheduleItem?, now: Date, facts: HomeFacts) -> some View {
        if let task, let record = model.object(task.id) {
            // A planned cook ("cook tacos thu") reads as the cook, with what's left to buy and a GROCERIES key
            // (kitchen gap hunt G19); any other task as his words.
            let recipe = cookRecipe(of: record)
            let fact = recipe.map { facts.fact(plannedCook: record, recipe: $0) }
                ?? facts.fact(task: record, startsAt: task.start)
            let line = HomeLines.line(for: fact, now: now)
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                LineHero(line: line, opens: .object(recipe?.id ?? task.id)) {
                    if recipe != nil {
                        switch Self.cookKey(toBuy: fact.toBuy) {
                        case .groceries:
                            PaintKey(paint: Theme.Colors.ink, isTap: true, action: { openLink(.groceries) },
                                     label: { _ in Text("Groceries").textRole(.labelStrong) })
                                .accessibilityHint("Opens Groceries")
                        case .cook:
                            PaintKey(paint: Theme.Colors.now, isTap: true,
                                     action: { model.open(.object(recipe?.id ?? task.id)) },
                                     label: { _ in Text("Cook").textRole(.labelStrong) })
                                .accessibilityHint("Opens the recipe to cook")
                        case .none:
                            EmptyView()
                        }
                    } else {
                        finishKey(task)
                    }
                }
                .id(task.id)
                .transition(heroTransition)
                // The countdown as time you can see: a wash that drains while the item runs.
                DrainBar(start: task.start, end: task.end)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(4)
            }
        } else if let routine = model.todaysRoutine(now: now) {
            LineHero(line: HomeLines.line(for: facts.fact(planned: routine, now: now), now: now),
                     opens: .object(routine.id))
            {
                if model.canStart(routine) {
                    PaintKey(paint: Theme.Colors.ink, isTap: true, action: { model.startRoutine(routine) },
                             label: { _ in Text("Start \(routine.title)").textRole(.labelStrong) })
                        .accessibilityLabel("Start \(routine.title)")
                }
            }
        } else if let done = model.finishedToday(now: now).first {
            // The counts live one tap down (41.1, 41.6).
            LineHero(line: HomeLines.line(for: facts.fact(done: done), now: now), opens: .object(done.workout.id)) {
                EmptyView()
            }
        } else if let cook = facts.cooksFinished(on: now).first {
            // "Tacos done." stays until his day ends at 4 AM, like a done workout (G19).
            LineHero(line: HomeLines.line(for: facts.fact(doneCook: cook), now: now), opens: .object(cook.id)) {
                EmptyView()
            }
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text("Nothing else is planned today.")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    onShow(.review)
                } label: {
                    Text("Look back at the week →")
                        .textRole(.bodyStrong)
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(HandleButtonStyle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .siblingParallax()
            .entrance(1)
        }
    }

    /// "now, until twenty to four" or "next, half past five".
    static func contextLine(_ task: ScheduleItem, now: Date) -> String {
        task.start <= now
            ? "now, until \(SpokenTime.clock(task.end))"
            : "next, \(SpokenTime.clock(task.start))"
    }

    /// ("14 MIN", "LEFT") while it runs, ("IN", "25 MIN") before it starts.
    static func timeLeft(_ task: ScheduleItem, now: Date) -> (String, String) {
        let isNow = task.start <= now
        let seconds = isNow ? task.end.timeIntervalSince(now) : task.start.timeIntervalSince(now)
        let minutes = max(Int((seconds / 60).rounded(.up)), 0)
        let amount = minutes >= 120 ? "\(minutes / 60) H" : "\(minutes) MIN"
        return isNow ? (amount, "LEFT") : ("IN", amount)
    }

    /// The next item writes itself in from the right: 18 pt of travel, blur 4 → 0, on the hero only.
    private var heroTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .modifier(
                active: HeroWriteIn(offset: 18, blur: 4, opacity: 0),
                identity: HeroWriteIn(offset: 0, blur: 0, opacity: 1)
            ),
            removal: .opacity
        )
    }

    private func finish(_ task: ScheduleItem) {
        finishes += 1
        let record = try? model.engine.perform(SetTaskDone(task: task.id, done: true), by: .user).record
        withTesseraAnimation(.smooth(duration: 0.34), reduceMotion: reduceMotion) {
            model.touch()
        }
        let hasNext = model.currentTask(around: AppClock.now) != nil
        TessVoice.shared.say(hasNext ? "Done. Next one is up." : "\(task.title), done.", undo: record)
    }
}

/// Now's countdown: a 2 pt hairline track with a dry 6 pt amber brushstroke over the elapsed part, growing to the
/// right as the item runs. No container and no rounded ends. Ticks once a second; the tip glides between ticks.
struct DrainBar: View {
    let start: Date
    let end: Date

    private static let height: CGFloat = 14

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = AppClock.adjust(context.date)
            let fraction = Self.remaining(start: start, end: end, now: now)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.Colors.ink.opacity(0.14))
                        .frame(height: 2)
                    // Ink at 51% with an amber leading edge (no-dots): the time, not a colour.
                    DryStroke()
                        .fill(LinearGradient(stops: [.init(color: Theme.Colors.ink.opacity(0.51), location: 0),
                                                     .init(color: Theme.Colors.ink.opacity(0.51), location: 0.85),
                                                     .init(color: Theme.Colors.now, location: 1)],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(proxy.size.width * (1 - fraction), 0), height: 6)
                        .blur(radius: 0.3)
                        .tesseraAnimation(.linear(duration: 1), value: fraction)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: Self.height)
            .accessibilityElement()
            .accessibilityLabel("Time left")
            .accessibilityValue("\(Int((fraction * 100).rounded())) percent")
        }
    }

    /// 1 before the start, draining to 0 at the end.
    static func remaining(start: Date, end: Date, now: Date) -> Double {
        let total = end.timeIntervalSince(start)
        guard total > 0, now > start else { return 1 }
        return min(max(end.timeIntervalSince(now) / total, 0), 1)
    }
}

/// A dry brushstroke as a filled shape: tapered, slightly ragged ends and a wavering edge, never a capsule.
private struct DryStroke: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width, height = rect.height
        guard width > 1 else { return Path() }
        let taper = min(8, width / 3)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + height * 0.1))
        path.addLine(to: CGPoint(x: rect.minX + taper * 0.4, y: rect.minY + height * 0.3))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - taper, y: rect.minY + height * 0.05),
                          control: CGPoint(x: rect.midX, y: rect.minY - height * 0.15))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY - height * 0.15))
        path.addLine(to: CGPoint(x: rect.maxX - taper * 0.3, y: rect.midY + height * 0.2))
        path.addLine(to: CGPoint(x: rect.maxX - taper * 0.7, y: rect.maxY - height * 0.05))
        path.addQuadCurve(to: CGPoint(x: rect.minX + taper, y: rect.maxY - height * 0.1),
                          control: CGPoint(x: rect.midX, y: rect.maxY + height * 0.1))
        path.closeSubpath()
        return path
    }
}

private struct HeroWriteIn: ViewModifier {
    let offset: CGFloat
    let blur: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .blur(radius: blur)
            .opacity(opacity)
    }
}

// MARK: - Later window

/// A capture that is still wet paint: everything cobalt, breathing, with a brushstroke painting along under it
/// as the commit timer. Tap to keep it now; swipe it sideways to drop it (nothing is written).
private struct GhostRow: View {
    let item: ScheduleItem
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stroke: CGFloat = 0
    @State private var drag: CGFloat = 0
    @State private var arrived = false
    @State private var accepted = false
    @State private var timeDried = false

    private func words(breath: Double) -> some View {
        let title = Text(item.title).font(Theme.voice)
        let time = Text(Format.clock(item.start)).font(Theme.Typography.font(Theme.concept.scale.label))
        return HStack(spacing: Theme.Spacing.m) {
            DryingWords(text: title, dried: accepted)
                .lineLimit(1)
            Spacer(minLength: Theme.Spacing.s)
            DryingWords(text: time, dried: timeDried)
                .monospacedDigit()
        }
        .opacity(accepted ? 1 : reduceMotion ? 0.6 : 0.5 + 0.16 * breath)
    }

    /// Accepting: the words dry from cobalt into ink, left to right (700 ms), the time 250 ms later, then it lands.
    private func accept() {
        guard !accepted else { return }
        withTesseraAnimation(.spring(Spring(duration: 0.7, bounce: 0)), reduceMotion: reduceMotion) { accepted = true }
        withTesseraAnimation(.spring(Spring(duration: 0.7, bounce: 0)).delay(0.25), reduceMotion: reduceMotion) {
            timeDried = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 950))
            model.commitCapture()
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
            words(breath: (sin(context.date.timeIntervalSinceReferenceDate / 1.6 * .pi) + 1) / 2)
        }
        .frame(maxHeight: .infinity)
        .overlay(alignment: .bottomLeading) {
            Brushstroke(progress: stroke)
                .stroke(Theme.Colors.tess.opacity(0.7), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(height: 8)
                .blur(radius: 0.4)
        }
        .offset(x: drag, y: arrived ? 0 : -10)
        .blur(radius: arrived ? 0 : 6)
        .opacity(arrived ? 1 - Double(min(abs(drag) / 200, 0.8)) : 0)
        .contentShape(Rectangle())
        .onTapGesture(perform: accept)
        .gesture(DragGesture(minimumDistance: 12).onChanged { drag = min(0, $0.translation.width) }.onEnded { value in
            if value.translation.width < -80 {
                withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { drag = -400 }
                model.discardCapture()
            } else {
                withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { drag = 0 }
            }
        })
        .onAppear {
            withTesseraAnimation(.easeOut(duration: 0.42), reduceMotion: reduceMotion) { arrived = true }
            // The commit timer, as visible time: the stroke paints along under the row over exactly 2 s.
            withAnimation(.linear(duration: AppModel.captureDryTime)) { stroke = 1 }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Proposed: \(item.title), \(Format.clock(item.start))")
        .accessibilityHint("Saves in two seconds. Double-tap to keep it now.")
        .accessibilityAction(named: "Drop it") { model.discardCapture() }
    }
}

/// One ledger row: the subject, the next step stated as time (never judgement) and a text-only Resume. Its state
/// is the seam 6 pt above it: suspended = 2 pt vermilion, lit and still; waiting = an engraved hairline.
struct LedgerRow: View {
    let process: ProcessSnapshot
    let now: Date
    @Environment(AppModel.self) private var model
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        let shown = Self.shown(process, store: model.store, classes: model.classes,
                               lastWeightKg: BodyWeight.lastKg(in: model.store))
        VStack(alignment: .leading, spacing: 6) {
            seam
            Button { model.resume(process) } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(shown.title)
                            .textRole(.bodyStrong)
                            .foregroundStyle(Theme.Colors.ink)
                        Text(step(shown.nextStep))
                            .font(Theme.voice(size: 18))
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer(minLength: Theme.Spacing.s)
                    // A paused thing isn't running: Resume rests in ink at 600 (no-dots C9).
                    Text("Resume").textRole(.body).fontWeight(.semibold).foregroundStyle(Theme.Colors.ink)
                }
                .frame(minHeight: 64)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(shown.title), \(step(shown.nextStep)). Resume")
        }
    }

    private var seam: some View {
        // One quiet engraved ink rule, suspended or not: no glow (no-dots C9, B11).
        Theme.Colors.hairline.frame(height: process.state == .suspended ? 1 : 1 / displayScale)
    }

    private func step(_ nextStep: String?) -> String {
        let ago = process.lastTouchedAt.map { Self.ago(now.timeIntervalSince($0)) }
        return [nextStep, ago].compactMap(\.self).joined(separator: ", ")
    }

    /// The row's name and next step. A list run never shows a walled name: its title is the shelf's shown name and
    /// its step is built from that and the live count, never the engine's stored "<title>, 6 left" (QA on #814).
    static func shown(_ process: ProcessSnapshot, store: ObjectStore, classes: [SystemCatalog.Key: ClassDef],
                      lastWeightKg: Double?) -> (title: String, nextStep: String?)
    {
        guard let subject = process.subject, let listClass = classes[.list], let subjectClass = subject.classDef,
              ClassResolver.isSubclass(subjectClass, of: listClass), subject.id != Groceries.listID
        else { return (process.subject?.title ?? process.object.title, process.nextStep) }
        let name = ListsShelf.shownName(store.displayTitle(of: subject), lastWeightKg: lastWeightKg)
        let left = ListContents(store: store, classes: classes).open(in: subject).count
        return (name, left == 0 ? "\(name), nothing left" : "\(name), \(left) left")
    }

    /// "just now", "21 min ago", "2 h ago" (never a mm:ss duration).
    static func ago(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 1 {
            return "just now"
        }
        if minutes < 60 {
            return "\(minutes) min ago"
        }
        return "\(minutes / 60) h ago"
    }
}

/// Cobalt words drying into ink: an ink copy is revealed over them left to right.
struct DryingWords: View {
    let text: Text
    let dried: Bool

    var body: some View {
        text.foregroundStyle(Theme.Colors.tess)
            .overlay(alignment: .leading) {
                text.foregroundStyle(Theme.Colors.ink)
                    .mask(alignment: .leading) {
                        GeometryReader { proxy in
                            Rectangle().frame(width: dried ? proxy.size.width : 0)
                        }
                    }
            }
    }
}

/// The plan's hero in the first form that fits: Hero 56 on one line, Title 44 on one line, then Title 44 wrapped
/// (plan-home.md: "Three tasks, Push A at 6" sits on two lines of 44 without the calendar). Static children only
/// (`ViewThatFits` traps on a `ForEach`).
private struct PlanHeroText: View {
    let forms: [String]

    var body: some View {
        let long = forms.first ?? ""
        ViewThatFits(in: .horizontal) {
            Text(long).textRole(.hero).lineLimit(1)
            Text(long).textRole(.title).lineLimit(1)
            Text(long).textRole(.title).fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Theme.Colors.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}
