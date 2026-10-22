import SwiftUI
import TesseraCore

/// The Routines landing (Design 131 §2 Routines, v2, approved Oct 22; build sheet §2): the app talks. Subtitle in the
/// rose, then the Thread with at most four sentences hanging from it: the top (what is running in large words, or
/// "Nothing is running" with Start words) and up to three lines, one per routine. Browse at the foot opens the index.
/// Everything here sits on the shared `LandingPage` frame, behind Settings › Review › "Landing pages" (default Off).
/// Only workout routines exist today; the default runner for morning and night routines is PR 3 and stays held.
struct RoutinesLandingPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var haptic = HapticCue()
    @State private var detail: RoutineDetailTarget?

    var body: some View {
        let _ = model.revision
        // "4 min on this step" moves, so the page re-reads every 30 s.
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            page(RoutinesFront(model: model, now: AppClock.now))
        }
        .background { ThemedBackground() }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        // Hiding the system back button drops the edge swipe; keep it (QA K1).
        .background { EdgeSwipeBack() }
        .tesseraFeedback(haptic)
        .sheet(item: $detail) { target in
            RoutineDetailSheet(id: target.id)
                .presentationDetents([.medium])
        }
    }

    private func page(_ front: RoutinesFront) -> some View {
        let accent = RoutinesFront.accent
        var subtitle = AttributedString(front.subtitle)
        subtitle.foregroundColor = accent
        // While one runs, only its name is rose; the rest of the line is ink-secondary.
        if let name = front.running?.name, let range = subtitle.range(of: name) {
            subtitle.foregroundColor = Theme.Colors.inkSecondary
            subtitle[range].foregroundColor = accent
        }
        let browse = LandingAction(word: RoutinesLandingWords.browse, hint: "Opens the index") {
            model.open(.routinesBrowse)
        }
        // The page carries exactly one accent underline: Pick up, else the first Start word, else Browse (Q3).
        let browseIsUnderlined = front.underlined == .browse
        return LandingPage(
            back: (title: cameFrom, action: { dismiss() }),
            title: "Routines",
            onTitle: { model.open(.routinesBrowse) },
            sentence: subtitle,
            accent: accent,
            lead: {
                RoutinesThread(front: front, accent: accent, actions: actions(front))
            },
            action: browseIsUnderlined ? browse : nil,
            secondary: browseIsUnderlined ? nil : browse
        )
    }

    /// "‹ Training" when he came from Training, whatever page is under this one otherwise.
    private var cameFrom: String {
        guard model.path.count >= 2 else { return "Training" }
        return model.title(of: model.path[model.path.count - 2])
    }

    private func actions(_ front: RoutinesFront) -> RoutinesActions {
        RoutinesActions(
            start: { item in
                if RoutinesStarter.start(item, running: front.running, model: model) {
                    haptic.play(.pickedUp)
                }
            },
            pickUp: { RoutinesStarter.pickUp(model: model) },
            open: { model.open(.object($0.id)) },
            openRunning: { id in
                if let id {
                    model.open(.object(id))
                }
            },
            detail: { detail = RoutineDetailTarget(id: $0.id) }
        )
    }
}

/// What the landing's rows can do; shared by the lines here and the rows on the Browse rail.
struct RoutinesActions {
    let start: (RoutinesFront.Item) -> Void
    let pickUp: () -> Void
    let open: (RoutinesFront.Item) -> Void
    let openRunning: (UUID?) -> Void
    let detail: (RoutinesFront.Item) -> Void
}

struct RoutineDetailTarget: Identifiable {
    let id: UUID
}

// MARK: - The Thread and what hangs from it

