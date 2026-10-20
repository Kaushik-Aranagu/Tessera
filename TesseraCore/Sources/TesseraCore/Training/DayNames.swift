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
    static let placeholders: Set = ["", "new routine", "untitled", "routine", "new day", "workout"]

    /// What a naming call may carry: exercise names and muscle words, nothing else.
    public struct Pack: Equatable, Sendable {
        public let exercises: [String]
        public let muscles: [String]
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
        return Pack(exercises: names, muscles: MuscleSummary.topWords(of: routine, store: store, limit: 5))
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

    /// Whether Tess may name this routine now: never a private one; only while the title is empty, a placeholder,
    /// or still the name Tess gave it.
    @MainActor
    public static func mayAutoName(_ routine: ObjectRecord, store: ObjectStore) -> Bool {
        guard pack(of: routine, store: store) != nil else { return false }
        let title = routine.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let given = store.value("autoName", of: routine)?.stringValue ?? ""
        return placeholders.contains(title.lowercased()) || (!given.isEmpty && title == given)
    }

    /// The name last given and the exercises it was given for.
    @MainActor
    public static func given(to routine: ObjectRecord, store: ObjectStore) -> (name: String, key: String)? {
        guard let name = store.value("autoName", of: routine)?.stringValue, !name.isEmpty else { return nil }
        return (name, store.value("autoNameKey", of: routine)?.stringValue ?? "")
    }

    /// Whether the routine's exercises changed since it was named (or it was never named): time to ask again.
    @MainActor
    public static func needsName(_ routine: ObjectRecord, store: ObjectStore) -> Bool {
        guard mayAutoName(routine, store: store), let pack = pack(of: routine, store: store) else { return false }
        return given(to: routine, store: store)?.key != pack.key
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

    public init(routine: UUID, name: String, force: Bool? = nil) {
        self.routine = routine
        self.name = name
        self.force = force
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
        try transaction.set("autoNameKey", to: .text(pack.key), on: target)
    }

    public func summary(in store: ObjectStore) -> String {
        "Named \(store.object(id: routine)?.title ?? "a day") “\(name)”"
    }
}
