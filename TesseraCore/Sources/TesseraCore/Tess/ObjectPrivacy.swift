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
    /// What a walled list name reads (the same word `ListContents.privateListLabel` carries).
    public static let listLabel = "Private list"

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
        if isA(.listItem) {
            return isPrivateWord(object.title, in: store) ? "Private item" : nil
        }
        if isA(.list) {
            return isPrivateWord(object.title, in: store) ? listLabel : nil
        }
        if isA(.workout) || isA(.routine) {
            return PrivateWords.isPrivateTitle(object.title, lastWeightKg: last) ? routineLabel : nil
        }
        if isA(.recipe) {
            return isPrivateRecipeTitle(object.title, lastWeightKg: last) ? recipeLabel : nil
        }
        return nil
    }

    /// Whether a recipe's title is private (a secret word, money, a body fact or a medicine).
    public static func isPrivateRecipeTitle(_ title: String, lastWeightKg: Double?) -> Bool {
        title == recipeLabel || PrivateFacts.isPrivateTitle(title, lastWeightKg: lastWeightKg)
            || EngineWall.isHealth(title, lastWeightKg: lastWeightKg)
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
        return isPrivateText(text, lastWeightKg: last) || EngineWall.isHealth(text, lastWeightKg: last)
    }

    static func isPrivateText(_ text: String, lastWeightKg: Double?) -> Bool {
        !text.isEmpty && (SecretWords.mentions(text) || PrivateFacts.isWalled(text, lastWeightKg: lastWeightKg))
    }
}
