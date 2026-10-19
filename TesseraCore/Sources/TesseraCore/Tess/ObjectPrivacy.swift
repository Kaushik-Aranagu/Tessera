import Foundation

/// What a private object shows outside its own editor: only its class's label ("Private note", "Private task",
/// "Private memory"), never its title, fields, notes or links (board 0ai mask, Product 2:45 PM PT amended 2:55;
/// Research private-field-mask PM1 to PM20). A computed check, so no new field and no catalog change: a note or a
/// memory
/// is private by its stored flag, or by a secret word, money or a body fact in its words; a task by its title.
public enum ObjectPrivacy {
    public static let noteLabel = SecretWords.title
    public static let taskLabel = "Private task"
    public static let memoryLabel = "Private memory"
    /// A recipe has no flag on master; the title rule decides (kitchen-week-one-private-filter PF4, gap hunt G21).
    public static let recipeLabel = "Private recipe"
    /// What a workout's notes read on the generic page (Product 5:20 PM PT).
    public static let keptNoteLabel = "Note kept private"
    /// What a private routine's title reads wherever a workout shows its name: the Done hero and line, the UNDO line,
    /// the Live Activity and the live workout's context line (Product, decisions 12:35 PM on #849).
    public static let routineLabel = "Private workout"

    /// A routine's title wherever it shows: "Private workout" when the title is private, else the title as it is.
    @MainActor
    public static func routineTitle(_ title: String, in store: ObjectStore) -> String {
        PrivateWords.isPrivateTitle(title, lastWeightKg: BodyWeight.lastKg(in: store)) ? routineLabel : title
    }

    /// The label to show in place of the object, or nil when it isn't private.
    @MainActor
    public static func label(of object: ObjectRecord, in store: ObjectStore,
                             classes: [SystemCatalog.Key: ClassDef]) -> String?
    {
        guard let classDef = object.classDef else { return nil }
        func isA(_ key: SystemCatalog.Key) -> Bool {
            classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
        }
        let flagged = store.value("isPrivate", of: object) == .bool(true)
        let last = BodyWeight.lastKg(in: store)
        func isPrivateText(_ text: String) -> Bool {
            Self.isPrivateText(text, lastWeightKg: last)
        }
        if isA(.note) {
            let body = store.value("body", of: object)?.stringValue ?? ""
            return flagged || object.title == noteLabel || isPrivateText(object.title) || isPrivateText(body)
                ? noteLabel : nil
        }
        if isA(.tessMemory) {
            let rule = store.value("rule", of: object)?.stringValue ?? ""
            return flagged || isPrivateText(object.title) || isPrivateText(rule) ? memoryLabel : nil
        }
        if isA(.task) {
            return object.title == taskLabel || PrivateFacts
                .isPrivateTitle(object.title, lastWeightKg: last) ? taskLabel : nil
        }
        if isA(.recipe) {
            return isPrivateRecipeTitle(object.title, lastWeightKg: last) ? recipeLabel : nil
        }
        // An ingredient masks on the one check, like the item it becomes on Groceries (G103, G105). Items and lists
        // are #895's branches.
        if isA(.ingredient) {
            return isPrivateRecipeTitle(object.title, lastWeightKg: last) ? "Private item" : nil
        }
        return nil
    }

    /// The one check for a title or a word he typed (G105): a secret word, money, a body fact, a medicine, or one of
    /// the
    /// money and health title words ("dentist", "therapy", "clinic", "rent"). Receipts, UNDO, Tess lines, screens and
    /// the shared export all ask this, so a thing reads private everywhere or nowhere ("Dentist cake" is "Private
    /// recipe" on a screen and in a file alike).
    public static func isPrivateTitle(_ text: String, lastWeightKg: Double?) -> Bool {
        if text == SecretWords.title {
            return true
        }
        // A grocery amount that opens the line ("5 kg flour", "1 pound butter") is never masked as money or a weigh-in:
        // those rules are for money and body lines. A secret, a medicine or a title word still is, and so is whatever
        // follows the amount ("5 kg flour and weighed 82 kg"). An amount in the middle of a line is not this case.
        if let rest = withoutLeadingAmount(text) {
            return SecretWords.mentions(text) || hasTitleWord(text) || isDoctorName(text) || EngineWall.isMedicine(text)
                || (!rest.trimmingCharacters(in: .whitespaces).isEmpty
                    && (isPrivateText(rest, lastWeightKg: lastWeightKg)
                        || EngineWall.isHealth(rest, lastWeightKg: lastWeightKg)))
        }
        if isPrivateText(text, lastWeightKg: lastWeightKg) {
            return true
        }
        return hasTitleWord(text) || isDoctorName(text)
            // A bare medicine is a health fact: "lexapro", "advil", "take melatonin".
            || EngineWall.isHealth(text, lastWeightKg: lastWeightKg)
    }

