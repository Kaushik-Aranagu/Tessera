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

    var body: some View {
        let _ = model.revision
        let now = AppClock.now
        let lanes = HomeData.lanes(model, now: now)
        let schedule = model.schedule(around: now)
        let current = model.currentTask(around: now)
        let upcoming = HomeData.upcoming(schedule, excluding: current, now: now)

        VStack(alignment: .leading, spacing: 0) {
            HomeDayStrip(lanes: lanes)
                .entrance(0)
                .padding(.bottom, Theme.Spacing.l)

            Group {
                // A running process is Now (docs/product/whats-running.md).
                if let session = model.session, model.processes.running()?.subject?.id == session.workout.id {
                    RunningHero(session: session)
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

            if !upcoming.isEmpty {
                Text("Later")
                    .font(Theme.voice(size: 34))
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, Theme.Spacing.s)
                    .entrance(4)
                LaterWindow(items: upcoming)
                    .entrance(5)
            }

            Spacer(minLength: 0)
        }
        .sensoryFeedback(.success, trigger: finishes)
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
                    PaintKey(duration: 0.7, action: { finish(task) }, label: { holding in
                        Text(holding ? "Keep holding" : "Hold to finish")
                            .textRole(.bodyStrong)
                    })
                    .frame(width: 220)
                    .accessibilityLabel("Finish \(task.title)")
                    .accessibilityHint("Touch and hold")
                    TimelineView(.periodic(from: .now, by: 30)) { context in
                        let lines = Self.timeLeft(task, now: AppClock.adjust(context.date))
                        VStack(alignment: .leading, spacing: 0) {
                            Text(lines.0)
                            Text(lines.1)
                        }
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .monospacedDigit()
                        .accessibilityElement(children: .combine)
                    }
                }
                .entrance(3)
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
        withTesseraAnimation(.smooth(duration: 0.34), reduceMotion: reduceMotion) {
            model.finish(taskID: task.id)
        }
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

/// A bounded window, 92 pt tall (about two rows), snapping per 50 pt row and fading out at the bottom. No
/// separators, no ruler.
private struct LaterWindow: View {
    let items: [ScheduleItem]

    static let rowHeight: CGFloat = 50
    static let height: CGFloat = 92

    var body: some View {
        let height = min(Self.height, Self.rowHeight * CGFloat(items.count))
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    LaterRow(item: item)
                        .frame(height: Self.rowHeight)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: height)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0.6),
                    .init(color: .black.opacity(items.count > 2 ? 0 : 1), location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Later, \(items.count) items")
    }
}

private struct LaterRow: View {
    let item: ScheduleItem
    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var namespace

    var body: some View {
        if model.isGhost(item.id) {
            GhostRow(item: item)
        } else {
            row
        }
    }

    private var row: some View {
        Button {
            model.open(.object(item.id))
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                PaintDab(color: item.isWorkout ? Theme.Colors.live : Theme.Colors.context, seed: item.title.count)
                Text(item.title)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                Spacer(minLength: Theme.Spacing.s)
                Text(Format.clock(item.start))
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .monospacedDigit()
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .modifier(ZoomSource(id: Route.object(item.id), namespace: namespace))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(Format.clock(item.start))")
        .accessibilityHint("Opens \(item.title)")
    }
}

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
                    Text("Start").textRole(.bodyStrong)
                })
                .frame(width: 220)
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
                             Text("Resume").textRole(.bodyStrong)
                         })
                         .tint(Theme.Colors.live)
                         .frame(width: 220)
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
        let ago = process.lastTouchedAt.map { Format.duration(now.timeIntervalSince($0)) + " ago" }
        return [process.nextStep, ago].compactMap(\.self).joined(separator: ", ")
    }
}
