import Foundation

/// The calls each room's places offer, as data (docs/ai/harness/elements.md has the same tables in words). A room's
/// `RoomContent` takes its place's calls from here and fills the items and focus from its own facts, so what Tess may
/// do on a screen is written once.
///
/// Every tool name is either a `TessTools` tool, `open`, or listed in `proposed` (a tool Core still has to add over an
/// action that already exists). A test holds that.
public enum ElementCatalog {
    // MARK: Shell calls (write nothing)

    static let openItem = ElementCall("openItem", .shell, phrases: ["open", "show me", "go to"],
                                      inputs: [CallInput("item", from: .referent)], reaction: .navigate)
    static let openDoor = ElementCall("openDoor", .shell, phrases: ["open", "show me", "go to"],
                                      inputs: [CallInput("door", from: .door)], reaction: .navigate)
    static let showWindow = ElementCall("showWindow", .shell, phrases: ["show", "switch to"],
                                        inputs: [CallInput("window", from: .asked)], reaction: .lines)
    static let goBack = ElementCall("goBack", .shell, phrases: ["back", "go back"], reaction: .navigate)

    // MARK: Things to do (pending, a ghost row with Undo 10 s)

    static let done = ElementCall("completeTask", phrases: ["done", "did it", "finished", "tick", "check off"],
                                  inputs: [CallInput("task", from: .referent)], reaction: .strike, kinds: ["task"])
    static let notNow = ElementCall("rescheduleTask", phrases: ["not now", "later", "move", "push", "tomorrow"],
                                    inputs: [CallInput("task", from: .referent), CallInput("startsAt", from: .asked)],
                                    reaction: .next, kinds: ["task"])
    static let checkItem = ElementCall("checkListItem", phrases: ["done", "got it", "check", "tick"],
                                       inputs: [CallInput("item", from: .referent)], reaction: .strike,
                                       kinds: ["list item"])
    static let addToList = ElementCall("addToList", phrases: ["add", "put"],
                                       inputs: [CallInput("list", from: .referent), CallInput("items", from: .asked)],
                                       reaction: .keystoneTakes, kinds: ["list"])
    static let createNote = ElementCall("createNote", phrases: ["write", "note", "jot"],
                                        inputs: [CallInput("body", from: .asked)], reaction: .keystoneTakes)
    static let createList = ElementCall("createList", phrases: ["list", "new list", "make a list"],
                                        inputs: [CallInput("name", from: .asked)], reaction: .keystoneTakes)
    static let createTask = ElementCall("createTask", phrases: ["remind", "add a task", "to do"],
                                        inputs: [CallInput("title", from: .asked),
                                                 CallInput("startsAt", from: .window, required: false)],
                                        reaction: .keystoneTakes)
    static let pinNote = ElementCall("pinNote", phrases: ["pin", "unpin"],
                                     inputs: [CallInput("note", from: .referent),
                                              CallInput("pinned", from: .asked, required: false)],
                                     reaction: .keystoneTakes, kinds: ["note", "list"])

    /// Lookout
    static let rainAlert = ElementCall("rainAlert", phrases: ["alert", "tell me when", "warn me"],
                                       inputs: [CallInput("on", from: .asked, required: false),
                                                CallInput("leadMinutes", from: .asked, required: false)],
                                       reaction: .tessLine)
    static let planWalk = ElementCall("createTask", phrases: ["walk", "go out"],
                                      inputs: [CallInput("title", from: .asked, required: false),
                                               CallInput("startsAt", from: .window, required: false)],
                                      reaction: .tessLine)

    /// Deck
    static let startWorkout = ElementCall("startWorkout", phrases: ["start", "begin", "let's go"],
                                          inputs: [CallInput("routine", from: .referent)], reaction: .keystoneTakes,
                                          kinds: ["routine"])
    static let logSet = ElementCall("logSet", phrases: ["log", "did", "sets", "reps"],
                                    inputs: [CallInput("exercise", from: .asked), CallInput("weight", from: .asked),
                                             CallInput("reps", from: .asked)], reaction: .keystoneTakes)
    static let restDay = ElementCall("restDay", phrases: ["rest", "skip today", "day off"], reaction: .reform)

    /// Galley
    static let startCooking = ElementCall("startCooking", phrases: ["cook", "start cooking", "make"],
                                          inputs: [CallInput("recipe", from: .referent)], reaction: .keystoneTakes,
                                          kinds: ["recipe"])
    static let cookTogether = ElementCall("cookTogether", phrases: ["cook together", "plan dinner", "tonight"],
                                          inputs: [CallInput("recipes", from: .asked)], reaction: .keystoneTakes)
    static let setServeTime = ElementCall("setServeTime", phrases: ["eat at", "serve at", "dinner at"],
                                          inputs: [CallInput("time", from: .asked)], reaction: .lines)
    static let addGroceries = ElementCall("addGroceries", phrases: ["get", "buy", "need", "out of"],
                                          inputs: [CallInput("lines", from: .asked)], reaction: .keystoneTakes)
    static let startShop = ElementCall("startShop", phrases: ["shopping", "at the store", "shop"],
                                       reaction: .keystoneTakes)
    static let createRecipe = ElementCall("createRecipe", phrases: ["save the recipe", "new recipe"],
                                          inputs: [CallInput("title", from: .asked)], reaction: .keystoneTakes)