    /// The text after a grocery amount that opens it ("2 kg rice" then the rest), or nil when it does not open with
    /// one.
    static func withoutLeadingAmount(_ text: String) -> String? {
        let lower = text.lowercased()
        guard let match = lower.firstMatch(
            of: /^\s*\d+(?:[.,]\d+)?\s*(?:kg|kgs|lb|lbs|pound|pounds|kilo|kilos|g|oz|ml|l)\s+[a-z]+/
        ), AddListItem.isAmountOfAThing(String(match.0)) else { return nil }
        return String(lower[match.range.upperBound...])
    }

    /// A title word, or its plural ("dentists"); joined words ("dentist-appt") are not.
    static func hasTitleWord(_ text: String) -> Bool {
        PrivateFacts.words(text.lowercased()).contains { word in
            titleWords.contains(word) || (word.hasSuffix("s") && titleWords.contains(String(word.dropLast())))
        }
    }

    /// "Dr. Patel" and "Dr Patel": a "dr" with a stop, or followed by a capitalised name other than Pepper. A bare "dr"
    /// is not a title word, so "Dr Pepper" stays raw.
    static func isDoctorName(_ text: String) -> Bool {
        text.firstMatch(of: /\b[Dd]r\.(?!\s*(?i:pepper)\b)/) != nil
            || text.firstMatch(of: /\bDr\s+(?!Pepper\b)\p{Lu}/) != nil
    }

    /// Medical and care words that make a bare title private even with no number (Product: money and body titles are
    /// private in an export, and on a screen alike).
    /// Money words are not here: money masks only with an amount or a sign (Product, 4:22 PM PT: "Rent car" stays
    /// raw). Words that are also food or plain English are out: "blood orange", "hearts of palm", "energy drink",
    /// "sleep tea", "Dr Pepper".
    static let titleWords: Set<String> = TessMemoryScreen.healthWords
        .subtracting(["blood", "heart", "energy", "sleep", "tight", "tip", "pepper", "dr", "kg", "lb", "lbs", "kcal",
                      "calories", "pain", "recovery", "weight", "slept", "sleepy", "drained"])
        .union(["rehab", "physio", "physiotherapy", "therapy", "therapist", "surgery", "doctor", "dentist", "clinic",
                "hospital"])

    /// Whether a recipe's title is private: the one check above.
    public static func isPrivateRecipeTitle(_ title: String, lastWeightKg: Double?) -> Bool {
        title == recipeLabel || isPrivateTitle(title, lastWeightKg: lastWeightKg)
    }

    /// A field that is always private on its class: a workout's notes are a body fact (Product 5:07 PM PT).
    @MainActor
    public static func hidesNotes(of object: ObjectRecord, classes: [SystemCatalog.Key: ClassDef]) -> Bool {
        guard let classDef = object.classDef, let workout = classes[.workout] else { return false }
        return ClassResolver.isSubclass(classDef, of: workout)
    }

    /// The notes line an object page shows: nil when there are none (only spaces is none; Research PM26), "Note kept
    /// private" for a workout's.
    @MainActor
    public static func notesLine(of object: ObjectRecord, in store: ObjectStore,
                                 classes: [SystemCatalog.Key: ClassDef]) -> String?
    {
        guard let notes = store.value("notes", of: object)?.stringValue,
              !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return hidesNotes(of: object, classes: classes) ? keptNoteLabel : notes
    }

    /// Whether a word he typed is one Tess never says back (a secret, a medicine or a body fact), so a line that would
    /// echo it says "that" instead.
    @MainActor
    public static func isPrivateWord(_ text: String, in store: ObjectStore) -> Bool {
        let last = BodyWeight.lastKg(in: store)
        return isPrivateTitle(text, lastWeightKg: last)
    }

    static func isPrivateText(_ text: String, lastWeightKg: Double?) -> Bool {
        !text.isEmpty && (SecretWords.mentions(text) || PrivateFacts.isWalled(text, lastWeightKg: lastWeightKg))
    }
}