private struct RoutinesThread: View {
    let front: RoutinesFront
    let accent: Color
    let actions: RoutinesActions

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ThreadRow(kind: topKind, accent: accent) { top }
            ForEach(front.lines) { item in
                ThreadRow(kind: item.doneAt == nil ? .ahead : .ran, accent: accent) {
                    line(item)
                }
            }
        }
    }

    private var topKind: ThreadKind {
        if front.running != nil {
            return .running
        }
        return front.allDone ? .ran : .ahead
    }

    // MARK: The top

    @ViewBuilder
    private var top: some View {
        if let running = front.running {
            RunningTop(running: running, accent: accent, underlined: front.underlined == .pickUp, actions: actions)
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(front.allDone ? RoutinesLandingWords.everythingDone : RoutinesLandingWords.nothingRunning)
                    .font(Theme.voice(size: 28))
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if !front.allDone {
                    // Start words stack, one per line, so Dynamic Type never breaks one (AX5).
                    ForEach(Array(front.startWords.enumerated()), id: \.element.id) { index, item in
                        startWord(item, underlined: index == 0 && front.underlined == .firstStart)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func startWord(_ item: RoutinesFront.Item, underlined: Bool) -> some View {
        let word = RoutinesLandingWords.start(item.name)
        if underlined {
            Button(word) { actions.start(item) }
                .buttonStyle(LandingLinkStyle(accent: accent))
        } else {
            Button(word) { actions.start(item) }
                .buttonStyle(LandingWordStyle())
        }
    }

    // MARK: A line

    private func line(_ item: RoutinesFront.Item) -> some View {
        StartSwipeRow(
            startWord: "Start",
            accent: accent,
            onStart: { actions.start(item) },
            onOpen: { actions.open(item) },
            onDetail: { actions.detail(item) }
        ) {
            Text(item.line)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.spokenLine)
        .accessibilityHint("Opens \(item.name)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Start") { actions.start(item) }
        .accessibilityAction(named: "Details") { actions.detail(item) }
    }
}

/// While a routine runs: "{Name} is running" (name in the rose), the step in large words, "4 min on this step", and
/// Pick up. Tap the step or Pick up to go on; hold the step for the routine's page.
private struct RunningTop: View {
    let running: RoutinesFront.Running
    let accent: Color
    let underlined: Bool
    let actions: RoutinesActions

    var body: some View {
        let sentence = LandingSentences.routineRunning(running.name)
        let onStep = LandingSentences.onThisStep(seconds: running.seconds)
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(LandingText.build(sentence, accent: accent))
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: actions.pickUp) {
                Text(running.step)
                    // 40 pt, scaling with Dynamic Type, wrapping rather than cutting.
                    .font(Theme.voice(size: 40).weight(.medium))
                    .foregroundStyle(Theme.Colors.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                actions.openRunning(running.routineID)
            })
            Text(onStep)
                .font(Theme.voice(size: 19).weight(.light))
                .monospacedDigit()
                .foregroundStyle(Theme.Colors.inkSecondary)
            if underlined {
                Button(RoutinesLandingWords.pickUp, action: actions.pickUp)
                    .buttonStyle(LandingLinkStyle(accent: accent))
            } else {
                Button(RoutinesLandingWords.pickUp, action: actions.pickUp)
                    .buttonStyle(LandingWordStyle())
            }
        }
        // One element: "Morning is running. Step: Shoes on. 4 minutes on this step." with Pick up as its action.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(RoutinesLandingWords.spokenTop(name: running.name, step: running.step,
                                                           onStep: spoken(onStep)))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, actions.pickUp)
        .accessibilityAction(named: RoutinesLandingWords.pickUp, actions.pickUp)
    }

    /// "4 min on this step" read as "4 minutes on this step".
    private func spoken(_ words: String) -> String {
        words.replacingOccurrences(of: " min ", with: " minutes ")
    }
}

// MARK: - Swipe right to start

/// A row that opens on a tap, shows its details on a hold, and starts on a swipe right past 90 pt (the rail rule).
/// Swipe left does nothing yet and springs back (Product Q1 default). The row is a plain line: no card, no shape.
struct StartSwipeRow<Content: View>: View {
    let startWord: String
    let accent: Color
    let onStart: () -> Void
    let onOpen: () -> Void
    let onDetail: () -> Void
    @ViewBuilder let content: Content

