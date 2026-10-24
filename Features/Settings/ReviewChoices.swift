import Foundation
import Observation
import TesseraCore

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
        // Together (sheet 135): the apps remember each other, one switch per piece.
        Choice(id: "daySentence", name: "Day sentence", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Today leads with its one big line.",
                      "On": "Today reads as one paragraph across your apps, each key word in its app's colour."],
               readiness: .live),
        Choice(id: "linkColours",
               name: "Link colours",
               values: ["Off", "On"],
               defaultValue: "Off",
               says: ["Off": "@ words are blue, as now.",
                      "On": "@ words are underlined in their own app's colour, and a page says where else it comes up."],
               readiness: .live),
        Choice(id: "writeAnywhere", name: "Write anywhere", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Home's write line keeps to tasks and logs, as now.",
                      "On": "Write anything on Home and it goes to the right app, with Undo."],
               readiness: .live),
        // Sheet 139: a finished list, task and day each write a result in words.
        Choice(id: "finishMoments",
               name: "Finish moments",
               values: ["Off", "On"],
               defaultValue: "Off",
               says: ["Off": "A finished list, task or day just stays as it is.",
                      "On": "A finished list says so in words, Home counts tasks done today, and a past day reads as a sentence."],
               readiness: .live),
        Choice(id: "oneHands", name: "One pair of hands", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "As now.", "On": "When two things need you at once, Tess offers one fix."],
               readiness: .arrivesWith("its Core facts")),
        Choice(id: "occasions", name: "Occasions", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "As now.", "On": "A trip or a dinner gets one page, with a piece from every app."],
               readiness: .arrivesWith("its Core facts")),
        Choice(id: "makeAKind", name: "Make a kind", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "As now.",
                      "On": "Notes offers to make something you keep writing about into its own kind."],
               readiness: .arrivesWith("its Core facts")),
        Choice(id: "moneyPools",
               name: "Money pools",
               values: ["Off", "On"],
               defaultValue: "Off",
               says: ["Off": "Money is spends only, as now.",
                      "On": "Tell Tess what came in and where it went: \"got 3200 paycheck\", \"moved 1000 to India\"."],
               readiness: .live),
        Choice(id: "awayV2", name: "Away", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Home is the same on a trip.",
                      "On": "Mark a trip away and Home shows only that trip on its days."],
               readiness: .live),
        // Sheet 199: Home as a sentence, a picture of the day and three rows. Off leaves Home as it is.
        Choice(id: "homeMosaic",
               name: "Mosaic",
               values: ["Off", "On"],
               defaultValue: "Off",
               says: ["Off": "Home is as it is now.",
                      "On": "Home is three lines about your day, a mosaic of it, and what's next. It wins over Home v2 when both are On."],
               readiness: .live),
        Choice(id: "homeMosaicMoments",
               name: "Mosaic moments",
               values: ["Off", "On"],
               defaultValue: "Off",
               says: ["Off": "The mosaic keeps to its mood.",
                      "On": "Now and then the mosaic shows snow, a word about what is next, Tess, or a finished tile. Needs Mosaic moods."],
               readiness: .live),
        Choice(id: "homeAppsList", name: "Apps list", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "No apps list under Next.", "On": "Your apps list under Next on the Mosaic Home."],
               readiness: .live),
        // Sheet 200: the three lines as a departure board. Needs Mosaic On.
        Choice(id: "homeMosaicMoods", name: "Mosaic moods", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "The three lines change at once.",
                      "On": "When the day turns, each letter clicks forward to its new word. Needs Mosaic On."],
               readiness: .live),
        Choice(id: "homeV2", name: "Home v2", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Home pages sideways: Review, Today, Training.",
                      "On": "One Home page, with your apps as thin lines along the bottom."],
               readiness: .live),
        Choice(id: "tasksApp", name: "Tasks app", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Tasks live on Home and in lists, as now.",
                      "On": "Tasks is an app of its own: one thing at a time, with Today, Soon and Later."],
               readiness: .live),
        Choice(id: "landingPages", name: "Landing pages", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Each app opens on its list of ways in.",
                      "On": "Each app opens on a page that tells you where things stand."],
               readiness: .live),
        // Notes and Lists landings (notes-lists-landing-build-sheet-oct22.md section 5): the pages ride "Landing
        // pages";
        // these are the sheet's own opinions, default Off.
        Choice(id: "notesMargin", name: "Notes margin", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "The Notes landing has no Waiting or New lines.",
                      "On": "The Notes landing says what is waiting and what is new."],
               readiness: .live),
        Choice(id: "notesLinkSuggest", name: "Link suggestions", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "A note that names a thing in words stays as written.",
                      "On": "The Notes landing offers to link a note that names a thing."],
               readiness: .live),
        Choice(id: "listsMargin", name: "Lists margin", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "The Lists landing has no Waiting or New lines.",
                      "On": "The Lists landing says what is done and what is new."],
               readiness: .live),
        Choice(id: "listsLeadByDue", name: "Lead list by due date", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "The running list, else the one touched last, leads.",
                      "On": "With nothing running, the list due soonest leads."],
               readiness: .live),
        // Training Stats (Product build sheet, Oct 22): a page of numbers behind the Training landing's Stats door.
        Choice(id: "trainingStats", name: "Stats", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Training has no Stats page.",
                      "On": "Training gets a Stats door: your best, your lifts, your sets, your weeks."],
               readiness: .live),
        Choice(id: "trainingLog", name: "Log", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "The Log door opens the list of workouts as before.",
                      "On": "The Log door opens your sessions by month."],
               readiness: .live),
        Choice(id: "statsBalance", name: "Balance words", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Stats says nothing about push, pull, upper and lower.",
                      "On": "Stats adds a few words on how your sets are shared."],
               readiness: .live),
        Choice(id: "trainingLightWeeks", name: "Lighter weeks", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "A week is just a week.",
                      "On": "A week with fewer sets than usual says so, once, when you tap it."],
               readiness: .live),
        // Design 138: one shared number view for every app.
        Choice(id: "numberRules",
               name: "Number rules",
               values: ["Off", "On"],
               defaultValue: "Off",
               says: ["Off": "Numbers are drawn as before.",
                      "On": "Fractions hang small, an estimate is lighter than an exact value, and the unit stays with its number."],
               readiness: .live),
        // Design 138: the shared room motions (word to title, receipts, paper sheets, room shift).
        Choice(id: "roomMotion", name: "Room motion", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Pages and receipts move as before.",
                      "On": "A word grows into its page's title, receipts travel and dry, and rooms shift tint."],
               readiness: .live),
        // Design 150: the finished workout's page, one sentence and its marks.
        Choice(id: "pagesV2", name: "Pages v2", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "A finished workout's page is as before.",
                      "On": "A finished workout's page is one sentence, its set marks and its numbers."],
               readiness: .live),
        // Design 154: Settings in sentence case, a line under the title, value words in ink 2.
        Choice(id: "settingsV2", name: "Settings v2", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Settings reads as it does now.",
                      "On": "Settings opens with a line under its title, in sentence case, with values in grey."],
               readiness: .live),
        // Design round 2 and 3 (137, 139, 142, 153): each piece behind its own switch, all default Off.
        Choice(id: "finishV2", name: "Finishing marks", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Finishing a session, a cook or a routine ends as before.",
                      "On": "Finishing gathers its marks and says one line."],
               readiness: .live),
        Choice(id: "surfacesV2", name: "Surfaces v2", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Widgets, the Lock Screen and Live Activities look as before.",
                      "On": "Widgets, the Lock Screen and Live Activities use today's look."],
               readiness: .live),
        Choice(id: "liveV2", name: "Live workout v2", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "The live workout looks as before.",
                      "On": "The live workout is sentence case with one hot action."],
               readiness: .live),
        // Design 166: press a page's title and Tess answers one question about it, from Describe, on the phone only.
        Choice(id: "askPageV2", name: "Ask the page", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "A page's title does nothing when pressed.",
                      "On": "Press a page's title and Tess says what it is and what changed, on this phone only."],
               readiness: .live),
        Choice(id: "routinesDayV2", name: "Routines day", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "The Routines landing's top reads as before.",
                      "On": "The Routines landing's top is one plain sentence about the day."],
               readiness: .live),
        Choice(id: "weekThreadV2", name: "Week thread", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "The Routines landing shows no week line.",
                      "On": "The Routines week is a rose thread, solid where a routine ran and a gap where not."],
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
        // Together round 13 (sheet 183): a quiet offer on Today to join two things that look the same.
        Choice(id: "twinsV2", name: "Twins", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Two things that look the same stay as they are.",
                      "On": "Today offers once to join two things that look the same, with UNDO."],
               readiness: .live),
        // Together round 9, 10 and 12 (164, 169, 179): each its own switch, default Off.
        Choice(id: "walledPageV2", name: "Privacy page", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Settings has no Privacy page.",
                      "On": "Settings gets a Privacy word: what stays on this phone, in counts, never names."],
               readiness: .live),
        Choice(id: "backupsV2", name: "Backups in words", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Backups reads as before.",
                      "On": "Backups says the last copy and its count, shows what a restore changes first, with Undo."],
               readiness: .live),
        // Sheet 167: Settings > Quiet hours, On by default.
        Choice(id: "quietHoursV2", name: "Quiet hours", values: ["On", "Off"], defaultValue: "On",
               says: ["On": "Settings has a Quiet hours line: drag the two ends of the day to say when notices wait.",
                      "Off": "No Quiet hours line; quiet stays 11 pm to 7 am."],
               readiness: .live),
        Choice(id: "undoLogV2", name: "Undo log", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Undo stays on the line Tess says after a change.",
                      "On": "Today ends with the last change and Undo for 10 minutes; Review lists recent changes."],
               readiness: .live),
        // Design 161 and 155: Pantry's levels and the shop run, each its own switch, default Off.
        Choice(id: "pantryLevelsV2", name: "Pantry levels", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "Pantry places list their things; the count sits by the Pantry word.",
                      "On": "Each place shows a level line, and what's to get sits after the places."],
               readiness: .live),
        Choice(id: "shopV2", name: "Shop run", values: ["Off", "On"], defaultValue: "Off",
               says: ["Off": "The shop shows the aisle and its items.",
                      "On": "The next item leads; swipe right to strike it; Done shopping puts it all away."],
               readiness: .live),
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
        ("Shown", ["sampleData", "landingPages", "homeV2", "areasShown", "classInspector", "tasksApp"]),
        ("Notes and lists", ["notesMargin", "notesLinkSuggest", "listsMargin", "listsLeadByDue", "twinsV2"]),
        ("Money", ["moneyPools"]),
        ("Together", ["daySentence", "linkColours", "writeAnywhere", "oneHands", "occasions", "makeAKind"]),
        ("Training stats", ["trainingStats", "trainingLog", "statsBalance", "trainingLightWeeks"]),
        // Design 138, 150 and later rounds: the shared numbers, room motion and the redrawn pages.
        ("Rooms", ["numberRules", "roomMotion", "pagesV2", "askPageV2", "finishMoments", "settingsV2"]),
        ("Home and live", ["finishV2", "surfacesV2", "liveV2", "routinesDayV2", "weekThreadV2", "awayV2"]),
        // Kitchen is full at six, so Pantry levels and the shop run get their own page.
        ("Kitchen v2", ["pantryLevelsV2", "shopV2"]),
        ("Safe keeping", ["walledPageV2", "backupsV2", "undoLogV2"]),
        ("Time", ["quietHoursV2"]),
        ("Home mosaic", ["homeMosaic", "homeMosaicMoods", "homeMosaicMoments", "homeAppsList"]),
    ]

    /// The facet pages with their rows, in the facets' order; a row no facet names goes on a last "More" page.
    /// The pages Settings draws: only rows whose feature ships in this build (Product, Oct 20; sheet 110). A waiting
    /// row is not drawn at all, and a tab with nothing live goes with it.
    nonisolated static func drawnPages(_ choices: [Choice] = all) -> [(word: String, rows: [Choice])] {
        // Sample data is simulator-only: the switch is never offered on a device, whichever page draws the rows.
        facetPages(choices.filter { $0.readiness == .live && ($0.id != "sampleData" || LaunchFlags.allowed) })
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
    /// Whether the approved feature flags (stored as the few turned Off) are in force. A unit-test host keeps the older
    /// per-switch behaviour so tests of it do not drift; the flag tests ask for the real thing.
    private let usesFlags: Bool
    private var picked: [String: String] = [:]

    init(defaults: UserDefaults = .standard, writes: Bool = !LaunchFlags.has("-demo"),
         usesFlags: Bool = FeatureFlagStore.usesFlags)
    {
        self.usesFlags = usesFlags
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
        // An approved feature flag ships On and is stored as the few he turned Off (sheet 203).
        if writes, usesFlags, let on = FeatureFlagStore.isOn(choice.id, defaults: defaults) {
            return on ? "On" : "Off"
        }
        if writes, let kept = defaults.string(forKey: Self.key(choice.id)), choice.values.contains(kept) {
            return kept
        }
        return choice.defaultValue
    }

    /// What a choice reads as shipped: a feature flag is On (the Home v2 layout is the one Off, Mosaic wins), else
    /// today's default.
    func shippedValue(of choice: Choice) -> String {
        guard usesFlags, FeatureFlagStore.isFlag(choice.id) else { return choice.defaultValue }
        return FeatureFlagStore.shippedOff.contains(choice.id) ? "Off" : "On"
    }

    /// Whether a choice is off what shipped. A switch that isn't live yet reads its own default and is never "off".
    func isTrying(_ choice: Choice) -> Bool {
        choice.readiness == .live && value(of: choice) != shippedValue(of: choice)
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
        // Surfaces v2: the widgets cannot read this store, so the flag is mirrored to the App Group (Off clears it).
        if choice.id == SurfacesV2.choiceID, writes {
            SurfacesV2.mirrorFlag(SurfacesV2.isOn(value: value))
        }
        guard writes else { return }
        if usesFlags, FeatureFlagStore.isFlag(choice.id) {
            FeatureFlagStore.set(choice.id, on: value == "On", defaults: defaults)
            return
        }
        if value == choice.defaultValue {
            defaults.removeObject(forKey: Self.key(choice.id))
        } else {
            defaults.set(value, forKey: Self.key(choice.id))
        }
    }

    /// Every switch back to today's behavior ("Everything as before").
    func resetAll(_ choices: [Choice] = ReviewChoices.all) {
        // Only switches that are live: a flag whose feature isn't here yet must stay as shipped (On) for when it is.
        for choice in choices where choice.readiness == .live {
            set(choice, to: shippedValue(of: choice))
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
