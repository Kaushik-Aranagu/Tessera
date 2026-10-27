import ActivityKit
import Foundation

/// Cook's Live Activity (Design 142): the soonest timer in ochre, "+2" for the others, and the next step. Started
/// only while the Review switch "Surfaces v2" is On. Everything here is masked at the source: a private recipe
/// carries "Private recipe", "Timer" and no step.
struct CookActivityAttributes: ActivityAttributes {
    /// The recipe's name, already masked.
    var recipeName: String

    struct ContentState: Codable, Hashable {
        /// The soonest running timer.
        var timerLabel: String
        var endsAt: Date
        var total: TimeInterval
        /// How many other timers are running (the "+2").
        var others: Int
        /// The next step's text, nil for a private recipe or when there is none.
        var nextStep: String?
        /// Sheet 344: the food whose pan timer has just ended ("Chicken"); nil while every timer still runs. When set
        /// the
        /// activity reads "READY, OFF THE HEAT" (`CookFace.readyLine`) and the island shows the food and the word.
        var readyFood: String?
        /// Sheet 344: the next timer that is still running, as the words after its countdown: "onions to go". The
        /// countdown itself is `endsAt` when no timer is ready, else `nextEndsAt`.
        var nextLabel: String?
        var nextEndsAt: Date?
        /// Sheet 344: opens the ticket with the alert printed (`CookFace.alertLink`).
        var link: URL?

        var interval: ClosedRange<Date> {
            let start = endsAt.addingTimeInterval(-max(total, 1))
            return start ... max(endsAt, start)
        }

        /// "+2": only when other timers run.
        var plusWord: String? {
            CookFace.plusWord(others: others)
        }
    }
}

/// A Routine's Live Activity (Design 142): its step with the Thread in rose. The Thread is one bead per step, the
/// one he is on lit.
struct RoutineActivityAttributes: ActivityAttributes {
    /// The routine's name, already masked ("Private routine").
    var routineName: String

    struct ContentState: Codable, Hashable {
        var step: String
        /// 1-based position of the step.
        var position: Int
        var count: Int
        var startedAt: Date
    }
}

struct CookTimerInput: Equatable {
    var label: String
    var endsAt: Date
    var startedAt: Date
}

enum CookFace {
    static let privateRecipe = "Private recipe"
    /// Sheet 344: what the activity and the island say when a pan timer ends.
    static let readyLine = "READY, OFF THE HEAT"

    /// The deep link the activity opens: the cook's ticket with the alert already printed. A private cook names no food
    /// in the link, only that something is ready.
    static func alertLink(cook: UUID, food: String?) -> URL? {
        var parts = URLComponents()
        parts.scheme = "tessera"
        parts.host = "cook"
        parts.queryItems = [URLQueryItem(name: "cook", value: cook.uuidString),
                            URLQueryItem(name: "alert", value: food ?? "")]
        return parts.url
    }

    /// "Chicken" from a timer's label ("Brown the chicken" reads "Chicken"); a hidden label reads "Timer".
    static func food(from label: String) -> String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Timer" }
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
            where trimmed.lowercased().hasPrefix(lead)
        {
            let rest = String(trimmed.dropFirst(lead.count))
            return rest.prefix(1).uppercased() + rest.dropFirst()
        }
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }

    /// "onions to go": the next timer's label as the words after its countdown.
    static func toGo(_ label: String) -> String {
        "\(food(from: label).lowercased()) to go"
    }

    /// "+2" for two other timers; nothing when the soonest runs alone.
    static func plusWord(others: Int) -> String? {
        others > 0 ? "+\(others)" : nil
    }

    /// The next step as one short line for a Lock Screen: its first sentence, and if that is still long, whole words
    /// only (never an ellipsis).
    static func shortStep(_ text: String, most: Int = 80) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // The first sentence, shown with no closing stop (Kaushik, Oct 26).
        var sentence = trimmed.range(of: ". ")
            .map { String(trimmed[..<$0.lowerBound]).trimmingCharacters(in: .whitespaces) }
            ?? trimmed
        if sentence.hasSuffix("."), !sentence.hasSuffix("..") {
            sentence.removeLast()
        }
        guard sentence.count > most else { return sentence }
        var line = ""
        for word in sentence.split(separator: " ") {
            let next = line.isEmpty ? String(word) : line + " " + word
            if next.count > most {
                break
            }
            line = next
        }
        return line.trimmingCharacters(in: CharacterSet(charactersIn: ",;:"))
    }

    /// The activity's state from a cook's timers. Only timers still running count. `appNow` is the app clock (a demo
    /// may shift it); the countdown runs on the real clock, so the end moves onto it, rounded to the second.
    static func state(timers: [CookTimerInput], nextStep: String?, isPrivate: Bool, appNow: Date,
                      realNow: Date) -> CookActivityAttributes.ContentState?
    {
        let running = timers.filter { $0.endsAt > appNow }.sorted { $0.endsAt < $1.endsAt }
        let ended = timers.filter { $0.endsAt <= appNow }.sorted { $0.endsAt > $1.endsAt }
        let shift = realNow.timeIntervalSince(appNow)
        // The last timer has just ended: the activity stays to say so (sheet 344) until the cook dismisses it.
        guard let soonest = running.first else {
            guard let done = ended.first else { return nil }
            let end = Date(timeIntervalSinceReferenceDate: done.endsAt.addingTimeInterval(shift)
                .timeIntervalSinceReferenceDate.rounded())
            return CookActivityAttributes.ContentState(
                timerLabel: isPrivate ? "Timer" : done.label, endsAt: end,
                total: max(done.endsAt.timeIntervalSince(done.startedAt), 1), others: 0, nextStep: nil,
                readyFood: isPrivate ? "Timer" : food(from: done.label)
            )
        }
        let end = Date(timeIntervalSinceReferenceDate: soonest.endsAt.addingTimeInterval(shift)
            .timeIntervalSinceReferenceDate.rounded())
        return CookActivityAttributes.ContentState(
            timerLabel: isPrivate ? "Timer" : soonest.label, endsAt: end,
            total: max(soonest.endsAt.timeIntervalSince(soonest.startedAt), 1),
            others: running.count - 1, nextStep: isPrivate ? nil : nextStep,
            readyFood: ended.first.map { isPrivate ? "Timer" : food(from: $0.label) },
            nextLabel: running.count > 1 ? (isPrivate ? "timer to go" : toGo(running[1].label)) : nil,
            nextEndsAt: running.count > 1
                ? Date(timeIntervalSinceReferenceDate: running[1].endsAt.addingTimeInterval(shift)
                    .timeIntervalSinceReferenceDate.rounded()) : nil
        )
    }
}

enum RoutineFace {
    static let privateStep = "Private step"

    static func state(step: String, position: Int, count: Int, startedAt: Date,
                      isPrivate: Bool) -> RoutineActivityAttributes.ContentState
    {
        let total = max(count, 1)
        return RoutineActivityAttributes.ContentState(
            step: isPrivate ? privateStep : step, position: min(max(position, 1), total), count: total,
            startedAt: startedAt
        )
    }
}
