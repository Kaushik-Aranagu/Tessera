import SwiftUI
import TesseraCore

/// Cooking mode on the standing shell (sheet 322), over the existing cook session: Next, Timer, Read and Finish do
/// what the clock's own keys do. Behind the "Cooking mode" switch (On); Off keeps the clock page.
struct GalleyCookModePage: View {
    let cookID: UUID
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session: CookClockSession?
    @State private var navigator = ShellNavigator(root: .landing(GalleyCookContent.room))

    var body: some View {
        ZStack {
            if let session {
                modeView(session)
            }
        }
        .onAppear(perform: begin)
        .onDisappear { session?.pauseArming() }
    }

    private func modeView(_ session: CookClockSession) -> some View {
        LiveClock(LiveFeatures.cookClock, minimumInterval: 1, paused: scenePhase != .active) { context in
            let _ = model.revision
            let facts = Self.facts(session: session, model: model, now: AppClock.adjust(context.date))
            ShellView(room: GalleyCookContent(facts: facts), navigator: navigator, accent: LandingAccent.kitchen) {
                handle($0, session: session, facts: facts)
            }
            .environment(\.doorSummaryStyle, .ticket)
            .environment(\.shellGlyphRoom, .galley)
            .environment(\.shellScene) { _ in
                AnyView(GalleyRail(tickets: GalleyCookContent.tickets(facts)) { opens in
                    if case let .cookTimer(index) = opens {
                        startTimer(index, session: session, facts: facts)
                    }
                })
            }
        }
    }

    // MARK: Intents

    private func handle(_ intent: ShellIntent, session: CookClockSession, facts: GalleyCookFacts) {
        switch intent {
        case .back:
            dismiss()
        case .openItem:
            // The whole sentence place is the tap for Next, so a knuckle works.
            advance(session)
        case let .action(id):
            switch id {
            case "next": advance(session)
            case "timer": startTimer(facts.current, session: session, facts: facts)
            case "read": TessSpeech.shared.say(session.text(of: session.current))
            case "finish":
                if session.finish(note: nil) {
                    dismiss()
                }
            default: break
            }
        default:
            break
        }
    }

    private func advance(_ session: CookClockSession) {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { _ = session.next() }
    }

    /// Starts the step's pan timer, or gives a running one a minute more.
    private func startTimer(_ index: Int, session: CookClockSession, facts: GalleyCookFacts) {
        if let line = session.timer(ofStep: index) {
            session.extend(line, minutes: 1)
        } else if index >= 0, facts.steps.indices.contains(index) {
            let step = facts.steps[index]
            session.startSpoken(label: step.short, minutes: step.panMinutes ?? 5)
        }
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
            let ingredients = session.isPrivate ? [] : lines.filter { uses.contains($0.object.id) }.map(ledger)
            let timer = session.timer(ofStep: index).map {
                GalleyCookFacts.Timer(id: $0.id.uuidString, label: $0.label, endsAt: $0.endsAt)
            }
            return GalleyCookFacts.Step(index: index, short: short,
                                        how: GalleyCookWords.how(text, short: short),
                                        ingredients: ingredients,
                                        panMinutes: step.timers.first.map(\.lowerBound), timer: timer)
        }
        facts.spoken = session.spokenTimers.map {
            GalleyCookFacts.Timer(id: $0.id.uuidString, label: $0.label, endsAt: $0.endsAt)
        }
        return facts
    }

    /// "Chicken thighs 1 lb".
    static func ledger(_ line: RecipeBook.Line) -> String {
        let parts = line.line
        guard let amount = parts.amount else { return parts.name }
        let number = amount.rounded() == amount ? String(Int(amount)) : String(format: "%g", amount)
        let unit = parts.unit.map { " \($0.rawValue)" } ?? ""
        return "\(parts.name) \(number)\(unit)"
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
