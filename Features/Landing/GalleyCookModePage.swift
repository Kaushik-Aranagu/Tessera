import SwiftUI
import TesseraCore

/// Cooking mode (sheets 322, 325, 328): the whole ticket, cream paper full bleed in IBM Plex Sans Condensed. It reads
/// top to bottom: the dish, the step number with its heat, the instruction, how and when it is done, what it needs
/// with dotted leaders, the timers; the verb bottom left, the steps down the right edge. Swipe up anywhere is Next.
/// Behind the "Cooking mode" switch (On); Off keeps the clock page.
struct GalleyCookModePage: View {
    let cookID: UUID
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session: CookClockSession?
    /// Sheet 333: the ticket printer. Timers already printed, the line on the ticket now, and how far the paper has
    /// fed.
    @State private var printedTimers: Set<String> = []
    @State private var printedLine: String?
    @State private var feed: CGFloat = 0
    @State private var cue = HapticCue()

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
        #if DEBUG
            .task {
                // Simulator only (LaunchFlags): `-printNow` feeds the ready line after 3 s, for stills and recordings.
                guard LaunchFlags.has("-printNow") else { return }
                try? await Task.sleep(for: .seconds(3))
                await printLine(GalleyCookWords.readyLine(label: "Chicken"))
            }
        #endif
            .tesseraFeedback(cue)
    }

    private func screen(_ session: CookClockSession, now: Date) -> some View {
        let facts = Self.facts(session: session, model: model, now: now)
        let data = GalleyCookScreen(facts)
        return VStack(spacing: 0) {
            printer
            modeScreen(session, facts: facts, data: data)
        }
    }

    /// The paper has fed `feed` points: the printed line sits in the space it freed, over a dashed tear line.
    private var printer: some View {
        ZStack(alignment: .bottom) {
            if let line = printedLine {
                VStack(spacing: 2) {
                    Text(line)
                        .font(GalleyPaper.plex(.bold, 20))
                        .textCase(.uppercase)
                        .tracking(20 * 0.04)
                        .foregroundStyle(GalleyPaper.printed)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    PrinterTear()
                        .stroke(GalleyPaper.printed.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)
                .contentShape(Rectangle())
                .onTapGesture { clearPrinted() }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Clears it")
            }
        }
        .frame(height: feed)
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
        for offset in GalleyPrinter.feedSteps {
            feed = offset
            try? await Task.sleep(for: .milliseconds(45))
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
                    Text(data.number)
                        .font(GalleyPaper.number(104))
                        .foregroundStyle(Color(hex: 0x9C4B2C))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer(minLength: 12)
                    if let heat = data.heat {
                        Text(heat)
                            .font(GalleyPaper.plex(.medium, 18))
                            .foregroundStyle(GalleyPaper.ochre)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 150, alignment: .trailing)
                    }
                }
                .frame(height: 112)
                Text(data.instruction)
                    .font(GalleyPaper.plex(.bold, 46))
                    .foregroundStyle(GalleyPaper.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
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
                                GalleyLeaderRow(name: need.name, amount: need.amount)
                            }
                        }
                        .frame(maxWidth: 230)
                    }
                }
                if !data.timers.isEmpty || data.start != nil {
                    section("Timers") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(data.timers) { timer in
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text(timer.time)
                                        .font(GalleyPaper.number(26, weight: .bold))
                                        .monospacedDigit()
                                        .foregroundStyle(timer.ready ? GalleyPaper.wine : GalleyPaper.ink)
                                        .contentTransition(.numericText(countsDown: true))
                                    Text(timer.label)
                                        .font(GalleyPaper.plex(.regular, 18))
                                        .foregroundStyle(GalleyPaper.inkSecondary)
                                        .lineLimit(1)
                                }
                                .accessibilityElement(children: .combine)
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
            if session.finish(note: nil) {
                dismiss()
            }
        } else {
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { _ = session.next() }
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
    static func facts(session: CookClockSession, model: AppModel, now: Date) -> GalleyCookFacts {
        var facts = GalleyCookFacts()
        facts.recipe = session.isPrivate ? "Private recipe" : session.recipeName
        facts.serves = session.serves
        facts.current = session.current
        facts.now = now
        facts.minutesLeft = Int(session.minutesLeft(at: now).rounded())
        let cook = model.store.object(id: session.cookID)
        let began = cook.flatMap { model.store.value("startedAt", of: $0)?.dateValue } ?? cook?.createdAt ?? now
        facts.minutesIn = max(0, Int(now.timeIntervalSince(began) / 60))
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
                                        heat: GalleyCues.heat(text),
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

    var body: some View {
        if Tier1b.cookModeIsOn {
            GalleyCookModePage(cookID: cookID)
        } else {
            CookClockPage(cookID: cookID)
        }
    }
}