    /// Watch
    static let tend = ElementCall("tendRoutine", phrases: ["done", "did it", "water", "tend"],
                                  inputs: [CallInput("routine", from: .referent)], reaction: .strike,
                                  kinds: ["routine"])
    static let plant = ElementCall("plantRoutine", phrases: ["plant", "new habit", "start doing"],
                                   inputs: [CallInput("name", from: .asked),
                                            CallInput("cadence", from: .asked, required: false),
                                            CallInput("weekdays", from: .asked, required: false)],
                                   reaction: .keystoneTakes)
    static let pause = ElementCall("pauseRoutine", phrases: ["pause", "rest", "skip", "resume"],
                                   inputs: [CallInput("routine", from: .referent),
                                            CallInput("days", from: .asked, required: false),
                                            CallInput("resume", from: .asked, required: false)],
                                   reaction: .reform,
                                   kinds: ["routine"])

    // Purse: the phone's own rungs only (money actions are never offered to Claude).
    static let logSpend = ElementCall("logSpend", phrases: ["spent", "paid", "log", "bought"],
                                      inputs: [CallInput("amount", from: .asked), CallInput("note", from: .asked)],
                                      reaction: .keystoneTakes, reach: .deviceOnly)

    // MARK: Reads

    static let query = ElementCall("query", phrases: ["how many", "when did", "what was", "how much"],
                                   inputs: [CallInput("question", from: .asked)], reaction: .tessLine)

    /// Tools named here that `TessTools` does not have yet. Each wraps an engine action that exists.
    /// Added: checkListItem, startWorkout, startCooking, logSpend (device rungs only). Still waiting for an engine
    /// action to wrap: pinNote (no pinned field on a note), rainAlert (a local notification, the app's), restDay (a
    /// read today, not a write), and the Watch trees' tend, plant and pause (no routine-tending action yet).
    public static let proposed: Set<String> = [
        "pinNote", "rainAlert", "restDay", "tendRoutine", "plantRoutine", "pauseRoutine",
    ]

    /// Shell calls: they change what is shown and write nothing.
    public static let shellCalls: Set<String> = ["openItem", "openDoor", "showWindow", "goBack"]

    // MARK: Places, room by room

    /// The same in every room: the switcher, the dial, the nav word, a door page's rows.
    static let shared: [ElementPlace: [ElementCall]] = [
        .switcher: [showWindow],
        .dial: [openDoor],
        .navWord: [goBack],
        .keystone: [openItem],
        .tess: [query],
    ]

    static let rooms: [String: [ElementPlace: [ElementCall]]] = [
        "bridge": [
            .widget: [done, notNow, openItem],
            .page: [done, notNow, openItem],
        ],
        "log": [
            .widget: [checkItem, done, notNow, pinNote, openItem],
            .page: [checkItem, done, notNow, pinNote, openItem],
            .keystone: [openItem, addToList],
            .actionWord: [createNote, createList, createTask],
        ],
        "lookout": [
            .widget: [openItem],
            .actionWord: [rainAlert, planWalk],
        ],
        "deck": [
            .widget: [startWorkout, restDay, openItem],
            .keystone: [openItem, logSet],
            .page: [startWorkout, openItem],
            .actionWord: [startWorkout, logSet, restDay],
        ],
        "galley": [
            .widget: [startCooking, setServeTime, done, openItem],
            .keystone: [openItem, startCooking, addGroceries],
            .page: [startCooking, openItem],
            .actionWord: [startCooking, cookTogether, addGroceries, startShop, done, createRecipe],
        ],
        "watch": [
            .widget: [tend, pause, openItem],
            .keystone: [openItem, tend, pause],
            .page: [tend, pause, openItem],
            .actionWord: [plant, tend, pause],
        ],
        "purse": [
            .widget: [openItem],
            .page: [openItem],
            .actionWord: [logSpend],
        ],
    ]

    /// The calls one place offers in one room: the room's own first, then the shared ones it lacks.
    public static func calls(room: String, place: ElementPlace) -> [ElementCall] {
        var out = rooms[room]?[place] ?? []
        for call in shared[place] ?? [] where !out.contains(where: { $0.name == call.name }) {
            out.append(call)
        }
        return out
    }

    /// Every call any room offers, once each by name.
    public static var everyCall: [ElementCall] {
        var out: [ElementCall] = []
        let lists: [[ElementCall]] = rooms.values.flatMap(\.values) + Array(shared.values)
        for call in lists.flatMap(\.self) where !out.contains(where: { $0.name == call.name }) {
            out.append(call)
        }
        return out
    }
}
