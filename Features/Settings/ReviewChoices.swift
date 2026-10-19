import Foundation
import Observation

/// Switches Kaushik flips live to pick between two ways of doing something (batch mode, Oct 19). Each choice's
/// default is today's behavior; once he picks a winner it becomes the real default and the switch goes. Kept on this
/// iPhone only (UserDefaults), never in TesseraSettings, the op log or a backup. Under `-demo` nothing is written:
/// a pick lasts until the app quits.
@MainActor
@Observable
final class ReviewChoices {
    /// Where a switch stands: it works now, it waits for its feature, or it waits for something only Kaushik's
    /// build can have (an entitlement). A switch that waits shows today's value and can't be flipped.
    enum Readiness: Equatable, Sendable {
        case live
        case arrivesWith(String)
        case later
    }

    /// One switch: its name in the sentence, its values in the order a tap cycles them, the default (always today's
    /// behavior), what each value does in a few plain words, and whether it sends anything to Claude.
    struct Choice: Identifiable, Equatable, Sendable {
        let id: String
        let name: String
        let values: [String]
        let defaultValue: String
        /// One short line per value, for the before/after line: "Rest counts down after every set."
        let says: [String: String]
        /// The new way sends something to Claude. The type doesn't enforce it: the feature that reads the switch
        /// must also gate on "Tess asks Claude" (`AppModel.asksClaude`) and the month's cap, and a switch never turns
        /// Claude on by itself.
        var needsClaude = false
        var readiness: Readiness = .live
    }

    static let shared = ReviewChoices()

