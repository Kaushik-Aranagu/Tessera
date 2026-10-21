import Foundation

/// Names for training days (Kaushik, Oct 19: "Tess names training days"). The engine side: what may be sent, the
/// local rule name, the check every proposed name passes, and the action that applies one. The phone's own model
/// and Claude live above (`DayNamer`); this file knows neither.
///
/// His own name always wins: a routine is auto-named only while its title is empty or a placeholder, or still
/// exactly the name Tess gave it. A private routine is never auto-named.
public enum DayNames {
    /// The Review switch "Tess names training days", default On.
    public static let reviewKey = "trainingAutoName"
    /// `autoNameKey` after he took a name from "Suggest a name": auto-naming never touches that routine again.
    static let chosenMark = "chosen"
    static let placeholders: Set = ["", "new routine", "untitled", "routine", "new day", "workout"]

    /// What a naming call may carry: exercise names and muscle words, nothing else.
    public struct Pack: Equatable, Sendable {
        public let exercises: [String]
        public let muscles: [String]
        /// The rule names for this day, best first (from what its exercises really work).
        public let ruleNames: [String]
        /// Changes when the exercises do, so an unchanged routine is not asked again.
        public var key: String {
            exercises.map { $0.lowercased() }.sorted().joined(separator: "|")
        }
    }

    /// The pack for a routine, or nil: a private routine or exercise, or one with no exercises yet.
    @MainActor
    public static func pack(of routine: ObjectRecord, store: ObjectStore) -> Pack? {
        let last = BodyWeight.lastKg(in: store)
        guard ObjectPrivacy.routineTitle(routine.title, in: store) != ObjectPrivacy.routineLabel,
              store.value("isPrivate", of: routine) != .bool(true) else { return nil }
        var names: [String] = []
        for slot in routine.orderedChildren where !slot.isDeleted {
            guard let exercise = store.linkedClass("exercise", of: slot) else { continue }
            if PrivateWords.isPrivateTitle(exercise.name, lastWeightKg: last) || SecretWords.mentions(exercise.name) {
                return nil
            }
            if !names.contains(exercise.name) {
                names.append(exercise.name)
            }
        }
        guard !names.isEmpty else { return nil }
        let muscles = MuscleSummary.topWords(of: routine, store: store, limit: 5)
        let rules = DayRuleNames.choices(DayRuleNames.shape(of: routine, store: store))
        return Pack(exercises: names, muscles: muscles,
                    ruleNames: rules.isEmpty ? localChoices(muscles: muscles) : rules)
    }

    static let legs: Set = ["quads", "glutes", "hamstrings", "calves", "inner thighs", "outer hips"]
    static let push: Set = ["chest", "shoulders", "triceps"]
    static let pull: Set = ["back", "biceps", "forearms"]
    static let trunk: Set = ["abs", "core"]

    /// The rule names from the muscle words, plainest first ("Leg day", then "Lower body", "Legs"), so "Suggest a
    /// name" can offer a different one each time. Empty when there are no muscles.
    public static func localChoices(muscles: [String]) -> [String] {
        let words = Set(muscles)
        guard !words.isEmpty else { return [] }
        let down = !words.isDisjoint(with: legs), pushes = !words.isDisjoint(with: push)
        let pulls = !words.isDisjoint(with: pull), middle = !words.isDisjoint(with: trunk)
        let heavyLegs = legs.intersection(words).count >= words.subtracting(trunk).count / 2 + 1
        switch (down, pushes || pulls) {
        case (true, true):
            return heavyLegs ? ["Leg day", "Legs and upper", "Full body"] : ["Full body", "Legs and upper", "Leg day"]
        case (true, false): return ["Leg day", "Lower body", "Legs"]
        case (false, true):
            if pushes, !pulls {
                return ["Push day", "Push", "Chest and shoulders"]
            }
            if pulls, !pushes {
                return ["Pull day", "Pull", "Back and biceps"]
            }
            return ["Upper body", "Push and pull", "Upper day"]
        case (false, false): return middle ? ["Core day", "Core", "Abs and core"] : []
        }
    }

