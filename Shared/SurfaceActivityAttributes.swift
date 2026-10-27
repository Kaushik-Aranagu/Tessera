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
        guard let soonest = running.first else { return nil }
        let shift = realNow.timeIntervalSince(appNow)
        let end = Date(timeIntervalSinceReferenceDate: soonest.endsAt.addingTimeInterval(shift)
            .timeIntervalSinceReferenceDate.rounded())
        return CookActivityAttributes.ContentState(
            timerLabel: isPrivate ? "Timer" : soonest.label, endsAt: end,
            total: max(soonest.endsAt.timeIntervalSince(soonest.startedAt), 1),
            others: running.count - 1, nextStep: isPrivate ? nil : nextStep
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
