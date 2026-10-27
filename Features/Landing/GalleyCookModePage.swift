import SwiftUI
import TesseraCore

/// Cooking mode (sheets 322, 325, 328): the whole ticket, cream paper full bleed in IBM Plex Sans Condensed. It reads
/// top to bottom: the dish, the step number with its heat, the instruction, how and when it is done, what it needs
/// with dotted leaders, the timers; the verb bottom left, the steps down the right edge. Swipe up anywhere is Next.
/// Behind the "Cooking mode" switch (On); Off keeps the clock page.
struct GalleyCookModePage: View {
    let cookID: UUID
    /// A ready line to print when the page opens (the Live Activity's link: "Chicken"), sheet 344.
    var alert: String?
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session: CookClockSession?
    /// When the mode was opened: the top line counts minutes from here.
    @State private var opened = AppClock.now
    /// Sheet 333: the ticket printer. Timers already printed, the line on the ticket now, and how far the paper has
    /// fed.
    @State private var printedTimers: Set<String> = []
    @State private var printedLine: String?
    @State private var feed: CGFloat = 0
    @State private var cue = HapticCue()
    /// The Needs lines set out on the counter, by step number and name (sheet 353).
    @State private var setOut: Set<String> = []
    /// The last Serve (sheet 337): the ticket spiked, then the Eat summary printing down.
    @State private var spiked = false
    /// The old ticket's layers are removed once the spike has finished, so nothing of it stays under the summary.
    @State private var retired = false
    @State private var eat: GalleyCookEat?
    @State private var eatReveal: CGFloat = 0
    /// Counts Undos of Serve, so a Serve still printing stops when it is taken back.
    @State private var served = 0

