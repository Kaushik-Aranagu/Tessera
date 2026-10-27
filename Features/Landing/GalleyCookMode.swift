import SwiftUI
import TesseraCore

/// Cooking mode (sheet 322): the Galley's landing with each place given a live job. The rail holds the step you are on
/// as the big ticket and one ticket per pan timer, the sentence place says the step big enough to read from the stove
/// (and the whole place is a tap for Next), the dial holds the steps with a running timer's time beside its name, the
/// summary is the focused step's ledger, and the foot does the next thing. Pure: the facts come in, a `Screen` comes
/// out, so it tests without a view or a store.
struct GalleyCookFacts: Equatable {
    struct Timer: Equatable, Identifiable {
        let id: String
        let label: String
        let endsAt: Date

        func left(at now: Date) -> TimeInterval {
            max(0, endsAt.timeIntervalSince(now))
        }
    }

    struct Step: Equatable, Identifiable {
        let index: Int
        /// The step in a few words, big: "Brown the chicken".
        let short: String
        /// The rest of the step: "Cumin and salt, leave it be".
        let how: String
        /// Its ingredients as a ledger: "Chicken thighs 1 lb".
        var ingredients: [String] = []
        /// The pan time the step names, in minutes, nil when it has none.
        var panMinutes: Double?
        /// The step's running timer, if one is.
        var timer: Timer?

        var id: Int {
            index
        }
    }

    var recipe = ""
    var steps: [Step] = []
    /// The step he is on.
    var current = 0
    var minutesIn = 0
    var minutesLeft = 0
    var now = Date()
    /// Timers that belong to no step (he said "bread, 8 minutes").
    var spoken: [Timer] = []

    var step: Step? {
        steps.indices.contains(current) ? steps[current] : nil
    }

    var isLast: Bool {
        current >= steps.count - 1
    }
}

/// The words of the mode, one place, tested.
enum GalleyCookWords {
    private static let cuts = [" until ", " for ", " about ", " while ", " then ", " so ", " and "]
    private static let tails: Set<String> = ["the", "a", "an", "in", "on", "to", "of", "with", "into", "for", "and"]

    /// "Brown the chicken in the oil for 5 minutes, then flip." becomes "Brown the chicken".
    static func short(_ text: String) -> String {
        var line = sentence(text)
        for cut in cuts + [",", ";", ":", " - "] {
            if let range = line.range(of: cut) {
                line = String(line[..<range.lowerBound])
            }
        }
        var words = line.split(separator: " ").map(String.init)
        if words.count > 4 {
            words = Array(words.prefix(4))
        }
        while let last = words.last, tails.contains(last.lowercased()), words.count > 1 {
            words.removeLast()
        }
        return capital(words.joined(separator: " "))
    }

    /// What follows the short name, trimmed to a line: "in the oil for 5 minutes".
    static func how(_ text: String, short: String) -> String {
        let line = sentence(text)
        var rest = line
        if line.lowercased().hasPrefix(short.lowercased()) {
            rest = String(line.dropFirst(short.count))
        }
        rest = rest.trimmingCharacters(in: CharacterSet(charactersIn: " ,;:-."))
        let words = rest.split(separator: " ")
        guard !words.isEmpty else { return "" }
        let kept = words.prefix(9).joined(separator: " ")
        return capital(kept)
    }

    /// The first sentence, without its closing stop (no full stop on a shown line).
    static func sentence(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let first = trimmed.components(separatedBy: ". ").first ?? trimmed
        return ShownLine.unstopped(first, between: ", ")
    }

    static func capital(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }

    /// "2:47" from seconds; an hour or more reads "1:05:00".
    static func clock(_ seconds: TimeInterval) -> String {
        let whole = Int(seconds.rounded(.up))
        let hours = whole / 3600
        let minutes = (whole % 3600) / 60
        let secs = whole % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, secs)
            : String(format: "%d:%02d", minutes, secs)
    }

    static func minutes(_ value: Double) -> String {
        let whole = Int(value.rounded())
        return whole == 1 ? "1 min" : "\(whole) min"
    }

    static func band(_ facts: GalleyCookFacts) -> [String] {
        let steps = facts.steps.count
        let first = facts.minutesIn <= 0 ? "Just started" : "\(facts.minutesIn) min in"
        let second = facts.minutesLeft > 0
            ? "\(steps) steps, about \(facts.minutesLeft) min to eat"
            : "\(steps) steps"
        return [first, second]
    }

    /// "Step 2 of 5, 2:47 left" (or without the time when the step has no timer running).
    static func header(_ facts: GalleyCookFacts) -> String {
        let base = "Step \(facts.current + 1) of \(facts.steps.count)"
        guard let timer = facts.step?.timer else { return base }
        let left = timer.left(at: facts.now)
        return left > 0 ? "\(base), \(clock(left)) left" : "\(base), ready"
    }

    /// What comes next, or that Tess will say when.
    static func after(_ facts: GalleyCookFacts) -> String {
        if let next = facts.steps.indices.contains(facts.current + 1) ? facts.steps[facts.current + 1] : nil {
            return "Next, \(next.short.lowercased())"
        }
        return "Last step, then serve"
    }
}

/// The mode as content for the standing shell.
struct GalleyCookContent: RoomContent {
    static let room = "galley.cook"
    static let sceneKey = "galley.cook.rail"

    let facts: GalleyCookFacts
    var accent: Color = LandingAccent.kitchen

