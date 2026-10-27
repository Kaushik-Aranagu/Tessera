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
    /// The page the book being read stands at (the Read step names the page it will reach).
    @State private var bookPage: Int?

    var body: some View {
        let dusk = run?.dusk ?? 0
        ZStack {
            RoutineDusk.gradient(dusk).ignoresSafeArea()
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.2), value: dusk)
            if let run {
                LiveClock(LiveFeatures.routineClock, minimumInterval: 1, paused: scenePhase != .active) { context in
                    let now = AppClock.adjust(context.date)
                    let data = RoutineScreen(run, name: name, totalMinutes: total, now: now, bookPage: bookPage)
                    screen(data, now: now)
                        // Sheet 335: the sky and the words dim together on the last step; kept under Reduce Motion.
                        .overlay {
                            Color.black.opacity(1 - data.brightness).ignoresSafeArea().allowsHitTesting(false)
                        }
                }
            }
        }
        .preferredColorScheme(.dark)
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
                // The count on the right, and under it "hold to finish" (like the workout): the hold ends the evening.
                VStack(alignment: .trailing, spacing: 0) {
                    Text(data.topRight)
                        .font(.custom("Figtree", fixedSize: 16).weight(.medium))
                        .foregroundStyle(soft)
                    if !data.finished {
                        Text("hold to finish")
                            .font(.custom("Figtree", fixedSize: 13).weight(.medium))
                            .foregroundStyle(soft.opacity(0.8))
                    }
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 0.7) {
                    if !data.finished {
                        finish()
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityHint(data.finished ? "" : "Hold to finish the evening")
            }
            .padding(.top, 8)
            if data.finished {
                done(data, ink: ink, soft: soft)
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text(data.line)
                        .font(.custom("Figtree", fixedSize: 22).weight(.semibold))
                        .foregroundStyle(soft)
                    Spacer(minLength: 12)
                    if let minutes = data.stepMinutes {
                        // The label wraps beside the numerals; the numerals never shrink (sheet 341).
                        Text(minutes)
                            .font(.custom("Outfit", fixedSize: 18).weight(.regular))
                            .foregroundStyle(soft)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 190, alignment: .trailing)
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
                        // The letters widen on the in-breath (4 s) and close up on the out-breath (6 s).
                        .tracking(reduceMotion ? 0 : (breath == "breathe in" ? 5 : 0))
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
                    .fixedSize()
                    .padding(.top, 10)
                if let then = data.then {
                    Text("then \(then)")
                        .font(.custom("Figtree", fixedSize: 20).weight(.medium))
                        .foregroundStyle(soft)
                }
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
                            .foregroundStyle(row.state == .done ? RoutineScreen.tended
                                : row.state == .current ? ink : soft)
                            .strikethrough(row.state == .done, color: RoutineScreen.tended)
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
                        // Pause and Not tonight on one line under Next; Finish is the hold at the top right.
                        HStack(spacing: 22) {
                            small(data.pauseWord.lowercased(), color: soft) { pauseOrResume() }
                            small("not tonight", color: soft) { notTonight() }
                        }
                    }
                }
                Spacer(minLength: 8)
                GalleyModeRail(items: data.rail, tint: ink) { _ in }
                    // The thumb zone sits over the sky's lightest band: a soft shadow keeps the steps readable.
                    .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                    .allowsHitTesting(false)
            }
        }
    }

    private func small(_ word: String, color: Color, hold: Bool = false, _ act: @escaping () -> Void) -> some View {
        Text(word)
            .font(.custom("Figtree", fixedSize: 17).weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
            .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
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
        // A tended Read step says the page it reached, from the minutes actually read (sheet 341).
        if stepped, let bookPage, let before = run,
           let step = new.steps.first(where: { new.tended.contains($0.id) && !before.tended.contains($0.id) }),
           RoutineReading.isReading(step.title)
        {
            TessVoice.shared.say(RoutineReading.receipt(title: step.title, last: bookPage,
                                                        spent: new.spent[step.id] ?? 0))
        }
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
        let shelf = Bookshelf(store: model.store, classes: model.classes)
        bookPage = shelf.reading().first.map { shelf.page(of: $0) }
        #if DEBUG
            // Simulator only (LaunchFlags): `-routineSkip N` moves N moves on, to see the dusk deepen, for stills.
            if let value = LaunchFlags.value(after: "-routineSkip"), let count = Int(value) {
                for _ in 0 ..< count {
                    made.next(now: AppClock.now)
                }
            }
        #endif
        run = made
    }
}

/// The dusk (sheet 329): the sky starts dark (top 2A2140, middle 5B3A62, horizon C98472) and deepens to night as the
/// steps are tended; the ink is F4EEF2 throughout.
enum RoutineDusk {
    private typealias RGB = (r: Double, g: Double, b: Double)
    private static func rgb(_ hex: UInt32) -> RGB {
        (Double((hex >> 16) & 255) / 255, Double((hex >> 8) & 255) / 255, Double(hex & 255) / 255)
    }

    private static let startTop = rgb(0x2A2140), startMiddle = rgb(0x5B3A62), startHorizon = rgb(0xC98472)
    private static let endTop = rgb(0x0A0916), endMiddle = rgb(0x181536), endHorizon = rgb(0x3B2E58)

    static func gradient(_ dusk: Double) -> LinearGradient {
        let t = min(max(dusk, 0), 1)
        func mix(_ from: RGB, _ to: RGB) -> Color {
            Color(
                red: from.r + (to.r - from.r) * t,
                green: from.g + (to.g - from.g) * t,
                blue: from.b + (to.b - from.b) * t
            )
        }
        return LinearGradient(
            colors: [mix(startTop, endTop), mix(startMiddle, endMiddle), mix(startHorizon, endHorizon)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func ink(_: Double) -> Color {
        RoutineScreen.ink
    }

    static func soft(_ dusk: Double) -> Color {
        ink(dusk).opacity(0.72)
    }
}
