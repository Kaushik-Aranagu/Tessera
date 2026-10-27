import Foundation

/// What may go to Claude. Kaushik, Oct 27 11:59 AM PT: "I don't want any privacy-related restrictions on what Claude
/// can [see] ... calories or weight or money or everything ... don't filter or mask any of them." So everything goes
/// as it is: money, health, body, calories, calendar, secret words and private things, unmasked. Only the Claude key,
/// or text shaped like one, stays on the phone.
///
/// This is about what leaves for Claude, nothing else: what this phone's screens, widgets, backups and logs keep
/// private is unchanged, and prompt-steering text keeps its own guard (`PromptSteering`), which is about safety.
/// The harness has its own switch for the same thing (`DoorPolicy`: lab, which ships On).
public enum ClaudeSees {
    /// On. A test runs the old walls with `ClaudeSees.$everything.withValue(false) { ... }`.
    @TaskLocal public static var everything = true

    /// Money changes too (his pick on the card, Oct 27 12:28 PM PT, "Claude can write money too"): a money call is
    /// offered to Claude like any other and lands pending, as a ghost row with Undo. Off, money calls stay on the
    /// phone's own rungs, as before.
    @TaskLocal public static var moneyWrites = true

    /// Whether a call marked for the phone only (a money call) is still kept off Claude.
    public static func keepsOnPhone(_ deviceOnly: Bool) -> Bool {
        deviceOnly && !moneyWrites
    }

    /// Whether text must not go to Claude: a key always; `walled`, the old wall, only with `everything` off.
    public static func blocks(_ text: String, walled: @autoclosure () -> Bool) -> Bool {
        looksLikeClaudeKey(text) || (!everything && walled())
    }

    /// The label a private thing goes to Claude as: none while Claude sees everything (it goes by its own title),
    /// its shown label (`ObjectPrivacy.shownLabel`) otherwise, or when `strict` (the harness's strict policy).
    @MainActor
    public static func label(of object: ObjectRecord, in store: ObjectStore, classes: [SystemCatalog.Key: ClassDef],
                             strict: Bool = false) -> String?
    {
        everything && !strict ? nil : ObjectPrivacy.shownLabel(of: object, in: store, classes: classes)
    }
}
