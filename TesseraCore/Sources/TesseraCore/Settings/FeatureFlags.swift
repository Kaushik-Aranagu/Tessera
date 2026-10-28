import Foundation

/// Where Developer mode files a flag (sheet 203): by app, so it reads as a list of what the app can do.
public enum FeatureGroup: String, CaseIterable, Sendable {
    case home = "Home"
    case training = "Training"
    case kitchen = "Kitchen"
    case notesAndLists = "Notes and lists"
    case tasksAndRoutines = "Tasks and routines"
    case money = "Money"
    case everywhere = "Everywhere"
}

/// One feature that ships On. Developer mode can turn it Off and bring it back; nothing here adds a feature.
public struct FeatureFlag: Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let group: FeatureGroup
    /// The feature sends something to Claude, so it also needs "Tess asks Claude" On: a flag never turns Claude on.
    public let needsClaude: Bool

    init(_ id: String, _ name: String, _ group: FeatureGroup, claude: Bool = false) {
        self.id = id
        self.name = name
        self.group = group
        needsClaude = claude
    }
}

/// Every approved feature flag, all On by default (Kaushik, Oct 23 8:47 AM PT: what he approves, asks for or is
/// recommended ships On, and he asks for what he does not want turned off). Stored as the few he turned Off, so a new
/// flag ships On with no migration. The values are stored on this iPhone only, by the app, never in a backup, the op
/// log or a model. Choices with more than two values, the connections (Calendar, Health) and tools (sample data, the
/// class inspector) are not flags and are not here.
public enum FeatureFlags {
    public static let all: [FeatureFlag] = [
        // Home
        .init("homeV2", "Home v2", .home), .init("homeMosaic", "Mosaic", .home),
        .init("homeMosaicMoods", "Mosaic moods", .home), .init("homeMosaicMoments", "Mosaic moments", .home),
        .init("homeAppsList", "Apps list", .home), .init("daySentence", "Day sentence", .home),
        .init("quietHoursV2", "Quiet hours", .home),
        .init("routineMode", "Routine mode", .home),
        .init("awayV2", "Away", .home), .init("finishMoments", "Finish moments", .home),
        .init("finishV2", "Finishing marks", .home), .init("surfacesV2", "Surfaces v2", .home),
        // Training
        .init("restTimer", "Rest timer", .training), .init("finishNudge", "Forgot Finish nudge", .training),
        .init("trainingAutoName", "Tess names training days", .training, claude: true),
        .init("trainingStats", "Stats", .training), .init("trainingLog", "Log", .training),
        .init("statsBalance", "Balance words", .training), .init("trainingLightWeeks", "Lighter weeks", .training),
        .init("liveV2", "Live workout v2", .training), .init("caloriesBurned", "Calories burned", .training),
        // Kitchen
        .init("cookTimerVoice", "Cook timer voice", .kitchen), .init("handsFreeCook", "Hands-free cook mode", .kitchen),
        .init("pantryState", "Pantry state", .kitchen), .init("canCookShelf", "Can cook shelf", .kitchen),
        .init("weekStrip", "Week strip", .kitchen), .init("cookDouble", "Cook double", .kitchen),
        .init("parallelSteps", "Parallel steps", .kitchen), .init("cookNotes", "Cook notes on the recipe", .kitchen),
        .init("fixRecipe", "Fix a recipe", .kitchen), .init("usuallyLine", "Usually line", .kitchen),
        .init("aisleOrder", "Learned aisle order", .kitchen),
        .init("pantryLevelsV2", "Pantry levels", .kitchen), .init("shopV2", "Shop run", .kitchen),
        .init("linkFetch", "Link reader v2", .kitchen, claude: true),
        .init("kitchenRoomsV2", "Kitchen rooms", .kitchen),
        .init("galleyCookMode", "Cooking mode", .kitchen),
        .init("galleyShopMode", "Shopping mode", .kitchen),
        // Notes and lists
        .init("notesMargin", "Notes margin", .notesAndLists), .init(
            "notesLinkSuggest",
            "Link suggestions",
            .notesAndLists
        ),
        .init("listsMargin", "Lists margin", .notesAndLists), .init(
            "listsLeadByDue",
            "Lead list by due date",
            .notesAndLists
        ),
        .init("twinsV2", "Twins", .notesAndLists), .init("makeAKind", "Make a kind", .notesAndLists),
        .init("writeAnywhere", "Write anywhere", .notesAndLists), .init("linkColours", "Link colours", .notesAndLists),
        .init("askPageV2", "Ask the page", .notesAndLists),
        // Tasks and routines
        .init("tasksApp", "Tasks app", .tasksAndRoutines), .init("landingPages", "Landing pages", .tasksAndRoutines),
        .init("routinesDayV2", "Routines day", .tasksAndRoutines), .init(
            "weekThreadV2",
            "Week thread",
            .tasksAndRoutines
        ),
        .init("repeatItems", "Repeat items", .tasksAndRoutines), .init("occasions", "Occasions", .tasksAndRoutines),
        .init("oneHands", "One pair of hands", .tasksAndRoutines),
        .init("quietInterrupts", "Quiet interrupts", .tasksAndRoutines),
        .init("planMyDay", "Plan my day, Claude wording", .tasksAndRoutines, claude: true),
        .init("shutdown", "Shutdown", .tasksAndRoutines, claude: true),
        .init("energyCheckIn", "Energy check-in", .tasksAndRoutines, claude: true),
        // Money
        .init("moneyPools", "Money pools", .money),
        // Everywhere
        .init("numberRules", "Number rules", .everywhere), .init("roomMotion", "Room motion", .everywhere),
        .init("pagesV2", "Pages v2", .everywhere), .init("settingsV2", "Settings v2", .everywhere),
        .init("walledPageV2", "Privacy page", .everywhere), .init("backupsV2", "Backups in words", .everywhere),
        .init("undoLogV2", "Undo log", .everywhere),
        .init("depthOnWheels", "Depth on wheels", .everywhere),
        .init("tessLabPolicy", "Lab mode for Claude", .everywhere, claude: true),
        .init("tessDirectorPlaybook", "Tess picks her looks", .everywhere, claude: true),
        .init("tessAsks", "Ask Tess anything", .everywhere, claude: true),
        // The Chart room: the experimental room Tess builds by talking (R1).
        .init("chartRoom", "Chart room", .everywhere),
    ]