    /// The plainest rule name, or nil.
    public static func localName(muscles: [String]) -> String? {
        localChoices(muscles: muscles).first
    }

    static let longest = 22
    static let hype: Set = ["beast", "crush", "destroy", "gains", "shred", "grind", "blast", "ultimate", "domination",
                            "therapy", "workout"]
    static let articles: Set = ["a", "an", "the"]

    /// Whether a proposed name may be used (Design's style): one to three words, 22 characters or fewer, letters and
    /// spaces only (no digits, punctuation, emoji or quotes), no leading article, none of the hype words, nothing
    /// walled.
    @MainActor
    public static func isUsable(_ name: String) -> Bool {
        let text = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = text.lowercased().split(separator: " ").map(String.init)
        guard !text.isEmpty, text.count <= longest, (1 ... 3).contains(words.count),
              text.allSatisfy({ $0.isLetter || $0 == " " }), !articles.contains(words[0]),
              hype.isDisjoint(with: words), !text.contains("  "),
              !SecretWords.mentions(text), !PrivateWords.isPrivateTitle(text, lastWeightKg: nil) else { return false }
        return true
    }

    /// Whether another routine already carries exactly this name (any case): a name is never reused.
    @MainActor
    public static func isTaken(_ name: String, besides routine: ObjectRecord, store: ObjectStore,
                               classes: [SystemCatalog.Key: ClassDef]) -> Bool
    {
        guard let routineClass = classes[.routine] else { return false }
        return store.objects(of: routineClass).contains {
            $0.id != routine.id && !$0.isDeleted && $0.title.lowercased() == name.lowercased()
        }
    }

    /// The stock day titles the app itself made ("Push A", "Pull B", "Legs A", the demo's "Push Day A") and plain
    /// stock patterns of the same kind ("Push day", "Legs"): not a name he chose, so Tess may replace one once.
    static func isStockTitle(_ title: String) -> Bool {
        title.lowercased().firstMatch(of: /^(?:push|pull|legs?)(?: day)?(?: [a-z])?$/) != nil
    }

    /// Whether Tess may name this routine now: never a private one; only while the title is empty, a placeholder,
    /// a stock title never yet renamed by Tess, or still the name Tess gave it. Any other name is his.
    @MainActor
    public static func mayAutoName(_ routine: ObjectRecord, store: ObjectStore) -> Bool {
        guard pack(of: routine, store: store) != nil else { return false }
        let title = routine.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let given = store.value("autoName", of: routine)?.stringValue ?? ""
        // A name taken from "Suggest a name" is his choice for good, even if it looks like a stock title.
        if store.value("autoNameKey", of: routine)?.stringValue == chosenMark {
            return false
        }
        if !given.isEmpty {
            return title == given
        }
        // Never named by Tess (or taken from Suggest, which clears the mark): a placeholder or stock title is fair.
        return placeholders.contains(title.lowercased()) || isStockTitle(title)
    }

    /// `autoNameBy`: who made the name Tess gave. A rule name may be improved once by a model; a model's name and
    /// any name he typed never are.
    public static let byRules = "rules", byModel = "model"

    /// Whether the name on this routine is one Tess made from rules (and is still on it).
    @MainActor
    public static func isRuleNamed(_ routine: ObjectRecord, store: ObjectStore) -> Bool {
        let given = store.value("autoName", of: routine)?.stringValue ?? ""
        guard !given.isEmpty, routine.title == given else { return false }
        let by = store.value("autoNameBy", of: routine)?.stringValue ?? ""
        return by == byRules || isUnmarked(routine, store: store)
    }