    @State private var pull: CGFloat = 0
    /// A sideways drag or a hold owns the touch: the row doesn't also open on the lift.
    @State private var handled = false
    @State private var armed = false
    @State private var cue = HapticCue()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static var arm: CGFloat {
        90
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Text(startWord)
                .textRole(.bodyStrong)
                .foregroundStyle(accent)
                .opacity(Double(min(max((pull - 56) / (Self.arm - 56), 0), 1)))
                .accessibilityHidden(true)
            Button {
                guard !handled else { return }
                onOpen()
            } label: {
                content
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .offset(x: pull)
        }
        .simultaneousGesture(swipe)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
            hold()
            onDetail()
        })
        .tesseraFeedback(cue)
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                handled = true
                // Right only; left stays put.
                pull = max(value.translation.width, 0)
                if pull >= Self.arm, !armed {
                    armed = true
                    cue.play(.selection)
                } else if pull < Self.arm {
                    armed = false
                }
            }
            .onEnded { _ in
                let started = pull >= Self.arm
                armed = false
                withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { pull = 0 }
                if started {
                    onStart()
                }
                // After the button has seen the lift, a tap opens the row again.
                release()
            }
    }

    private func hold() {
        handled = true
        release()
    }

    private func release() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            handled = false
        }
    }
}

// MARK: - Starting

/// Start and Pick up for a workout routine, the one live workout the app has. Start makes today's workout the way
/// Training's START does, but stays on the page: the top becomes "{Name} is running" and Tess says so with UNDO for
/// 10 s, which ends the fresh run and logs nothing. Pick up opens the live workout on the step it is on.
@MainActor
enum RoutinesStarter {
    /// Whether a run started.
    @discardableResult
    static func start(_ item: RoutinesFront.Item, running: RoutinesFront.Running?, model: AppModel) -> Bool {
        if let running {
            if running.routineID == item.id {
                pickUp(model: model)
            } else {
                TessVoice.shared.say("\(running.name) is running.")
            }
            return false
        }
        guard model.session == nil, model.canStart(item.record),
              let result = try? model.engine.perform(StartRoutine(routine: item.id, time: AppClock.now), by: .user)
        else { return false }
        let workout = result.output
        model.session = WorkoutSession(workout: workout, model: model)
        model.touch()
        let name = item.name
        let record = result.record
        TessVoice.shared.say("\(name) is running", takeBack: { [model] in
            if takeBack(workout: workout, record: record, model: model) {
                Task { @MainActor in TessVoice.shared.say(Receipt.takenBack(name)) }
            } else if model.session?.workout.id == workout.id {
                // A set is logged (or the undo would not fully apply): the run stays.
                Task { @MainActor in TessVoice.shared.say("\(name) has a set in, so it stays.") }
            }
        })
        return true
    }

    /// A set under the workout: UNDO of the start never takes a logged set with it.
    static func hasLoggedSets(_ workout: ObjectRecord) -> Bool {
        workout.orderedChildren.filter { !$0.isDeleted }.contains { entry in
            entry.orderedChildren.contains { !$0.isDeleted }
        }
    }

    /// Ends the fresh run the start made and logs nothing. Refused (and the session kept) when any set exists under
    /// the workout, or when the undo does not fully apply (it is put back).
    @discardableResult
    static func takeBack(workout: ObjectRecord, record: OpRecord, model: AppModel) -> Bool {
        guard model.session?.workout.id == workout.id, !hasLoggedSets(workout) else { return false }
        guard model.engine.undo(record) == .applied else {
            model.engine.redo(record)
            return false
        }
        model.session = nil
        model.isWorkoutPresented = false
        model.touch()
        return true
    }

    static func pickUp(model: AppModel) {
        guard model.session != nil else { return }
        model.isWorkoutPresented = true
    }
}

// MARK: - Details

/// A hold on a routine: its usual start and length, its exercises and its kind, as plain lines.
struct RoutineDetailSheet: View {
    let id: UUID
    @Environment(AppModel.self) private var model

    var body: some View {
        let front = RoutinesFront(model: model, now: AppClock.now)
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            if let item = front.item(id) {
                Text(item.name)
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                if let usual = item.usual {
                    Text("Usually starts \(RoutinesLandingWords.clock(usual.startMinuteOfDay))")
                    Text("Usually \(HouseTime.minutes(usual.lengthMinutes))")
                } else {
                    Text("Usual start and length show after 7 runs.")
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
                if !item.isPrivate {
                    Text(RoutinesLandingWords.countWords(item.exercises, workout: true))
                }
                Text("A workout routine")
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
        }
        .textRole(.body)
        .foregroundStyle(Theme.Colors.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.gutter)
        .padding(.top, Theme.Spacing.xl)
        .frame(maxHeight: .infinity, alignment: .top)
        .background { ThemedBackground() }
    }
}