    /// Not flags: switches with more than two values, connections he makes by hand, and tools. A test keeps this list
    /// and `all` equal to the app's ReviewChoices, so a new switch cannot be forgotten.
    public static let notFlags: Set<String> = [
        "readingLayout", "swapExercise", "lockScreenLook", "pageTurn", "tessFace", "areasShown", "font", "calendar",
        "health", "sampleData", "classInspector",
    ]

    public static func flag(_ id: String) -> FeatureFlag? {
        all.first { $0.id == id }
    }

    /// A flag is On unless he turned it Off. A flag that needs Claude is also Off while "Tess asks Claude" is Off.
    /// An id that is not a flag reads Off.
    public static func isOn(_ id: String, off: Set<String>, asksClaude: Bool) -> Bool {
        guard let flag = flag(id) else { return false }
        return !off.contains(id) && (!flag.needsClaude || asksClaude)
    }

    /// Developer mode's list: every flag by app, each with whether it is On (a flag held back only by Claude still
    /// shows
    /// its own state).
    public static func developerGroups(off: Set<String>) -> [(
        group: FeatureGroup,
        flags: [(flag: FeatureFlag, isOn: Bool)]
    )] {
        FeatureGroup.allCases.compactMap { group in
            let flags = all.filter { $0.group == group }.map { (flag: $0, isOn: !off.contains($0.id)) }
            return flags.isEmpty ? nil : (group: group, flags: flags)
        }
    }

    /// Turns one flag Off or back On. Ids that are not flags change nothing.
    public static func setting(_ id: String, on: Bool, off: Set<String>) -> Set<String> {
        guard flag(id) != nil else { return off }
        var next = off
        if on {
            next.remove(id)
        } else {
            next.insert(id)
        }
        return next
    }

    /// "homeV2;pagesV2": the one text field the app stores. Sorted, so it never changes without a change.
    public static func encoded(off: Set<String>) -> String? {
        let known = off.filter { flag($0) != nil }
        return known.isEmpty ? nil : known.sorted().joined(separator: ";")
    }

    /// Reads it back, dropping anything that is not a flag any more.
    public static func off(encoded: String?) -> Set<String> {
        Set((encoded ?? "").split(separator: ";").map(String.init).filter { flag($0) != nil })
    }
}
