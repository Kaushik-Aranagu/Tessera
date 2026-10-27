import SwiftUI
import TesseraCore

/// Routine mode (sheets 323 and 329): the whole evening. A dusk gradient that darkens with every step tended, so by
/// the last step it is night; the step and move count, the move in Figtree extra bold at 84 pt (it shrinks to fit,
/// never cut), the cue in Newsreader italic (Tess's voice), the breath in words only (4 s in, 6 s out), the time left
/// in
/// Outfit at 96 pt, the step's moves with their times. Next is the verb; Pause and Not tonight sit under it; swipe up
/// anywhere is Next. Skipping never breaks a streak. Behind the "Routine mode" switch (On).
struct RoutineModePage: View {
    let routineID: UUID
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var run: RoutineModeRun?
    @State private var name = ""
    @State private var total = 0
    @State private var wrote = false
    @State private var cue = HapticCue()

    var body: some View {
        let dusk = run?.dusk ?? 0
        ZStack {
            RoutineDusk.gradient(dusk).ignoresSafeArea()
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.2), value: dusk)
            if let run {
                LiveClock(LiveFeatures.routineClock, minimumInterval: 1, paused: scenePhase != .active) { context in
                    let now = AppClock.adjust(context.date)
                    let data = RoutineScreen(run, name: name, totalMinutes: total, now: now)
                    screen(data, now: now)
                        // Sheet 335: the sky and the words dim together on the last step; kept under Reduce Motion.
                        .overlay {
                            Color.black.opacity(1 - data.brightness).ignoresSafeArea().allowsHitTesting(false)
                        }
                }
            }
        }
        .preferredColorScheme(dusk > 0.45 ? .dark : .light)
        .onAppear(perform: begin)
        .task {
            // The clock moves the run on: a move whose time is up gives way to the next, by itself.
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard scenePhase == .active, var current = run, !current.finished else { continue }
                current.tick(now: AppClock.now)
                if current != run {
                    change(current)
                }
            }
        }
        .tesseraFeedback(cue)
    }

    private func screen(_ data: RoutineScreen, now _: Date) -> some View {
        let ink = RoutineDusk.ink(data.dusk)
        let soft = RoutineDusk.soft(data.dusk)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Button { dismiss() } label: {
                    Text(data.title.uppercased())
                        .font(.custom("Figtree", fixedSize: 16).weight(.bold))
                        .tracking(16 * 0.1)
                        .foregroundStyle(soft)
                        .frame(minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to the Watch")
                Spacer()
                Text(data.topRight)
                    .font(.custom("Figtree", fixedSize: 16).weight(.medium))
                    .foregroundStyle(soft)
            }
            .padding(.top, 8)
            if data.finished {
                done(data, ink: ink, soft: soft)
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text(data.line)
                        .font(.custom("Figtree", fixedSize: 22).weight(.semibold))
                        .foregroundStyle(soft)
                    Spacer()
                    if let minutes = data.stepMinutes {
                        Text(minutes)
                            .font(.custom("Outfit", fixedSize: 18).weight(.regular))
                            .foregroundStyle(soft)
                    }
                }
                .padding(.top, 18)
                Text(data.move)
                    .font(.custom("Figtree", fixedSize: 84).weight(.heavy))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .padding(.top, 4)
                if let cue = data.cue {
                    Text(cue)
                        .font(TessFont.line(24, relativeTo: .title2).italic())
                        .foregroundStyle(soft)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
                if let breath = data.breath {
                    Text(breath)
                        .font(.custom("Figtree", fixedSize: 20).weight(.medium))
                        .foregroundStyle(soft)
                        .scaleEffect(reduceMotion ? 1 : (breath == "breathe in" ? 1.14 : 0.92), anchor: .leading)
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: breath == "breathe in" ? 4 : 6),
                            value: breath
                        )
                        .padding(.top, 14)
                }
                Text(GalleyCookWords.clock(TimeInterval(data.secondsLeft)))
                    .font(.custom("Outfit", fixedSize: 96).weight(.light))
                    .monospacedDigit()
                    .foregroundStyle(ink)
                    .contentTransition(.numericText(countsDown: true))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, 10)
                if data.paused {
                    Text("Paused")
                        .font(.custom("Figtree", fixedSize: 18).weight(.semibold))
                        .foregroundStyle(soft)
                }
                if !data.moves.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(data.moves) { row in
                            HStack {
                                Text(row.title)
                                Spacer()
                                Text(row.time).monospacedDigit()
                            }
                            .font(.custom("Figtree", fixedSize: 18).weight(row.state == .current ? .bold : .regular))
                            .foregroundStyle(row.state == .done ? RoutineScreen.tendedGreen
                                : row.state == .current ? ink : soft)
                            .strikethrough(row.state == .done, color: RoutineScreen.tendedGreen)
                        }
                    }
                    .frame(maxWidth: 220)
                    .padding(.top, 14)
                }
            }
            Spacer(minLength: 0)
            thumb(data, ink: ink, soft: soft)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .simultaneousGesture(
            DragGesture(minimumDistance: 24).onEnded { value in
                guard value.translation.height < -60, abs(value.translation.height) > abs(value.translation.width) * 1.5
                else { return }
                primary(data)
            }
        )
    }

    private func done(_ data: RoutineScreen, ink: Color, soft: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.summary)
                .font(.custom("Figtree", fixedSize: 52).weight(.heavy))
                .foregroundStyle(ink)
                .lineLimit(3)
                .minimumScaleFactor(0.5)
            Text("Goodnight")
                .font(TessFont.line(26, relativeTo: .title2).italic())
                .foregroundStyle(soft)
        }
        .padding(.top, 60)
    }

    private func thumb(_ data: RoutineScreen, ink: Color, soft: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            GalleyModeReceipt()
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Button { primary(data) } label: {
                        Text(data.finished ? "Done" : data.verb)
                            .font(.custom("Figtree", fixedSize: 44).weight(.heavy))
                            .foregroundStyle(ink)
                            .frame(minHeight: 60, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    if !data.finished {
                        HStack(spacing: 22) {
                            small(data.pauseWord, color: soft) { pauseOrResume() }
                            small("Not tonight", color: soft) { notTonight() }
                            small("Finish, hold", color: soft, hold: true) { finish() }
                        }
                    }
                }
                Spacer(minLength: 8)
                GalleyModeRail(items: data.rail, tint: ink) { _ in }
                    .allowsHitTesting(false)
            }
        }
    }

    private func small(_ word: String, color: Color, hold: Bool = false, _ act: @escaping () -> Void) -> some View {
        Text(word)
            .font(.custom("Figtree", fixedSize: 17).weight(.semibold))
            .foregroundStyle(color)
            .frame(minHeight: 36)
            .contentShape(Rectangle())
            .onTapGesture {
                if !hold {
                    act()
                }
            }
            .onLongPressGesture(minimumDuration: 0.7) {
                if hold {
                    act()
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(word)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { act() }
    }

    // MARK: Doing

    private func primary(_ data: RoutineScreen) {
        if data.finished {
            dismiss()
        } else {
            mutate { $0.next(now: AppClock.now) }
        }
    }

    private func pauseOrResume() {
        mutate { run in
            if run.isPaused {
                run.resume(now: AppClock.now)
            } else {
                run.pause(now: AppClock.now)
            }
        }
    }

    /// Not tonight: the step is left for tomorrow, with a receipt and Undo; nothing is lost and no streak breaks.
    private func notTonight() {
        guard let before = run, let beat = before.beat else { return }
        mutate { $0.notTonight(now: AppClock.now) }
        TessVoice.shared.say("\(before.steps[beat.step].title), left for tomorrow", takeBack: { run = before })
    }

    private func finish() {
        mutate { $0.finish() }
    }

    private func mutate(_ change: (inout RoutineModeRun) -> Void) {
        guard var current = run else { return }
        change(&current)
        self.change(current)
    }

    private func change(_ new: RoutineModeRun) {
        let wasDone = run?.finished ?? false
        let stepped = new.tended.count != (run?.tended.count ?? 0)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { run = new }
        if stepped {
            cue.play(.done)
        }
        if new.finished, !wasDone {
            write(new)
        }
    }

    /// The evening ends: if any step was tended the routine is tended for today (once a day), with one Undo.
    private func write(_ run: RoutineModeRun) {
        guard run.kept, !wrote else { return }
        wrote = true
        if let result = try? model.engine.perform(TendRoutine(routine: routineID, at: AppClock.now), by: .user) {
            model.touch()
            let line = result.record.receipt ?? "\(name), done for today."
            TessVoice.shared.say(line, undo: result.record, holds: .seconds(10))
        }
    }

    private func begin() {
        guard run == nil, let routine = model.store.object(id: routineID) else {
            if run == nil {
                dismiss()
            }
            return
        }
        let book = RoutineSteps(store: model.store, classes: model.classes)
        var made = RoutineModeRun(book.steps(of: routine))
        guard !made.isEmpty else {
            dismiss()
            return
        }
        made.start(at: AppClock.now)
        name = routine.title
        total = book.totalMinutes(of: routine)
        run = made
    }
}

/// The dusk: warm peach at the start to deep blue by the last step; the ink turns from dark to light halfway.
enum RoutineDusk {
    private static let dayTop = (r: 0.96, g: 0.84, b: 0.69)
    private static let dayBottom = (r: 0.93, g: 0.66, b: 0.52)
    private static let nightTop = (r: 0.06, g: 0.07, b: 0.16)
    private static let nightBottom = (r: 0.16, g: 0.18, b: 0.35)

    static func gradient(_ dusk: Double) -> LinearGradient {
        let t = min(max(dusk, 0), 1)
        func mix(_ from: (r: Double, g: Double, b: Double), _ to: (r: Double, g: Double, b: Double)) -> Color {
            Color(red: from.r + (to.r - from.r) * t, green: from.g + (to.g - from.g) * t,
                  blue: from.b + (to.b - from.b) * t)
        }
        return LinearGradient(colors: [mix(dayTop, nightTop), mix(dayBottom, nightBottom)], startPoint: .top,
                              endPoint: .bottom)
    }

    /// 0 in the day, 1 at night, with the turn between 0.35 and 0.6 of the dusk.
    static func night(_ dusk: Double) -> Double {
        let t = min(max((dusk - 0.35) / 0.25, 0), 1)
        return t * t * (3 - 2 * t)
    }

    static func ink(_ dusk: Double) -> Color {
        let n = night(dusk)
        return Color(red: 0.17 + (0.95 - 0.17) * n, green: 0.15 + (0.94 - 0.15) * n, blue: 0.13 + (0.90 - 0.13) * n)
    }

    static func soft(_ dusk: Double) -> Color {
        ink(dusk).opacity(0.72)
    }
}