    func screen(for _: ShellRoute, state: RoomState) -> Screen {
        let focus = facts.steps.isEmpty ? 0 : min(max(state.dialFocus, 0), facts.steps.count - 1)
        return Screen(layout: .landing, slots: [
            .title: SlotContent(id: "galley.cook.title", kind: .text, payload: .title(facts.recipe, accent: accent)),
            .navWord: SlotContent(id: "galley.cook.nav", kind: .text, payload: .navWord("Galley")),
            .needs: SlotContent(id: ContentID("galley.cook.band.\(facts.minutesIn).\(facts.minutesLeft)"), kind: .text,
                                payload: .lines(GalleyCookWords.band(facts))),
            .keystone: SlotContent(id: ContentID(Self.sceneKey), kind: .scene,
                                   payload: .scene(Self.sceneKey, label: "The cooking rail")),
            .caption: SlotContent(id: "galley.cook.caption", kind: .text,
                                  payload: .lines(["Tap the step when it is done"])),
            .widget: widget,
            .dial: facts.steps.isEmpty ? nil : SlotContent(id: "galley.cook.dial", kind: .dial, payload: .dial(dial)),
            .doorSummary: summary(focus),
            .actionWord: action,
            .tess: nil,
        ])
    }

    // MARK: Places

    /// The sentence place: the step on, big; how; what is next. The whole place is the tap for Next.
    private var widget: SlotContent? {
        guard let step = facts.step else { return nil }
        let item = WidgetItem(id: "step.\(step.index)", header: GalleyCookWords.header(facts), big: step.short,
                              middle: step.how.isEmpty ? "Tess will say when" : step.how,
                              small: GalleyCookWords.after(facts), bigColor: accent, strikeable: false)
        return SlotContent(id: ContentID("galley.cook.widget.\(step.index)"), kind: .widget, payload: .widget([item]))
    }

    private var dial: [DialDoor] {
        facts.steps.map { step in
            DialDoor(id: "step.\(step.index)", name: step.short,
                     count: step.timer.map { GalleyCookWords.clock($0.left(at: facts.now)) }, color: accent)
        }
    }

    /// The focused step's ledger: its ingredients, then its pan time.
    private func summary(_ focus: Int) -> SlotContent? {
        guard facts.steps.indices.contains(focus) else { return nil }
        let step = facts.steps[focus]
        var lines = Array(step.ingredients.prefix(3))
        if let pan = step.panMinutes {
            lines.append("Pan time \(GalleyCookWords.minutes(pan))")
        }
        let door = DialDoor(id: "step.\(step.index)", name: step.short, color: accent,
                            label: "Step \(step.index + 1)", lines: lines)
        return SlotContent(id: ContentID("galley.cook.summary.\(step.index)"), kind: .summary, payload: .summary(door))
    }

    /// Next (marks the step done and turns to the next), then Timer, Read and Finish (hold).
    private var action: SlotContent {
        let primary = facts.isLast
            ? ShellStep(id: "finish", verb: "Finish", object: facts.recipe, hold: true)
            : ShellStep(id: "next", verb: "Next", object: facts.steps.indices.contains(facts.current + 1)
                ? facts.steps[facts.current + 1].short : "")
        var steps = [primary]
        steps.append(ShellStep(id: "timer", verb: "Timer",
                               object: facts.step?.timer == nil ? "Start" : "1 min more"))
        steps.append(ShellStep(id: "read", verb: "Read", object: "Step \(facts.current + 1)"))
        if !facts.isLast {
            steps.append(ShellStep(id: "finish", verb: "Finish", object: "", hold: true))
        }
        return SlotContent(id: "galley.cook.action", kind: .action, payload: .action(steps, accent: accent))
    }

    // MARK: The rail

    /// The step on as the big ticket, then a small ticket for each running pan timer; a done one reads "Ready".
    static func tickets(_ facts: GalleyCookFacts) -> [GalleyTicket] {
        var out: [GalleyTicket] = []
        if let step = facts.step {
            let left = step.timer.map { $0.left(at: facts.now) }
            let sub = left.map { $0 > 0 ? "\(GalleyCookWords.clock($0)) left" : "Ready" }
            var lines = [step.short]
            if !step.how.isEmpty {
                lines.append(step.how)
            }
            lines.append(contentsOf: step.ingredients.prefix(2))
            out.append(GalleyTicket(id: "cook.step", title: "Step \(step.index + 1)", sub: sub, lines: lines, big: true,
                                    ink: .dinner, opens: .cookTimer(step.index)))
        }
        var others = facts.steps.compactMap { step in step.timer.map { (step, $0) } }
            .filter { $0.0.index != facts.current }
        others.sort { $0.1.endsAt < $1.1.endsAt }
        for (step, timer) in others {
            let left = timer.left(at: facts.now)
            out.append(GalleyTicket(
                id: "cook.timer.\(step.index)",
                title: timer.label.isEmpty ? step.short : timer.label,
                sub: left > 0 ? GalleyCookWords.clock(left) : "Ready",
                lines: [],
                big: false,
                ink: left > 0 ? .toGet : .runsOut,
                opens: .cookTimer(step.index)
            ))
        }
        for timer in facts.spoken {
            let left = timer.left(at: facts.now)
            out.append(GalleyTicket(id: "cook.spoken.\(timer.id)", title: timer.label,
                                    sub: left > 0 ? GalleyCookWords.clock(left) : "Ready", lines: [], big: false,
                                    ink: left > 0 ? .toGet : .runsOut, opens: .cookTimer(-1)))
        }
        return out
    }
}
