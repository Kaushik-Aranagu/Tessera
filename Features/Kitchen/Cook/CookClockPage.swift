import SwiftUI
import TesseraCore
import UIKit

/// The clock page: the cook's time view (Design 69, ruled the cook itself by G228). A dark ground like the workout,
/// the recipe laid on a vertical rail of minutes with a bead where he is, this step large with the one before it dim
/// above and the next two dim below, a horizon line from the top edge for each running timer, and one key row. The
/// swipe up or down is the only way to change step; the voice words and VoiceOver's actions do the same. Nothing
/// counts:
/// every figure is derived from each timer's `endsAt`, and the redraws are the system's.
struct CookClockPage: View {
    let cookID: UUID
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.lowPowerMotion) private var inheritedLowPower
    @State private var session: CookClockSession?
    @State private var hands: HandsFreeController?
    @State private var showsIngredients = false
    @State private var showsTimers = false
    @State private var note = ""
    @State private var metric = false
    @State private var hintsLeft = UserDefaults.standard.object(forKey: "cookSwipeHints") as? Int ?? 3
    @State private var lowPower = PowerState.isLowPower
    @State private var stepCue = HapticCue()
    @FocusState private var noteFocused: Bool

    private var calm: Bool {
        reduceMotion || lowPower || inheritedLowPower
    }

    var body: some View {
        ZStack {
            Theme.Colors.Workout.ground.ignoresSafeArea()
            if let session {
                page(session)
            } else {
                gone
            }
        }
        .environment(\.onWorkoutGround, true)
        .preferredColorScheme(.dark)
        .statusBarHidden(false)
        .onAppear(perform: begin)
        // Surfaces v2: the Cook Live Activity follows the cook's timers and step (a no-op with the switch Off).
        .onChange(of: session?.timers) { CookActivityDriver.shared.update(for: session) }
        .onChange(of: session?.current) { CookActivityDriver.shared.update(for: session) }
        .onDisappear(perform: leave)
        .onReceive(PowerState.changes) { _ in lowPower = PowerState.isLowPower }
        .onChange(of: scenePhase) { _, phase in
            guard let session else { return }
            if phase == .active {
                session.reconcileFlares(at: AppClock.now, live: false)
                session.armEnd()
            } else {
                session.pauseArming()
                hands?.close()
            }
            refreshAwake()
        }
        .sheet(isPresented: $showsTimers) {
            if let session {
                TimersSheet(session: session, calm: calm)
                    .presentationDetents([.medium, .large])
                    .presentationBackground(Theme.Colors.Workout.ground)
            }
        }
        .tesseraFeedback(session?.cue ?? HapticCue())
    }

    private var gone: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Cook gone")
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.Workout.inkSecondary)
            Button("Back to the recipe") { dismiss() }
                .buttonStyle(.labelWord(Theme.Colors.Workout.ink))
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // MARK: Page

    private func page(_ session: CookClockSession) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar(session)
            header(session)
            ZStack {
                if showsIngredients {
                    IngredientPeek(session: session, metric: $metric, calm: calm)
                        .transition(.opacity)
                } else {
                    stage(session)
                        .transition(.opacity)
                }
            }
            .frame(maxHeight: .infinity)
            .tesseraAnimation(.easeOut(duration: 0.15), value: showsIngredients)
            timerLines(session)
            receipt(session)
            keyRow(session)
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .padding(.bottom, Theme.Spacing.s)
        .overlay(alignment: .top) {
            CookHorizons(session: session, calm: calm, active: scenePhase == .active)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .top) {
            FlareBand(session: session, calm: calm)
                .padding(.top, 118)
                .padding(.horizontal, Theme.Spacing.gutter)
        }
        .contentShape(Rectangle())
        .onTapGesture { session.touched() }
    }

    private func topBar(_: CookClockSession) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Button {
                dismiss()
            } label: {
                Text("Recipes")
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.Workout.inkSecondary)
                    .frame(minHeight: 44)
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityLabel("Back to Recipes")
            .accessibilityHint("The cook keeps going")
            Spacer()
            if let hands {
                ListeningMark(controller: hands, calm: calm)
            }
        }
        .padding(.top, Theme.Spacing.xl)
    }

    private func header(_ session: CookClockSession) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(session.recipeName)
                .textRole(.label)
                .foregroundStyle(Theme.Colors.Workout.inkSecondary)
            if session.tracks.count == 1 {
                Text(CookModeCopy.step(session.current, of: session.steps.count))
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.Workout.inkTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(CookModeCopy.heading(recipe: session.recipeName, lastWeightKg: nil))
        .accessibilityAddTraits(.isHeader)
    }

    /// The rail and the steps side by side; the vertical swipe turns the lead track's step.
    private func stage(_ session: CookClockSession) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.l) {
            if !typeSize.isAccessibilitySize {
                ClockRail(session: session, calm: calm, active: scenePhase == .active)
                    .frame(width: 30)
                    .padding(.top, Theme.Spacing.m)
                    .accessibilityHidden(true)
            }
            StepStack(session: session, calm: calm, hintsLeft: hintsLeft, move: { forward in
                move(session, forward: forward)
            })
        }
        .padding(.top, Theme.Spacing.m)
    }

    private func move(_ session: CookClockSession, forward: Bool) {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: calm) {
            _ = forward ? session.next() : session.back()
        }
        if hintsLeft > 0 {
            hintsLeft -= 1
            UserDefaults.standard.set(hintsLeft, forKey: "cookSwipeHints")
        }
        refreshAwake()
    }

    // MARK: Timers under the step

    @ViewBuilder private func timerLines(_ session: CookClockSession) -> some View {
        let spoken = session.spokenTimers
        let other = session.other
        if !spoken.isEmpty || other != nil {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                if let other {
                    Button {
                        withTesseraAnimation(Theme.Motion.house, reduceMotion: calm) { session.lead(1 - session.lead) }
                    } label: {
                        Text(session.text(of: other))
                            .multilineTextAlignment(.leading)
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.Workout.inkSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: CookModeCopy.minTarget(accessibilitySize: typeSize.isAccessibilitySize))
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityLabel(CookClockCopy.meanwhile(
                        step: other, of: session.steps.count, text: session.text(of: other),
                        left: session.timer(ofStep: other).map { $0.remaining(at: AppClock.now) }
                    ))
                    .accessibilityHint("Makes this the step you move")
                }
                ForEach(spoken) { line in
                    SpokenTimerRow(session: session, line: line, calm: calm, active: scenePhase == .active)
                }
            }
            .padding(.top, Theme.Spacing.s)
            .transition(.opacity)
        }
    }

    // MARK: Receipt and keys

    @ViewBuilder private func receipt(_ session: CookClockSession) -> some View {
        if let receipt = session.receipt {
            HStack(alignment: .firstTextBaseline) {
                Text(receipt.text)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.Workout.tess)
                    .contentTransition(.opacity)
                Spacer()
                if receipt.undo != nil {
                    Button("Undo") { session.undo(receipt) }
                        .buttonStyle(.labelWord(Theme.Colors.Workout.signal))
                        .frame(minHeight: 44)
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
            .transition(.opacity)
            .id(receipt.id)
        }
    }

    private func keyRow(_ session: CookClockSession) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if session.isLast, Choice.cookNotesIsOn() {
                // The optional line on Finish: empty by default, adds no step (CN-S3).
                TextField(CookNotes.prompt, text: $note, axis: .vertical)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.Workout.ink)
                    .focused($noteFocused)
                    .submitLabel(.done)
                    .lineLimit(1 ... 3)
                    .frame(minHeight: 44)
                    .accessibilityLabel(CookNotes.prompt)
            }
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let now = AppClock.adjust(context.date)
                KeyFigure(session: session, now: now)
            }
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xl) {
                word(showsIngredients ? CookClockCopy.steps : CookClockCopy.ingredients,
                     hint: showsIngredients ? "Shows the steps" : "Shows the ingredient list")
                {
                    showsIngredients.toggle()
                }
                word(CookClockCopy.timers, hint: "Shows every timer, and starts one") { showsTimers = true }
                Spacer(minLength: 0)
            }
            if session.isLast {
                PaintKey(paint: Theme.Colors.Workout.signal, hint: CookModeCopy.finishHint,
                         action: { done(session) }, label: { _ in Text(CookModeCopy.done) },
                         meta: { Text("Hold") })
                    .finishing(by: CookModeCopy.finishAction)
                    .frame(minHeight: CookModeCopy.minTarget(accessibilitySize: typeSize.isAccessibilitySize))
            }
        }
        .tesseraAnimation(.easeOut(duration: 0.15), value: session.isLast)
    }

    private func word(_ text: String, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.Workout.ink)
                .underline(true, color: Theme.Colors.Workout.ink.opacity(0.4))
                .frame(minHeight: CookModeCopy.minTarget(accessibilitySize: typeSize.isAccessibilitySize))
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityHint(hint)
    }

    private func done(_ session: CookClockSession) {
        let spoken = session.pendingNote
        let written = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = written.isEmpty ? spoken : written
        if session.finish(note: Choice.cookNotesIsOn() ? text : nil) {
            _ = DonePattern.play()
            dismiss()
        }
    }

    // MARK: Lifecycle

    private func begin() {
        guard session == nil else { return }
        guard let made = CookClockSession(model: model, cookID: cookID) else { return }
        session = made
        if Choice.handsFreeCookIsOn() {
            hands = HandsFreeController(session: made)
        }
        // `-cookScript "next|timer bread 8|back"` (simulator only): plays commands in, 2.5 s apart, for recordings.
        if let script = LaunchFlags.value(after: "-cookScript") {
            Task { @MainActor in
                for phrase in script.split(separator: "|") {
                    try? await Task.sleep(for: .milliseconds(2500))
                    withTesseraAnimation(Theme.Motion.house, reduceMotion: calm) {
                        made.handle(HandsFreeGrammar.parse(String(phrase)))
                    }
                }
            }
        }
        made.armEnd()
        made.reconcileFlares(at: AppClock.now, live: false)
        DonePattern.prepare()
        refreshAwake()
        Task { @MainActor in
            // The screen stays awake only while it can (G218); checked every 20 s, and by every touch.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(20))
                refreshAwake()
            }
        }
    }

    private func leave() {
        hands?.close()
        session?.pauseArming()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func refreshAwake() {
        guard let session else { return }
        UIApplication.shared.isIdleTimerDisabled = scenePhase == .active && session.keepsAwake(at: AppClock.now)
    }
}
