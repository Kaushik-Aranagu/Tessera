import Foundation

/// What each system class is allowed to be: the one answer for the walls that used to be six lists (docs/design
/// element-template-288.md section 6). A new `SystemCatalog.Key` does not compile until it is answered here, and the
/// lists the walls read (`PrivateWords.mirrorClassKeys`, `localOnlyClassKeys`, `TessAskRouter.isUnnameable`,
/// `MemoryScope.neverRead`) are computed from this table, so they cannot drift apart again.
///
/// - `labeled`: an object of the class can read private, and `ObjectPrivacy` gives it a label (the rule itself stays in
///   `ObjectPrivacy.label`; the conformance test checks one exists).
/// - `unnameable`: never named to Claude, in an opener, a line or a query (money, health, body, calendar, her own
///   bookkeeping).
/// - `neverRead`: in no agent's memory slice, whatever the policy.
/// - `mirror`: read again from its source (EventKit, Health) or kept only on this phone; never in an op, a copy, an
///   export or the iCloud copy.
/// - `localOnly`: not in the iCloud copy or the export (a mirror is local only too).
@MainActor
public enum ClassPolicy {
    public struct Entry: Equatable, Sendable {
        public var labeled = false
        public var unnameable = false
        public var neverRead = false
        /// In no slice under strict (the calendar and Health mirrors, held notices); lab may read them. `neverRead` is
        /// the stronger answer: no slice at all.
        public var strictNever = false
        public var mirror = false
        public var localOnly = false

        static let plain = Entry()
        static let labeled = Entry(labeled: true)
        /// Money: named to no one, private by its nature.
        static let money = Entry(labeled: true, unnameable: true)
        /// Calendar and Health mirrors, held notices and her conversation: this phone only, in no copy at all.
        static let mirror = Entry(unnameable: true, neverRead: true, mirror: true, localOnly: true)
        /// A mirror of the calendar or Health: this phone only, in no strict slice, readable under lab (Claude sees
        /// anything there). Her own conversation and sent rows are `.mirror`, never read at all.
        static let sourceMirror = Entry(unnameable: true, strictNever: true, mirror: true, localOnly: true)
        /// Her bookkeeping that is not a mirror but stays on this phone: calls, sent rows, waiting phrases.
        static let bookkeeping = Entry(unnameable: true, neverRead: true, localOnly: true)
        /// The system's own state: in no slice and named to no one.
        static let internalState = Entry(unnameable: true, neverRead: true)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    public static func of(_ key: SystemCatalog.Key) -> Entry {
        switch key {
        case .thing, .activity, .exercise, .strengthExercise, .barbellLift, .benchPress, .muscle, .equipment,
             .exerciseEntry, .set, .slot, .plan, .list, .listItem, .recipeLine, .recipeStep, .cook, .kitchenTimer,
             .process, .occasion, .routineRun, .rest:
            // Lists and their items read private through the shown-label rule (a private list, a private item).
            key == .list || key == .listItem ? .labeled : .plain
        case .workout, .routine, .note, .task, .recipe, .ingredient, .cookSession, .cookDish, .place, .book:
            .labeled
        case .spend, .pool, .inflow, .poolMove, .rateNote:
            .money
        case .meProfile:
            Entry(labeled: true, unnameable: true, neverRead: true)
        case .belief:
            Entry(labeled: true, unnameable: true)
        case .tessMemory:
            Entry(labeled: true, unnameable: true, neverRead: true)
        case .settings, .tessAgent:
            .internalState
        case .closedDay:
            // In no slice, but nameable: the Day log and Home read closed days by name. Not tightened.
            Entry(neverRead: true)
        case .notebookPage, .agentEpisode:
            Entry(labeled: true, unnameable: true, neverRead: true, mirror: true, localOnly: true)
        case .event, .sleepNight, .stepsDay, .restingHeartRate:
            .sourceMirror
        case .heldNotice:
            Entry(unnameable: true, neverRead: true, strictNever: true, mirror: true, localOnly: true)
        case .tessSentExact, .tessTurn:
            .mirror
        case .tessCall, .tessSent, .tessWaiting:
            .bookkeeping
        }
    }

    // MARK: The lists the walls read, derived

    static func keys(where test: (Entry) -> Bool) -> Set<SystemCatalog.Key> {
        Set(SystemCatalog.Key.allCases.filter { test(of($0)) })
    }

    public static let unnameableKeys: Set<SystemCatalog.Key> = keys { $0.unnameable }
    public static let neverReadKeys: Set<SystemCatalog.Key> = keys { $0.neverRead }
    public static let strictNeverKeys: Set<SystemCatalog.Key> = keys { $0.strictNever || $0.neverRead }
    public static let mirrorKeys: Set<SystemCatalog.Key> = keys { $0.mirror }
    public static let localOnlyKeys: Set<SystemCatalog.Key> = keys { $0.localOnly || $0.mirror }
}