    var body: some View {
        ZStack {
            GalleyPaper.sheet.ignoresSafeArea()
            if let session {
                LiveClock(LiveFeatures.cookClock, minimumInterval: 1, paused: scenePhase != .active) { context in
                    let _ = model.revision
                    screen(session, now: AppClock.adjust(context.date))
                }
            }
        }
        .onAppear(perform: begin)
        .onDisappear { session?.pauseArming() }
        .task {
            // A pan timer that has reached zero is printed once: the paper feeds and the line prints.
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard scenePhase == .active, let session else { continue }
                let now = AppClock.now
                let done = session.timers.filter { $0.isDone(at: now) && !printedTimers.contains($0.id.uuidString) }
                guard let first = done.first else { continue }
                printedTimers.formUnion(done.map(\.id.uuidString))
                await printLine(GalleyCookWords.readyLine(label: first.label))
            }
        }
        .onChange(of: session?.current) { clearPrinted() }
        .task {
            // Opened from the Live Activity with an alert: the ticket opens with the ready line already printed.
            guard let alert else { return }
            try? await Task.sleep(for: .milliseconds(400))
            await printLine(GalleyCookWords.readyLine(label: alert))
        }
        #if DEBUG
        .task {
            // Simulator only (LaunchFlags): `-printNow` feeds the ready line after 3 s, for stills and recordings.
            guard LaunchFlags.has("-printNow") else { return }
            try? await Task.sleep(for: .seconds(3))
            await printLine(GalleyCookWords.readyLine(label: "Chicken"))
        }
        .task {
            // `-startTimerNow` starts the step's pan timer after 3 s (the digits roll up), then adds a minute 4 s
            // later; `-serveNow` serves the last step after 3 s (the ticket is spiked, the Eat summary prints).
            guard LaunchFlags.has("-startTimerNow") || LaunchFlags.has("-serveNow") else { return }
            try? await Task.sleep(for: .seconds(3))
            guard let session else { return }
            let facts = Self.facts(session: session, model: model, now: AppClock.now, opened: opened)
            if LaunchFlags.has("-serveNow") {
                for _ in 0 ..< session.steps.count {
                    _ = session.next()
                }
                try? await Task.sleep(for: .seconds(1))
                let last = Self.facts(session: session, model: model, now: AppClock.now, opened: opened)
                if session.finish(note: nil, takeBack: { reopen(session) }) {
                    await serve(last)
                }
            } else {
                startTimer(session, facts: facts)
                try? await Task.sleep(for: .seconds(4))
                if let line = session.timers.first {
                    session.extend(line, minutes: line.remaining(at: AppClock.now) / 60 + 1)
                }
            }
        }
        #endif
        .tesseraFeedback(cue)
    }

    private func screen(_ session: CookClockSession, now: Date) -> some View {
        let facts = Self.facts(session: session, model: model, now: now, opened: opened)
        let data = GalleyCookScreen(facts)
        return ZStack(alignment: .top) {
            if !retired {
                VStack(spacing: 0) {
                    printer
                    modeScreen(session, facts: facts, data: data)
                }
                // The finished ticket is pulled up into the rail clip: the origin is top centre, 18 pt above the paper.
                .scaleEffect(x: spiked ? GalleySpike.scaleX : 1, y: spiked ? GalleySpike.scaleY : 1,
                             anchor: UnitPoint(x: 0.5, y: -GalleySpike.originAbove / 874))
                .offset(y: spiked ? -GalleySpike.rise : 0)
                .opacity(spiked ? 0 : 1)
                .animation(reduceMotion ? nil : .easeIn(duration: GalleySpike.fade), value: spiked)
                .allowsHitTesting(!spiked)
            }
            if let eat {
                eatSummary(eat)
                    .mask {
                        GeometryReader { proxy in
                            Rectangle()
                                .frame(height: proxy.size.height * eatReveal)
                                .frame(maxHeight: .infinity, alignment: .top)
                        }
                    }
            }
        }
    }

    /// The Eat summary: the dish and how long it took, printed down out of the rail.
    private func eatSummary(_ eat: GalleyCookEat) -> some View {
        GalleyModeScreen(room: "Galley", topRight: "Served", back: { dismiss() }, verb: { dismiss() }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(eat.title)
                    .font(GalleyPaper.plex(.bold, 64))
                    .foregroundStyle(GalleyPaper.ink)
                    .padding(.top, 40)
                Text(eat.dish)
                    .font(GalleyPaper.plex(.bold, 26))
                    .foregroundStyle(GalleyPaper.ochre)
                    .lineLimit(2)
                Text(eat.detail)
                    .font(GalleyPaper.plex(.medium, 20))
                    .foregroundStyle(GalleyPaper.inkSecondary)
            }
        } thumb: {
            VStack(alignment: .leading, spacing: 0) {
                GalleyModeReceipt()
                GalleyModeVerb(word: "Done") { dismiss() }
            }
        }
    }

    /// The last Serve: the cook is written (one Undo), the ticket is pulled up into the clip with one short buzz, and
    /// 300 ms in the Eat summary prints down in eight steps over 620 ms.
    private func serve(_ facts: GalleyCookFacts) async {
        let summary = GalleyCookEat(facts)
        let mine = served
        guard !reduceMotion else {
            eat = summary
            eatReveal = 1
            spiked = true
            retired = true
            return
        }
        cue.play(.selection)
        spiked = true
        Task { @MainActor in
            // Once the ticket has gone up (400 ms) its layers are removed.
            try? await Task.sleep(for: .milliseconds(Int(GalleySpike.fade * 1000)))
            retired = true
        }
        try? await Task.sleep(for: .milliseconds(Int(GalleySpike.printDelay * 1000)))
        guard mine == served else { return }
        eatReveal = 0
        eat = summary
        let step = GalleySpike.printDuration / Double(GalleySpike.printSteps)
        for fraction in GalleySpike.reveal {
            guard mine == served else { return }
            eatReveal = fraction
            try? await Task.sleep(for: .milliseconds(Int(step * 1000)))
        }
    }

    /// Undo of Serve: the cook is open again, so the Eat summary goes and the ticket comes back as it was.
    private func reopen(_ session: CookClockSession) {
        served += 1
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            eat = nil
            eatReveal = 0
            spiked = false
            retired = false
        }
        session.armEnd()
    }

    /// The paper has fed `feed` points: the alert sits in the space it freed, on a 28 pt line with a dashed rule under
    /// it, and pushes the ticket down by its height. Its text is always 20 pt: the feed clips it, never shrinks it.
    private var printer: some View {
        ZStack(alignment: .bottom) {
            if let line = printedLine {
                VStack(spacing: 0) {
                    Text(line)
                        .font(GalleyPaper.plex(.bold, GalleyPrinter.textSize))
                        .textCase(.uppercase)
                        .tracking(GalleyPrinter.textSize * 0.06)
                        .foregroundStyle(GalleyPaper.printed)
                        .lineLimit(1)
                        .fixedSize()
                        .frame(height: GalleyPrinter.lineHeight)
                    PrinterTear()
                        .stroke(GalleyPaper.printed.opacity(0.5),
                                style: StrokeStyle(lineWidth: GalleyPrinter.ruleWidth, dash: [6, 4]))
                        .frame(height: GalleyPrinter.ruleWidth)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .contentShape(Rectangle())
                .onTapGesture { clearPrinted() }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Clears it")
            }
        }
        .frame(height: feed, alignment: .bottom)
        .clipped()
        .background(GalleyPaper.sheet)
    }

    private struct PrinterTear: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }

    /// Feeds the paper 30 pt with a 4 pt overshoot in five steps, with one buzz; Reduce Motion drops it in place.
    private func printLine(_ line: String) async {
        printedLine = line
        cue.play(.timeUp)
        guard !reduceMotion else {
            feed = GalleyPrinter.drop
            return
        }
        for (index, offset) in GalleyPrinter.feedSteps.enumerated() {
            feed = offset
            let last = index == GalleyPrinter.feedSteps.count - 1
            try? await Task
                .sleep(for: .milliseconds(last ? GalleyPrinter.settleMilliseconds : GalleyPrinter.stepMilliseconds))
        }
    }

    private func clearPrinted() {
        guard printedLine != nil else { return }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            feed = 0
            printedLine = nil
        }
    }

    private func modeScreen(_ session: CookClockSession, facts: GalleyCookFacts, data: GalleyCookScreen) -> some View {
        GalleyModeScreen(room: "Galley", topRight: data.topRight, back: { dismiss() },
                         verb: { primary(session, data) })
        {
            VStack(alignment: .leading, spacing: 0) {
                Text(data.title)
                    .font(GalleyPaper.plex(.bold, 26))
                    .foregroundStyle(GalleyPaper.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 4)
                HStack(alignment: .firstTextBaseline) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(data.number)
                            .font(GalleyPaper.number(104))
                            .foregroundStyle(GalleyPaper.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text(data.of)
                            .font(GalleyPaper.plex(.medium, 20))
                            .foregroundStyle(GalleyPaper.inkSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 12)
                    if let heat = data.heat {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(heat)
                                .font(GalleyPaper.plex(.bold, 18))
                                .textCase(.uppercase)
                                .tracking(18 * 0.06)
                                .foregroundStyle(GalleyPaper.ochre)
                            if let note = data.heatNote {
                                Text(note)
                                    .font(GalleyPaper.plex(.regular, 17))
                                    .foregroundStyle(GalleyPaper.inkSecondary)
                            }
                        }
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 170, alignment: .trailing)
                    }
                }
                .frame(height: 112)
                Text(data.instruction)
                    .font(GalleyPaper.plex(.bold, GalleyCookFit.size(for: data.instruction, width: 354)))
                    .foregroundStyle(GalleyPaper.ink)
                    .lineLimit(GalleyCookFit.lines)
                    .lineSpacing(-2)
                    .fixedSize(horizontal: false, vertical: true)
                if !data.how.isEmpty {
                    Text(data.how)
                        .font(GalleyPaper.plex(.regular, 19))
                        .foregroundStyle(GalleyPaper.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.top, 6)
                }
                if let done = data.doneWhen {
                    section("Done when") {
                        Text(done)
                            .font(GalleyPaper.plex(.medium, 19))
                            .foregroundStyle(GalleyPaper.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                    }
                }
                if !data.needs.isEmpty {
                    section("Needs") {
                        VStack(spacing: 5) {
                            ForEach(Array(data.needs.enumerated()), id: \.offset) { _, need in
                                // Sheet 353: tap a line when it is out on the counter; the pen strikes it. Optional,
                                // kept per step, never blocks Next and nothing counts it.
                                let key = "\(data.number)|\(need.name)"
                                GalleyNeedRow(name: need.name, amount: need.amount, struck: setOut.contains(key)) {
                                    if setOut.contains(key) {
                                        setOut.remove(key)
                                    } else {
                                        setOut.insert(key)
                                        cue.play(.selection)
                                        // Sheet 355: every strike carries a 10 s Undo that lifts the pen.
                                        TessVoice.shared.say("\(need.name), set out", holds: .seconds(10),
                                                             takeBack: { setOut.remove(key) })
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: 230)
                    }
                }
                if !data.timers.isEmpty || data.start != nil {
                    section("Timers") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(data.timers) { timer in
                                // Sheet 346: a started timer rolls up from 0:00; tapping a running one adds a minute.
                                Button { addMinute(session, timerID: timer.id) } label: {
                                    // Name, a dotted leader, then the time: "Roast ······ 30:00".
                                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                                        Text(timer.label)
                                            .font(GalleyPaper.plex(.regular, 18))
                                            .foregroundStyle(GalleyPaper.ink)
                                            .lineLimit(1)
                                            .layoutPriority(1)
                                        Rectangle().fill(.clear).frame(height: 1)
                                            .overlay(alignment: .bottom) {
                                                PrinterTear()
                                                    .stroke(GalleyPaper.inkSecondary.opacity(0.55),
                                                            style: StrokeStyle(lineWidth: 1.2, dash: [1.5, 4]))
                                                    .frame(height: 1)
                                            }
                                            .offset(y: -3)
                                        RollingTimerTime(seconds: timer.seconds, ready: timer.ready)
                                    }
                                    .frame(maxWidth: 260)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityElement(children: .combine)
                                .accessibilityHint(timer.ready ? "" : "Adds a minute")
                            }
                            if let start = data.start {
                                Button { startTimer(session, facts: facts) } label: {
                                    Text(start)
                                        .font(GalleyPaper.plex(.bold, 18))
                                        .foregroundStyle(GalleyPaper.ochre)
                                        .frame(minHeight: 36, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        } thumb: {
            VStack(alignment: .leading, spacing: 0) {
                GalleyModeReceipt()
                HStack(alignment: .bottom) {
                    GalleyModeVerb(word: data.verb, object: data.object, hold: data.hold) {
                        primary(session, data)
                    }
                    Spacer(minLength: 8)
                    GalleyModeRail(items: data.rail) { jump(session, to: $0) }
                }
            }
        }
    }

    private func section(_ title: String, @ViewBuilder _ body: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(GalleyPaper.plex(.bold, 13))
                .tracking(13 * 0.1)
                .foregroundStyle(GalleyPaper.inkSecondary)
            body()
        }
        .padding(.top, 14)
    }

    // MARK: Doing

    private func primary(_ session: CookClockSession, _ data: GalleyCookScreen) {
        if data.hold {
            let facts = Self.facts(session: session, model: model, now: AppClock.now, opened: opened)
            if session.finish(note: nil, takeBack: { reopen(session) }) {
                Task { await serve(facts) }
            }
        } else {
            // Sheet 355: Next is a step done, with a 10 s Undo that goes back to it.
            let done = session.steps.indices.contains(session.current)
                ? GalleyCookWords.short(session.steps[session.current].text) : nil
            var moved = false
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { moved = session.next() }
            if moved, let done {
                TessVoice.shared.say("\(done), done", holds: .seconds(10), takeBack: {
                    withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { _ = session.back() }
                })
            }
        }
    }

    /// Jumps to a step by walking the bead; a cook never skips a step's own timer start.
    private func jump(_ session: CookClockSession, to target: Int) {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            var guardSteps = session.steps.count
            while session.current != target, guardSteps > 0 {
                guardSteps -= 1
                let moved = session.current < target ? session.next() : session.back()
                if !moved {
                    break
                }
            }
        }
    }

    /// Tapping a running timer adds a minute (sheet 346): its own timer restarts with a minute more left, never a
    /// second
    /// one, and only the minute digit rolls on.
    private func addMinute(_ session: CookClockSession, timerID: String) {
        guard let line = session.timers.first(where: { $0.id.uuidString == timerID }) else { return }
        let left = line.remaining(at: AppClock.now)
        guard left > 0 else { return }
        session.extend(line, minutes: left / 60 + 1)
    }

    private func startTimer(_ session: CookClockSession, facts: GalleyCookFacts) {
        guard let step = facts.step else { return }
        session.startSpoken(label: step.short, minutes: step.panMinutes ?? 5)
    }

    private func begin() {
        guard session == nil else { return }
        guard let made = CookClockSession(model: model, cookID: cookID) else {
            dismiss()
            return
        }
        session = made
        made.armEnd()
        made.reconcileFlares(at: AppClock.now, live: false)
    }

    // MARK: Facts

    /// The mode's facts from the cook session: the steps in a few words, their ingredients and pan times, and the
    /// timers. A private recipe shows its label and no ingredient names.
    @MainActor
    static func facts(session: CookClockSession, model: AppModel, now: Date, opened: Date) -> GalleyCookFacts {
        var facts = GalleyCookFacts()
        facts.recipe = session.isPrivate ? "Private recipe" : session.recipeName
        facts.serves = session.serves
        facts.current = session.current
        facts.now = now
        facts.minutesLeft = Int(session.minutesLeft(at: now).rounded())
        // The count starts at 0 when the mode is opened; the plan's minutes left say when it is eaten.
        facts.minutesIn = max(0, Int(now.timeIntervalSince(opened) / 60))
        facts.eatAt = facts.minutesLeft > 0
            ? HouseTime.clock(now.addingTimeInterval(TimeInterval(facts.minutesLeft) * 60)).split(separator: " ").first
            .map(String.init)
            : nil
        let book = RecipeBook(store: model.store, classes: model.classes)
        let lines = model.store.object(id: session.recipeID).map { book.lines(of: $0) } ?? []
        facts.steps = session.steps.enumerated().map { index, step in
            let text = session.text(of: index)
            let short = GalleyCookWords.short(text)
            let uses = Set(step.uses.map(\.id))
            let used = session.isPrivate ? [] : lines.filter { uses.contains($0.object.id) }
            let timer = session.timer(ofStep: index).map {
                GalleyCookFacts.Timer(id: $0.id.uuidString, label: $0.label, endsAt: $0.endsAt)
            }
            return GalleyCookFacts.Step(index: index, short: short,
                                        how: GalleyCookWords.how(text, short: short),
                                        ingredients: used.map(ledger),
                                        needs: used.map(need),
                                        line: GalleyCookWords.line(text),
                                        heat: GalleyCues.heat(text), heatNote: GalleyCues.heatNote(text),
                                        cue: GalleyCues.doneness(text),
                                        panMinutes: step.timers.first.map(\.lowerBound), timer: timer)
        }
        facts.spoken = session.spokenTimers.map {
            GalleyCookFacts.Timer(id: $0.id.uuidString, label: $0.label, endsAt: $0.endsAt)
        }
        return facts
    }

    /// "Chicken thighs 1 lb".
    static func ledger(_ line: RecipeBook.Line) -> String {
        let parts = need(line)
        return parts.amount.map { "\(parts.name) \($0)" } ?? parts.name
    }

    /// The name and its amount, split for the dotted leaders.
    static func need(_ line: RecipeBook.Line) -> GalleyCookFacts.Need {
        let parts = line.line
        guard let amount = parts.amount else { return .init(name: parts.name, amount: nil) }
        let number = amount.rounded() == amount ? String(Int(amount)) : String(format: "%g", amount)
        let unit = parts.unit.map { " \($0.rawValue)" } ?? ""
        return .init(name: parts.name, amount: "\(number)\(unit)")
    }
}

/// The cook cover's single door: the cooking mode, or the clock page when the switch is Off.
struct CookEntry: View {
    let cookID: UUID
    var alert: String?

    var body: some View {
        if Tier1b.cookModeIsOn {
            GalleyCookModePage(cookID: cookID, alert: alert)
        } else {
            CookClockPage(cookID: cookID)
        }
    }
}

/// A timer's time in the big numerals (sheet 346). When the timer first appears its digits roll up from 0:00 to its
/// length,
/// each digit on its own; after that it follows the real time, so adding a minute rolls only the digits that change.
/// Reduce Motion: the time simply appears.
struct RollingTimerTime: View {
    let seconds: Int
    let ready: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// nil follows the real time; a value is the roll in progress.
    @State private var rolling: Int?

    private var shown: Int {
        rolling ?? seconds
    }

    var body: some View {
        Text(ready ? "Ready" : GalleyCookWords.clock(TimeInterval(shown)))
            .font(GalleyPaper.number(26, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(ready ? GalleyPaper.wine : GalleyPaper.ink)
            .contentTransition(.numericText(value: Double(shown)))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: shown)
            .task {
                guard !reduceMotion, !ready else { return }
                let target = seconds
                rolling = 0
                try? await Task.sleep(for: .milliseconds(30))
                rolling = target
                try? await Task.sleep(for: .milliseconds(550))
                rolling = nil
            }
    }
}

/// A Needs line as a mise en place tick (sheet 353): tapping it draws the pen stroke through it in 300 ms and it stays
/// struck until tapped again. Reduce Motion: the strike is simply there.
private struct GalleyNeedRow: View {
    let name: String
    var amount: String?
    let struck: Bool
    var tap: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat?

    var body: some View {
        Button(action: tap) {
            GalleyLeaderRow(name: name, amount: amount, struck: struck)
                .overlay {
                    let shown = progress ?? (struck ? 1 : 0)
                    if shown > 0 {
                        GalleyPenStroke(progress: shown)
                            .stroke(GalleyPaper.ink, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name + (amount.map { ", \($0)" } ?? ""))
        .accessibilityValue(struck ? "Set out" : "")
        .accessibilityAddTraits(.isToggle)
        .onChange(of: struck) { _, now in
            guard now, !reduceMotion else {
                progress = nil
                return
            }
            progress = 0
            withAnimation(.timingCurve(0.3, 0.7, 0.3, 1, duration: 0.3)) { progress = 1 }
        }
    }
}