    /// Named by Tess before the "named by" marker existed: it is given the new rule name once.
    /// Only a name the old rules could have made counts: an older name that Claude or the phone's model made is
    /// left alone, as it would be today.
    @MainActor
    public static func isUnmarked(_ routine: ObjectRecord, store: ObjectStore) -> Bool {
        let given = store.value("autoName", of: routine)?.stringValue ?? ""
        guard !given.isEmpty, routine.title == given,
              (store.value("autoNameBy", of: routine)?.stringValue ?? "").isEmpty else { return false }
        let muscles = MuscleSummary.topWords(of: routine, store: store, limit: 5)
        return localChoices(muscles: muscles).contains(given)
    }

    /// The name last given and the exercises it was given for.
    @MainActor
    public static func given(to routine: ObjectRecord, store: ObjectStore) -> (name: String, key: String)? {
        guard let name = store.value("autoName", of: routine)?.stringValue, !name.isEmpty else { return nil }
        return (name, store.value("autoNameKey", of: routine)?.stringValue ?? "")
    }

    /// Whether the routine's exercises changed since it was named (or it was never named): time to ask again.
    /// A rule-made name also waits for one better name (the pass only applies it if a model has one).
    @MainActor
    public static func needsName(_ routine: ObjectRecord, store: ObjectStore) -> Bool {
        guard mayAutoName(routine, store: store), let pack = pack(of: routine, store: store) else { return false }
        return given(to: routine, store: store)?.key != pack.key || isRuleNamed(routine, store: store)
    }

    /// Whether the routine's rule name is for its current exercises, so only a model's name would improve it.
    @MainActor
    public static func isUpgradeOnly(_ routine: ObjectRecord, store: ObjectStore) -> Bool {
        guard isRuleNamed(routine, store: store), let pack = pack(of: routine, store: store) else { return false }
        return given(to: routine, store: store)?.key == pack.key
    }
}

/// Gives a routine a proposed name. `force` is his "Suggest a name" tap: it renames whatever the title is and
/// counts as his own choice from then on.
/// Otherwise it applies only while `DayNames.mayAutoName` holds. A name that fails `DayNames.isUsable` is refused.
public struct ApplyDayName: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "applyDayName", summary: "Name a training day",
        parameters: [
            .init("routine", .object, "The routine"),
            .init("name", .string, "The proposed name"),
            .init("force", .boolean, "He asked for a suggestion", required: false),
        ], isOfferedToModel: false
    )

    public var routine: UUID
    public var name: String
    public var force: Bool?
    /// "rules" or "model"; nil works it out (a name among the day's rule names was made by rules).
    public var source: String?

    public init(routine: UUID, name: String, force: Bool? = nil, source: String? = nil) {
        self.routine = routine
        self.name = name
        self.force = force
        self.source = source
    }

    public func apply(_ transaction: inout Transaction) throws {
        let target = try transaction.object(routine, is: .routine)
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard DayNames.isUsable(clean) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that name will not fit")
        }
        let store = transaction.store
        guard let pack = DayNames.pack(of: target, store: store) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that routine stays unnamed")
        }
        guard force == true || DayNames.mayAutoName(target, store: store) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "he named it himself")
        }
        guard !DayNames.isTaken(clean, besides: target, store: store, classes: transaction.classes) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "another day has that name")
        }
        transaction.setTitle(clean, on: target)
        // A name he takes from "Suggest a name" is his choice: auto-naming stops (nothing remembered as Tess's).
        try transaction.set("autoName", to: .text(force == true ? "" : clean), on: target)
        try transaction.set("autoNameKey", to: .text(force == true ? DayNames.chosenMark : pack.key), on: target)
        let by = source ?? (pack.ruleNames.contains(clean) ? DayNames.byRules : DayNames.byModel)
        try transaction.set("autoNameBy", to: .text(force == true ? DayNames.byModel : by), on: target)
    }

    public func summary(in store: ObjectStore) -> String {
        "Named \(store.object(id: routine)?.title ?? "a day") “\(name)”"
    }
}
