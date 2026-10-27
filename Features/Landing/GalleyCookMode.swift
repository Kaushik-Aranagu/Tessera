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

    struct Need: Equatable {
        let name: String
        var amount: String?
    }

    struct Step: Equatable, Identifiable {
        let index: Int
        /// The step in a few words, big: "Brown the chicken".
        let short: String
        /// The rest of the step: "Cumin and salt, leave it be".
        let how: String
        /// Its ingredients as a ledger: "Chicken thighs 1 lb".
        var ingredients: [String] = []
        /// The same, split for the dotted leaders: the name and its amount.
        var needs: [Need] = []
        /// The step as one line for the instruction (up to two lines at 46 pt).
        var line = ""
        /// The heat for the step ("Medium high"), from its words or its verb; nil when unknown.
        var heat: String?
        /// What goes in the pan, under the heat: "a spoon of oil".
        var heatNote: String?
        /// What tells you it is done ("Turn it when it lets go of the pan"); nil when unknown.
        var cue: String?
        /// The pan time the step names, in minutes, nil when it has none.
        var panMinutes: Double?
        /// The step's running timer, if one is.
        var timer: Timer?

        var id: Int {
            index
        }
    }

    var recipe = ""
    var serves: Int?
    var steps: [Step] = []
    /// The step he is on.
    var current = 0
    /// Minutes since this cook was opened (it counts from 0 for the session).
    var minutesIn = 0
    var minutesLeft = 0
    /// When it will be eaten, "6:35", from the plan's minutes left; nil when unknown.
    var eatAt: String?
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

    /// The step as one instruction line: its first sentence, at most ten words, no full stop.
    static func line(_ text: String) -> String {
        let words = sentence(text).split(separator: " ")
        return capital(words.prefix(10).joined(separator: " "))
    }

    /// Sheet 333: what the ticket printer feeds when a pan timer hits zero: "Chicken ready, off the heat". The food is
    /// named from the timer ("Brown the chicken" reads "Chicken"); a timer with no name reads "Timer".
    static func readyLine(label: String) -> String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        var food = trimmed.isEmpty ? "Timer" : trimmed
        let lower = food.lowercased()
        for lead in [
            "brown the ",
            "sear the ",
            "char the ",
            "soften the ",
            "cook the ",
            "fry the ",
            "bake the ",
            "roast the ",
        ]
            where lower.hasPrefix(lead)
        {
            food = String(food.dropFirst(lead.count))
            break
        }
        return "\(capital(food)) ready, off the heat"
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
}

/// The cooking mode's whole screen as data (sheet 328): what the view draws, top to bottom. Pure, so it tests.
struct GalleyCookScreen: Equatable {
    struct TimerRow: Equatable, Identifiable {
        let id: String
        let label: String
        /// "2:47", or "Ready".
        let time: String
        let ready: Bool
        /// Whole seconds left (0 once ready), for the digits that roll (sheet 346).
        var seconds = 0
    }

    /// "Tacos for 2".
    var title = ""
    /// Top right: "6 min in".
    var topRight = ""
    var number = ""
    /// "of 5", small beside the number.
    var of = ""
    var heat: String?
    var heatNote: String?
    /// The instruction, 46 pt, up to two lines.
    var instruction = ""
    var how = ""
    var doneWhen: String?
    var needs: [GalleyCookFacts.Need] = []
    var timers: [TimerRow] = []
    var verb = "Next"
    var object = ""
    var hold = false
    var rail: [GalleyRailItem] = []
    /// A pan time the step names that is not running: "Start 5 min", tap to start it.
    var start: String?

    init(_ facts: GalleyCookFacts) {
        title = facts.serves.map { "\(facts.recipe) for \($0)" } ?? facts.recipe
        topRight = "\(max(facts.minutesIn, 0)) min in" + (facts.eatAt.map { ", eat about \($0)" } ?? "")
        guard let step = facts.step else { return }
        number = "\(step.index + 1)"
        of = "of \(facts.steps.count)"
        heat = step.heat
        heatNote = step.heatNote
        instruction = step.line.isEmpty ? step.short : step.line
        // The instruction line already says what follows its few words: never say it twice.
        how = instruction.lowercased().contains(step.how.lowercased()) ? "" : step.how
        doneWhen = step.cue
        needs = Array(step.needs.prefix(4))
        var rows = facts.steps.compactMap { other in
            other.timer.map { timer -> (Int, TimerRow) in
                let left = timer.left(at: facts.now)
                return (other.index, TimerRow(id: timer.id, label: timer.label.isEmpty ? other.short : timer.label,
                                              time: left > 0 ? GalleyCookWords.clock(left) : "Ready", ready: left <= 0,
                                              seconds: Int(left.rounded(.up))))
            }
        }
        .sorted { $0.0 < $1.0 }.map(\.1)
        rows += facts.spoken.map { timer in
            let left = timer.left(at: facts.now)
            return TimerRow(id: timer.id, label: timer.label, time: left > 0 ? GalleyCookWords.clock(left) : "Ready",
                            ready: left <= 0, seconds: Int(left.rounded(.up)))
        }
        timers = Array(rows.prefix(3))
        if step.timer == nil, let pan = step.panMinutes {
            start = "Start \(GalleyCookWords.minutes(pan))"
        }
        if facts.isLast {
            verb = "Serve"
            object = facts.recipe
            hold = true
        } else {
            verb = "Next"
            object = facts.steps[facts.current + 1].short
        }
        rail = facts.steps.map { other in
            GalleyRailItem(id: other.index, label: other.short, detail: other.timer.map {
                let left = $0.left(at: facts.now)
                return left > 0 ? GalleyCookWords.clock(left) : "Ready"
            }, current: other.index == facts.current, done: other.index < facts.current)
        }
    }
}

/// The "Eat" summary that prints after the last Serve (sheet 337).
struct GalleyCookEat: Equatable {
    var title = "Eat"
    var dish = ""
    /// "Cooked in 38 min, 5 steps".
    var detail = ""

    init(_ facts: GalleyCookFacts) {
        dish = facts.serves.map { "\(facts.recipe) for \($0)" } ?? facts.recipe
        let minutes = max(facts.minutesIn, 0)
        let steps = facts.steps.count
        detail = "Cooked in \(minutes) min, \(steps) \(steps == 1 ? "step" : "steps")"
    }
}