    /// Product's rows (huddle batches, Oct 19), in its order. A row turns `.live` in the PR that wires its feature.
    nonisolated static let all: [Choice] = [
        // Today leaves today's type tokens untouched; Sheet 99's sizes come through a switch-aware lookup.
        Choice(id: "readingLayout", name: "Reading layout", values: ["Today", "Sheet 99"], defaultValue: "Today",
               says: ["Today": "Groceries, Now, Exercise and Backups read as they do now.",
                      "Sheet 99": "Those four pages use three type sizes, refit for reading."],
               readiness: .arrivesWith("the sheet 99 refit")),
        Choice(id: "restTimer", name: "Rest timer", values: ["On", "Off"], defaultValue: "On",
               says: ["On": "Rest counts down after each set and says when it's up.",
                      "Off": "No countdown, no rest alert and no rest keys on the Lock Screen."],
               readiness: .arrivesWith("the rest-end alert")),
        Choice(id: "swapExercise", name: "Swap exercise", values: ["Two taps", "One tap"], defaultValue: "Two taps",
               says: ["Two taps": "Swap asks once, then swaps.",
                      "One tap": "Swap happens on the first tap, with UNDO."],
               readiness: .arrivesWith("easy swap")),
        Choice(id: "finishNudge", name: "Forgot Finish nudge", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "A workout left open waits quietly.",
                      "On": "One quiet nudge when a workout was left open."],
               readiness: .arrivesWith("the finish nudge")),
        Choice(id: "pageTurn", name: "Page turn", values: ["Today", "Slide", "Turn", "Soften", "Rotate"],
               defaultValue: "Today",
               says: ["Today": "Pages change as they do now.",
                      "Slide": "Pages slide across.",
                      "Turn": "Pages turn like paper.",
                      "Soften": "Pages soften into each other.",
                      "Rotate": "Pages rotate on their edge."],
               readiness: .arrivesWith("page turns")),
        Choice(id: "tessFace", name: "Tess has eyes", values: ["Off", "Eyes", "Eyes and mouth"], defaultValue: "Off",
               says: ["Off": "Tess is a plain mark, as now.", "Eyes": "Tess has eyes.",
                      "Eyes and mouth": "Tess has eyes and a small mouth."],
               readiness: .arrivesWith("Tess's mouth")),
        Choice(id: "planMyDay", name: "Plan my day, Claude wording", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "The morning plan in Tess's own words, as now.",
                      "On": "The same plan, worded by Claude."],
               needsClaude: true, readiness: .arrivesWith("Plan my day")),
        Choice(id: "shutdown", name: "Shutdown", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "No evening close.", "On": "A short close of the day on Now at 9 pm."],
               needsClaude: true, readiness: .arrivesWith("Shutdown")),
        Choice(id: "energyCheckIn", name: "Energy check-in", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "No check-in.", "On": "Tess asks how your energy is, once a day."],
               needsClaude: true, readiness: .arrivesWith("the check-in")),
        Choice(id: "quietInterrupts", name: "Quiet interrupts", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Notices come as they happen.",
                      "On": "During a workout or a cook, notices wait and come together."],
               readiness: .arrivesWith("notice grouping")),
        Choice(id: "calendar", name: "Calendar", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Your calendar stays out.", "On": "Busy times show on Now."], readiness: .later),
        Choice(id: "health", name: "Health", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Health stays out.", "On": "Workouts and weight sync with Health."], readiness: .later),
        Choice(id: "areasShown", name: "Areas shown", values: ["Today's", "All"], defaultValue: "Today's",
               says: ["Today's": "The area index shows today's areas.",
                      "All": "Body weight, Habits, Money, Reading, People and Upkeep show too."],
               readiness: .arrivesWith("the new areas")),
        Choice(id: "linkFetch", name: "Link reader v2", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Recipe links are read as they are now.",
                      "On": "A link the first reader can't read goes to a second reader, then Claude."],
               needsClaude: true, readiness: .arrivesWith("link reading")),
        Choice(id: "cookTimerVoice", name: "Cook timer voice", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "A cook timer ends with its alert.", "On": "Tess says the timer's name when it ends."],
               readiness: .arrivesWith("the timer voice")),
        Choice(id: "pantryState", name: "Pantry state", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "The pantry lists what you have.", "On": "Each pantry item shows how much is left."],
               readiness: .arrivesWith("pantry state")),
        Choice(id: "canCookShelf", name: "Can cook shelf", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Recipes in one shelf.", "On": "A CAN COOK shelf of what the pantry covers."],
               readiness: .arrivesWith("the CAN COOK shelf")),
        Choice(id: "handsFreeCook", name: "Hands-free cook mode", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Steps move on a tap.", "On": "Steps move by voice while you cook."],
               readiness: .arrivesWith("hands-free cooking")),
    ]

    /// The rows in pages of at most six, for the side swipe (Design sheet 100).
    nonisolated static func pages(_ choices: [Choice] = all, size: Int = 6) -> [[Choice]] {
        stride(from: 0, to: choices.count, by: size).map { Array(choices[$0 ..< min($0 + size, choices.count)]) }
    }

    private let defaults: UserDefaults
    private let writes: Bool
    private var picked: [String: String] = [:]

    init(defaults: UserDefaults = .standard, writes: Bool = !LaunchFlags.has("-demo")) {
        self.defaults = defaults
        self.writes = writes
    }

    private static func key(_ id: String) -> String {
        "review.\(id)"
    }

    /// The value in force: his pick this run, else the one kept on the phone, else the default. A kept value that
    /// is no longer one of the choice's values reads as the default, and so does any switch that isn't live yet.
    func value(of choice: Choice) -> String {
        guard choice.readiness == .live else { return choice.defaultValue }
        if let value = picked[choice.id] {
            return value
        }
        if writes, let kept = defaults.string(forKey: Self.key(choice.id)), choice.values.contains(kept) {
            return kept
        }
        return choice.defaultValue
    }

    /// Whether a choice is off its default.
    func isTrying(_ choice: Choice) -> Bool {
        value(of: choice) != choice.defaultValue
    }

    /// The next value in the cycle (or the one before), wrapping round.
    func step(_ choice: Choice, forward: Bool = true) {
        guard !choice.values.isEmpty, choice.readiness == .live else { return }
        let index = choice.values.firstIndex(of: value(of: choice)) ?? 0
        let next = (index + (forward ? 1 : choice.values.count - 1)) % choice.values.count
        set(choice, to: choice.values[next])
    }

    /// A switch that isn't live only ever goes back to its default (QA on #1096).
    func set(_ choice: Choice, to value: String) {
        guard choice.values.contains(value), choice.readiness == .live || value == choice.defaultValue else { return }
        picked[choice.id] = value
        guard writes else { return }
        if value == choice.defaultValue {
            defaults.removeObject(forKey: Self.key(choice.id))
        } else {
            defaults.set(value, forKey: Self.key(choice.id))
        }
    }

    /// Every switch back to today's behavior ("Everything as before").
    func resetAll(_ choices: [Choice] = ReviewChoices.all) {
        for choice in choices {
            set(choice, to: choice.defaultValue)
        }
    }

    /// Whether any switch is off its default, so "Everything as before" has something to do.
    func anyTrying(_ choices: [Choice] = ReviewChoices.all) -> Bool {
        choices.contains(where: isTrying)
    }

    /// The before/after line for a switch just flipped: "Before: Swap asks once, then swaps. Now: Swap happens on
    /// the first tap, with UNDO."
    func beforeAfter(_ choice: Choice, before: String) -> String {
        let now = value(of: choice)
        return "Before: \(choice.says[before] ?? before) Now: \(choice.says[now] ?? now)"
    }

    /// A switch by id, for the feature that reads it: `ReviewChoices.shared.value(of: "restTimer")`.
    func value(of id: String) -> String? {
        Self.all.first { $0.id == id }.map { value(of: $0) }
    }
}
