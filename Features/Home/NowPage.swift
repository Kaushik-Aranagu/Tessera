import SwiftUI
import TesseraCore

/// TODAY: the day stroke, the one current thing as the hero, hold to finish, a short "Later" window and, when a
/// workout is running, one quiet line to get back to it. Grouping is by space and type alone.
struct NowPage: View {
    /// Pages Home to a sibling (used by the empty state).
    var onShow: (HomeSpatialView.Page) -> Void = { _ in }

    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finishes = 0
    /// The current Now, passed back to the ranker so it holds against equal challengers (no flicker).
    @State private var incumbent: UUID?

    var body: some View {
        let _ = model.revision
        let now = AppClock.now
        let lanes = HomeData.lanes(model, now: now)
        let schedule = model.schedule(around: now)
        // Now comes from Core's ranker (rest day, the 15-minute override, re-entry, the scored rank). It re-runs
        // when the data changes (revision) and as the clock moves, never on its own timer.
        let top = rank(now: now).first
        let ranked = top?.item.kind == .task ? schedule.first { $0.id == top?.item.id } : nil
        let current = ranked ?? model.currentTask(around: now)

        VStack(alignment: .leading, spacing: 0) {
            HomeDayStrip(lanes: lanes)
                .entrance(0)
                .padding(.bottom, Theme.Spacing.l)

            Group {
                // A running process is Now (docs/product/whats-running.md).
                if let session = model.session, model.processes.running()?.subject?.id == session.workout.id {
                    RunningHero(session: session)
                } else if let top, top.item.kind == .rest {
                    RestHero(next: top.item.object)
                } else {
                    hero(current, now: now)
                }
            }
            .padding(.bottom, Theme.Spacing.xl)

            // The ledger: suspended processes (v1: a workout left idle), at most three, state in the seam above.
            ForEach(model.processes.ledger(now: now)) { process in
                LedgerRow(process: process, now: now)
                    .padding(.bottom, Theme.Spacing.l)
                    .transition(.offset(y: 10).combined(with: .opacity))
            }

            let queue = QueueEntry.split(model: model, schedule: schedule, current: current, now: now)
            QueueWindow(next: queue.next, later: queue.later)
                .entrance(4)

            Spacer(minLength: 0)
        }
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.8), trigger: finishes)
        .onChange(of: top?.id, initial: true) { _, id in
            incumbent = id
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

    @ViewBuilder
    private func hero(_ task: ScheduleItem?, now: Date) -> some View {
        if let task {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text(Self.contextLine(task, now: now))
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
                    .contentTransition(.opacity)
                    .entrance(1)

                ZStack(alignment: .topLeading) {
                    Button {
                        model.open(.object(task.id))
                    } label: {
                        HeroText(text: task.title) { $0 }
                            .foregroundStyle(Theme.Colors.ink)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(HandleButtonStyle())
                    .modifier(ZoomSource(id: Route.object(task.id), namespace: namespace))
                    .accessibilityHint("Opens \(task.title)")
                    .id(task.id)
                    .transition(heroTransition)
                }
                .siblingParallax()
                .entrance(2, hero: true)
                .padding(.bottom, Theme.Spacing.l)

                HStack(alignment: .center, spacing: Theme.Spacing.l) {
                    PaintKey(duration: 0.7, action: { finish(task) }, label: { _ in
                        Text("Finish")
                    }, meta: {
                        TimelineView(.periodic(from: .now, by: 30)) { context in
                            let lines = Self.timeLeft(task, now: AppClock.adjust(context.date))
                            Text("Hold · \(lines.0) \(lines.1)")
                                .monospacedDigit()
                        }
                    })
                    .accessibilityLabel("Finish \(task.title)")
                    .accessibilityHint("Touch and hold")
                }
                .entrance(3)
                // The countdown as time you can see: a wash that drains while the item runs.
                DrainBar(start: task.start, end: task.end)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(4)
            }
        } else if let routine = model.todaysRoutine(now: now) {
            RoutineHero(routine: routine)
        } else if let done = model.finishedToday(now: now).first {
            DoneHero(summary: done, onShow: onShow)
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

    /// "now, until twenty to four" or "next, at half past five".
    static func contextLine(_ task: ScheduleItem, now: Date) -> String {
        task.start <= now
            ? "now, until \(SpokenTime.clock(task.end))"
            : "next, at \(SpokenTime.clock(task.start))"
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
        TessVoice.shared.say(hasNext ? "Done. Next one is up." : "Done. \(task.title).", undo: record)
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
                    DryStroke()
                        .fill(HomePaint.dayAmber.opacity(0.85))
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

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
            let breath = (sin(context.date.timeIntervalSinceReferenceDate / 1.6 * .pi) + 1) / 2
            HStack(spacing: Theme.Spacing.m) {
                PaintDab(color: Theme.Colors.tess, seed: item.title.count)
                    .blur(radius: 1.5)
                Text(item.title)
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.tess)
                    .lineLimit(1)
                Spacer(minLength: Theme.Spacing.s)
                Text(Format.clock(item.start))
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.tess)
                    .monospacedDigit()
            }
            .opacity(reduceMotion ? 0.6 : 0.5 + 0.16 * breath)
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
        .onTapGesture { model.commitCapture() }
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

/// Trained today and nothing else on: the workout, saved, with Tess's one count line.
private struct DoneHero: View {
    let summary: WorkoutSummary
    var onShow: (HomeSpatialView.Page) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text(summary.endedAt.map { "trained this \(SpokenTime.partOfDay($0))" } ?? "trained today")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
                .entrance(1)
            Button {
                onShow(.training)
            } label: {
                HeroText(text: summary.title) { $0 }
                    .foregroundStyle(Theme.Colors.ink)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityLabel("\(summary.title), done")
            .accessibilityHint("Shows today's training")
            .siblingParallax()
            .entrance(2, hero: true)
            Text(summary.line)
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.tess)
                .fixedSize(horizontal: false, vertical: true)
                .entrance(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Nothing else on: the plan's next routine is Now, with one key into live mode.
/// A planned rest day: one quiet line, no guilt, and the next routine one tap away as a label word.
private struct RestHero: View {
    let next: ObjectRecord
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("today")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
                .entrance(1)
            HeroText(text: RestDay.line) { $0 }
                .foregroundStyle(Theme.Colors.ink)
                .siblingParallax()
                .entrance(2, hero: true)
            Text("\(next.title) is a tap away.")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
                .entrance(3)
            Button("Start \(next.title)") { model.startRoutine(next) }
                .buttonStyle(InkLabelWordStyle(color: Theme.Colors.live))
                .accessibilityHint("Starts \(next.title) anyway")
                .entrance(3)
        }
    }
}

private struct RoutineHero: View {
    let routine: ObjectRecord
    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace

    var body: some View {
        let slots = routine.orderedChildren.count
        let sets = routine.orderedChildren.reduce(0) { $0 + Int(model.store.number("sets", of: $1) ?? 3) }
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("today's training")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
                .entrance(1)
            Button {
                model.open(.object(routine.id))
            } label: {
                HeroText(text: routine.title) { $0 }
                    .foregroundStyle(Theme.Colors.ink)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .modifier(ZoomSource(id: Route.object(routine.id), namespace: namespace))
            .accessibilityHint("Opens \(routine.title)")
            .siblingParallax()
            .entrance(2, hero: true)
            .padding(.bottom, Theme.Spacing.l)
            HStack(alignment: .center, spacing: Theme.Spacing.l) {
                PaintKey(isTap: true, action: { model.startRoutine(routine) }, label: { _ in
                    Text("Start")
                })
                .accessibilityLabel("Start \(routine.title)")
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(slots) EXERCISES")
                    Text("\(sets) SETS")
                }
                .textRole(.label)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .accessibilityElement(children: .combine)
            }
            .entrance(3)
        }
    }
}

/// The live workout as Now: "running now, Push Day A", the resume point as the hero and one vermilion Resume key
/// (docs/design/home-v1.md, "What's running").
private struct RunningHero: View {
    let session: WorkoutSession
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("running now, \(session.workout.title)")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
            HeroText(text: resumePoint) { $0 }
                .foregroundStyle(Theme.Colors.ink)
                .siblingParallax()
                .padding(.bottom, Theme.Spacing.l)
            HStack(alignment: .center, spacing: Theme.Spacing.l) {
                PaintKey(finish: .ink, paint: Theme.Colors.live, isTap: true,
                         action: { model.isWorkoutPresented = true }, label: { _ in
                             Text("Resume")
                         })
                         .tint(Theme.Colors.live)
                         .accessibilityLabel("Resume \(session.workout.title), \(resumePoint)")
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let lines = state(now: AppClock.adjust(context.date))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(lines.0)
                        Text(lines.1).contentTransition(.numericText(countsDown: true))
                    }
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .monospacedDigit()
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var resumePoint: String {
        let exercise = session.currentExercise?.name ?? "Workout"
        guard let entry = session.currentEntry else { return exercise }
        return "\(exercise), set \(session.currentSetNumber) of \(session.targetSets(of: entry))"
    }

    private func state(now: Date) -> (String, String) {
        switch session.phase(at: now) {
        case let .rest(end): ("Resting", Format.duration(max(0, end.timeIntervalSince(now)).rounded(.up)))
        case .set: ("Set \(session.currentSetNumber)", "is up")
        case .exerciseDone: ("Next", "exercise")
        case .workoutDone: ("Ready", "to finish")
        }
    }
}

/// One ledger row: the subject, the next step stated as time (never judgement) and a text-only Resume. Its state
/// is the seam 6 pt above it: suspended = 2 pt vermilion, lit and still; waiting = an engraved hairline.
private struct LedgerRow: View {
    let process: ProcessSnapshot
    let now: Date
    @Environment(AppModel.self) private var model
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            seam
            Button { model.resume(process) } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(process.subject?.title ?? process.object.title)
                            .textRole(.bodyStrong)
                            .foregroundStyle(Theme.Colors.ink)
                        Text(step)
                            .font(Theme.voice(size: 18))
                            .foregroundStyle(Color(hex: 0x6E6480))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer(minLength: Theme.Spacing.s)
                    Text("Resume").textRole(.bodyStrong).foregroundStyle(Theme.Colors.live)
                }
                .frame(minHeight: 64)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(process.subject?.title ?? process.object.title), \(step). Resume")
        }
    }

    @ViewBuilder private var seam: some View {
        if process.state == .suspended {
            Theme.Colors.live
                .frame(height: 2)
                .shadow(color: Theme.Colors.live.opacity(0.45), radius: 4)
        } else {
            VStack(spacing: 0) {
                Theme.Colors.ink.opacity(0.12).frame(height: 1 / displayScale)
                Color.white.opacity(0.8).frame(height: 1 / displayScale)
            }
        }
    }

    private var step: String {
        let ago = process.lastTouchedAt.map { Self.ago(now.timeIntervalSince($0)) }
        return [process.nextStep, ago].compactMap(\.self).joined(separator: ", ")
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
