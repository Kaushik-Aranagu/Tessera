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
    public static let mealLabel = "Private meal"
    /// A recipe has no flag on master; the title rule decides (kitchen-week-one-private-filter PF4, gap hunt G21).
    public static let recipeLabel = "Private recipe"
    /// What a spend reads everywhere but its own page and the Month page (Money amendment 2).
    public static let spendLabel = "Private spend"
    public static let profileLabel = "Private profile"
    /// A multi-dish cook with a private dish in it (the session holds no names; this stops its title and fields).
    public static let cookLabel = "Private cook"
    /// Money pools: a pool, an inflow, a move between pools and a noted rate carry names, amounts, balances and rates,
    /// so each reads private everywhere but its own page, like a spend (Money pools B2).
    public static let poolLabel = "Private pool"
    public static let inflowLabel = "Private inflow"
    public static let moveLabel = "Private move"
    public static let rateLabel = "Private rate"
    public static let placeLabel = "Private place"
    /// What a private book reads wherever it is masked; its review shows on the book page only (Reading amendment 2).
    public static let bookLabel = "Private book"
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
        if isA(.leftover) || isA(.mealEntry) {
            return flagged || isPrivateText(object.title) ? mealLabel : nil
        }
        if isA(.tessMemory) {
            let rule = store.value("rule", of: object)?.stringValue ?? ""
            return flagged || isPrivateText(object.title) || isPrivateText(rule) ? memoryLabel : nil
        }
        if isA(.task) {
            // The one shared title check (G105): title words and "Dr Name" count for a task as for a routine or recipe.
            return object.title == taskLabel || isPrivateTitle(object.title, lastWeightKg: last) ? taskLabel : nil
        }
        if isA(.recipe) {
            return isPrivateRecipeTitle(object.title, lastWeightKg: last) ? recipeLabel : nil
        }
        // An ingredient masks on the one check, like the item it becomes on Groceries (G103, G105). Items and lists
        // are #895's branches.
        if isA(.ingredient) {
            return isPrivateRecipeTitle(object.title, lastWeightKg: last) ? "Private item" : nil
        }
        // A spend always carries an amount, so outside its own page and the Month page it is always private
        // (Money amendment 2).
        if isA(.spend) {
            return spendLabel
        }
        // A place named with a walled word reads "Private place".
        if isA(.place) {
            return isPrivateTitle(object.title, lastWeightKg: last) ? placeLabel : nil
        }
        // A dish of a multi-dish cook is private when its recipe or cook is, even if the recipe was plain when the dish
        // was made: it is read live, so retitling the recipe masks the dish (and its stored title) at once.
        if isA(.cookDish) {
            let recipe = store.linkedObjects("recipe", of: object).first
            let cook = store.linkedObjects("cook", of: object).first
            let hidden = (recipe.map { isPrivateRecipeTitle($0.title, lastWeightKg: last) } ?? false)
                || (cook.map { isPrivateCook($0, in: store) } ?? false)
            return hidden ? recipeLabel : nil
        }
        if isA(.cookSession) {
            let dishes = store.linkedObjects("dishes", of: object).filter { !$0.isDeleted }
            return dishes.contains(where: { label(of: $0, in: store, classes: classes) != nil }) ? cookLabel : nil
        }
        if isA(.pool) {
            return poolLabel
        }
        if isA(.inflow) {
            return inflowLabel
        }
        if isA(.poolMove) {
            return moveLabel
        }
        if isA(.rateNote) {
            return rateLabel
        }
        // Height, birth year and sex are body facts: private like a weigh-in.
        if isA(.meProfile) {
            return profileLabel
        }
        // A private book (flagged by him): bare words never mask, so a title alone does not make a book private.
        if isA(.book) {
            return flagged ? bookLabel : nil
        }
        // A workout or routine (OL01): its own title, its flag, or the routine a workout was made from.
        // The `flagged` branch is unused here for now: Workout and Routine declare no isPrivate field. Privacy is by words,
        // through the title and the routine link (decided Oct 22).
        if isA(.routine) || isA(.workout) {
            let routine = isA(.workout) ? store.linkedObjects("routine", of: object).first : nil
            let titles = [object.title] + (routine.map { [$0.title] } ?? [])
            return flagged || titles.contains(where: {
                $0 == routineLabel || PrivateWords.isPrivateTitle($0, lastWeightKg: last)
            }) ? routineLabel : nil
        }
        return nil
    }

    /// The one private-text function for an object (OL05): what any screen, row, handle, export or index prints in
    /// place of its title, or nil when it is plain. Core's own rules (note, memory, task, recipe, ingredient, workout,
    /// routine), then what the export has always masked (a child of a private object, an object carrying a private
    /// title, an ingredient only private things use, any object with a walled text value), then a private list or
    /// item. The page, the export and the index all call this, so a thing reads private everywhere or nowhere.
    @MainActor
    public static func shownLabel(of object: ObjectRecord, in store: ObjectStore,
                                  classes: [SystemCatalog.Key: ClassDef]) -> String?
    {
        if let core = label(of: object, in: store, classes: classes) {
            return core
        }
        if let wide = PrivateWords.labels(in: store.context)[object.id] {
            return wide
        }
        guard let classDef = object.classDef else { return nil }
        func isA(_ key: SystemCatalog.Key) -> Bool {
            classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
        }
        guard isPrivateRecipeTitle(object.title, lastWeightKg: BodyWeight.lastKg(in: store)) else { return nil }
        if isA(.listItem) {
            return "Private item"
        }
        return isA(.list) ? "Private list" : nil
    }

    /// The one check for a title or a word he typed (G105): a secret word, money, a body fact, a medicine, a doctor's
    /// name ("Dr Lin", "dr lin"), or one of the money and health title words ("therapy", "clinic", "rent"; not
    /// "dentist" or "physio", which stay plain, decisions Oct 16). Receipts, UNDO, Tess lines, screens and the shared
    /// export all ask this, so a thing reads private everywhere or nowhere ("Lexapro cake" is "Private recipe" on a
    /// screen and in a file alike).
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

    /// "Dr. Patel", "Dr Patel" and "dr lin": a "dr" with a stop, or followed by any name other than Pepper. A bare "dr"
    /// is not a title word, so "Dr Pepper" stays raw.
    static func isDoctorName(_ text: String) -> Bool {
        text.firstMatch(of: /\b[Dd]r\.(?!\s*(?i:pepper)\b)/) != nil
            // He dictates by voice and gets lowercase: "dr lin" walls like "Dr Lin". Unsure walls (Product Oct 19).
            || text.firstMatch(of: /\b[Dd][Rr]\s+(?!(?i:pepper)\b)\p{L}/) != nil
    }

    /// Medical and care words that make a bare title private even with no number (Product: money and body titles are
    /// private in an export, and on a screen alike).
    /// Money words are not here: money masks only with an amount or a sign (Product, 4:22 PM PT: "Rent car" stays
    /// raw). Words that are also food or plain English are out: "blood orange", "hearts of palm", "energy drink",
    /// "sleep tea", "Dr Pepper".
    static let titleWords: Set<String> = TessMemoryScreen.healthWords
        .subtracting(["blood", "heart", "energy", "sleep", "tight", "tip", "pepper", "dr", "kg", "lb", "lbs", "kcal",
                      "calories", "pain", "recovery", "weight", "slept", "sleepy", "drained"])
        .union(["rehab", "physiotherapy", "therapy", "therapist", "surgery", "doctor", "clinic",
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

    /// Whether any word in a phrase is one Tess never says back. Words split on anything that is not a letter or a
    /// digit, so "ozempic," and "ozempic-run" are caught; the whole phrase is checked too.
    @MainActor
    public static func containsPrivateWord(_ text: String, in store: ObjectStore) -> Bool {
        isPrivateWord(text, in: store)
            || text.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).contains {
                isPrivateWord(String($0), in: store)
            }
    }

    static func isPrivateText(_ text: String, lastWeightKg: Double?) -> Bool {
        !text.isEmpty && (SecretWords.mentions(text) || PrivateFacts.isWalled(text, lastWeightKg: lastWeightKg))
    }
}
