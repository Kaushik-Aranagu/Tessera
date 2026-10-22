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
               readiness: .live),
        Choice(id: "swapExercise", name: "Swap exercise", values: ["Two taps", "One tap"], defaultValue: "Two taps",
               says: ["Two taps": "Swap asks once, then swaps.",
                      "One tap": "Swap happens on the first tap, with UNDO."],
               readiness: .live),
        Choice(id: "finishNudge", name: "Forgot Finish nudge", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "A workout left open waits quietly.",
                      "On": "One quiet nudge when a workout was left open."],
               readiness: .live),
        Choice(
            id: "lockScreenLook",
            name: "Lock Screen look",
            values: ["Cobalt sky", "Follows the look"],
            defaultValue: "Cobalt sky",
            says: ["Cobalt sky": "The rest card on the Lock Screen is Cobalt sky in every look.",
                   "Follows the look": "The rest card takes your day or night look. The Island stays Obsidian."],
            readiness: .live
        ),
        Choice(id: "pageTurn", name: "Page turn", values: ["Today", "Slide", "Turn", "Soften", "Rotate"],
               defaultValue: "Today",
               says: ["Today": "Pages change as they do now.",
                      "Slide": "Pages slide across.",
                      "Turn": "Pages turn like paper.",
                      "Soften": "Pages soften into each other.",
                      "Rotate": "Pages rotate on their edge."],
               readiness: .live),
        // Core's #1160 (Kaushik, Oct 19, 7:12 PM): the phone's own model first, Claude only with "Tess asks Claude";
        // a private routine stays "Private workout"; his own name stops it. Off leaves every name to him.
        Choice(id: "trainingAutoName", name: "Tess names training days", values: ["On", "Off"], defaultValue: "On",
               says: ["On": "A new training day gets a short name from its exercises until you name it.",
                      "Off": "Training days keep the name you give them."],
               // It can send exercise names to Claude when "Tess asks Claude" is on and the phone has no model of
               // its own (QA on #1170); the switch never turns Claude on.
               needsClaude: true, readiness: .live),
        Choice(id: "tabs.neighbours", name: "Tab neighbours", values: ["Blurred", "Crisp"], defaultValue: "Blurred",
               says: ["Crisp": "The tabs beside the current one read crisp and faint.",
                      "Blurred": "The tabs beside the current one soften into a blur."],
               readiness: .live),
        // Off and Eyes only until the mouth is drawn (Builder A's #1125 reads it).
        Choice(id: "tessFace", name: "Tess has eyes", values: ["Off", "Eyes"], defaultValue: "Off",
               says: ["Off": "Tess is a plain mark, as now.", "Eyes": "Tess has eyes."],
               readiness: .live),
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
        // Kaushik, Oct 21: example content on every screen, kept apart from his own; Off is his data, untouched.
        Choice(id: "sampleData", name: "Sample data", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Every screen shows your own things.",
                      "On": "Every screen shows example things; yours come back untouched when it's off."],
               readiness: .live),
        Choice(id: "landingPages", name: "Landing pages", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Each app opens on its list of ways in.",
                      "On": "Each app opens on a page that tells you where things stand."],
               readiness: .live),
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
               readiness: .live),
        Choice(id: "pantryState", name: "Pantry state", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "The pantry lists what you have.", "On": "Each pantry item shows how much is left."],
               readiness: .arrivesWith("pantry state")),
        Choice(id: "canCookShelf", name: "Can cook shelf", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Recipes in one shelf.", "On": "A CAN COOK shelf of what the pantry covers."],
               readiness: .arrivesWith("the CAN COOK shelf")),
        Choice(id: "handsFreeCook", name: "Hands-free cook mode", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Steps move on a tap.", "On": "Steps move by voice while you cook."],
               readiness: .live),
        // Kitchen v2 (kitchen-v2-build-ready-rows-oct19.md): each its own switch, default Off.
        Choice(id: "weekStrip", name: "Week strip", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Plans show on the week side only.",
                      "On": "A Mon to Sun strip with one key to add the week to Groceries."],
               readiness: .arrivesWith("the week strip")),
        Choice(id: "repeatItems", name: "Repeat items", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "A bought item leaves with the shop.",
                      "On": "An item marked every week comes back after the shop ends."],
               readiness: .arrivesWith("repeat items")),
        Choice(id: "cookDouble", name: "Cook double", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "\"Cook double\" is not understood.",
                      "On": "It doubles the cook and puts a leftovers task on Later."],
               readiness: .arrivesWith("cook double")),
        Choice(id: "parallelSteps", name: "Parallel steps", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "One lane, steps one after another.",
                      "On": "Meanwhile steps run on a second lane with their own timer."],
               readiness: .live),
        Choice(id: "cookNotes", name: "Cook notes on the recipe", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Notes live with each cook.", "On": "The newest note shows on the recipe page."],
               readiness: .live),
        Choice(id: "fixRecipe", name: "Fix a recipe", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Paste again to change a recipe.",
                      "On": "FIX opens the recipe to change lines and steps."],
               readiness: .arrivesWith("recipe fixing")),
        Choice(id: "usuallyLine", name: "Usually line", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Groceries and Pantry end with no usually line.",
                      "On": "Up to 4 things you buy on a rhythm show at the foot."],
               readiness: .arrivesWith("the usually line")),
        Choice(id: "aisleOrder", name: "Learned aisle order", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Aisles in the fixed walk order.", "On": "Aisles in the order you walked last shop."],
               readiness: .arrivesWith("aisle order")),
        Choice(id: "classInspector", name: "Class inspector", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "A class shows its objects.", "On": "A class also shows its fields, to shape it."],
               readiness: .arrivesWith("the class inspector")),
        // Design 116: the type pair. Default is the new pair; "As before" is the Inter Tight look.
        Choice(
            id: "font",
            name: "Font",
            values: ["Figtree and Outfit", "As before"],
            defaultValue: "Figtree and Outfit",
            says: ["Figtree and Outfit": "Figtree for words, Outfit for numbers.",
                   "As before": "Inter Tight for everything."],
            readiness: .live
        ),
        // Design 110: on, the kcal line shows on a finished workout; it needs weight and height under Me.
        Choice(id: "caloriesBurned", name: "Calories burned", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "No calorie line.", "On": "A finished workout shows the calories burned."],
               readiness: .arrivesWith("calories burned")),
    ]

    /// Review's tabs by facet, named in PeekTabs (Design sheets 100 and 108), six rows at most.
    nonisolated static let facets: [(word: String, ids: [String])] = [
        ("Looks and day", ["readingLayout", "pageTurn", "tabs.neighbours", "tessFace", "lockScreenLook", "font"]),
        // Design 110: Calories burned and Energy check-in sit with the workout; Class inspector with Shown.
        // Tess names training days joins Workout; Quiet interrupts (notices) moves to Connected to keep six a page.
        (
            "Workout",
            ["restTimer", "swapExercise", "finishNudge", "trainingAutoName", "caloriesBurned", "energyCheckIn"]
        ),
        // Kitchen v2 adds eight rows: what is in the house and the shop on Kitchen, the cook itself on Cooking.
        ("Kitchen", ["pantryState", "canCookShelf", "weekStrip", "repeatItems", "usuallyLine", "aisleOrder"]),
        ("Cooking", ["cookTimerVoice", "handsFreeCook", "parallelSteps", "cookNotes", "cookDouble", "fixRecipe"]),
        ("Connected", ["planMyDay", "shutdown", "quietInterrupts", "calendar", "health", "linkFetch"]),
        ("Shown", ["sampleData", "landingPages", "areasShown", "classInspector"]),
    ]

    /// The facet pages with their rows, in the facets' order; a row no facet names goes on a last "More" page.
    /// The pages Settings draws: only rows whose feature ships in this build (Product, Oct 20; sheet 110). A waiting
    /// row is not drawn at all, and a tab with nothing live goes with it.
    nonisolated static func drawnPages(_ choices: [Choice] = all) -> [(word: String, rows: [Choice])] {
        facetPages(choices.filter { $0.readiness == .live })
    }

    nonisolated static func facetPages(_ choices: [Choice] = all) -> [(word: String, rows: [Choice])] {
        var pages = facets.map { facet in
            (word: facet.word, rows: facet.ids.compactMap { id in choices.first { $0.id == id } })
        }.filter { !$0.rows.isEmpty }
        let named = Set(facets.flatMap(\.ids))
        let rest = choices.filter { !named.contains($0.id) }
        if !rest.isEmpty {
            pages.append((word: "More", rows: rest))
        }
        return pages
    }

    /// The rows in pages of at most six, in order, for any caller that pages without facets.
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
