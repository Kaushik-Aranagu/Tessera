import Foundation
import TesseraCore

/// What the Routines landing says (248 v2, landing contract): the woodland's plants, the state line forms (longest
/// first, for `FitLine`), the caption under the scene, the two update rows and the doors' facts. Read from
/// `RoutinesFront`, which already masks private routines as "Private routine".
struct RoutinesWoodlandFacts {
    /// One update row in the brief: the routine and its sentence, with the name set apart (600).
    struct Update: Equatable, Identifiable {
        enum Kind: Equatable { case next, care }
        let id: UUID
        let kind: Kind
        let name: String
        /// The words after the name: " is next, around 5:30 pm".
        let rest: String

        var text: String {
            name + rest
        }
    }

    /// One door's facts beside the dial focus.
    struct Door: Equatable, Identifiable {
        let id: String
        let name: String
        let count: Int
        let lines: [String]
    }

    let trees: [WoodlandTree]
    let stateLine: [String]
    let updates: [Update]
    let doors: [Door]

    static let doorNames: [(id: String, name: String)] = [
        ("today", "Today"), ("body", "Body"), ("mind", "Mind"), ("home", "Home"), ("fruit", "Fruit"),
        ("lake", "Across the lake"),
    ]

    @MainActor
    init(front: RoutinesFront, notNow: Set<UUID> = [], calendar: Calendar = .current) {
        let today = TesseraDay(calendar: calendar).today(front.now)
        let all: [WoodlandTree] = front.items.map { item in
            WoodlandTree(
                id: item.id, name: item.name, isPrivate: item.isPrivate, days: item.runDays.count,
                marks: WoodlandLog.marks(runDays: item.runDays, daily: item.daily, weekdays: item.weekdays,
                                         today: today, calendar: calendar),
                doneToday: item.doneAt != nil,
                dueToday: front.todayIDs.contains(item.id)
                    || WoodlandLog.isDue(today: today, daily: item.daily, weekdays: item.weekdays, calendar: calendar),
                cap: WoodlandLog.cap(steps: item.exercises), species: WoodlandLog.species(item.id),
                steps: item.exercises,
                restToday: !item.daily && !item.weekdays.isEmpty && item.doneAt == nil
                    && !item.weekdays.contains(calendar.component(.weekday, from: today))
            )
        }
        self.init(trees: all, front: front, notNow: notNow)
    }

    /// The pure part, for tests: plants already read.
    init(trees all: [WoodlandTree], front: RoutinesFront? = nil, notNow: Set<UUID> = []) {
        // Today's and the ones needing care stand in front; then the oldest. At most 12 in the wide view.
        let ordered = all.sorted { lhs, rhs in
            let left = Self.rank(lhs), right = Self.rank(rhs)
            return left != right ? left < right :
                (lhs.days != rhs.days ? lhs.days > rhs.days : lhs.id.uuidString < rhs.id.uuidString)
        }
        trees = Array(ordered.prefix(WoodlandLayout.capacity))
        stateLine = Self.stateLine(all)
        var updates: [Update] = []
        let next = front.flatMap { front in
            front.ordered.first { $0.doneAt == nil && !notNow.contains($0.id) && $0.id != front.running?.routineID }
        }
        if let next {
            let when = next.usual.map { ", around \(RoutinesLandingWords.clock($0.startMinuteOfDay))" } ?? ""
            updates.append(Update(id: next.id, kind: .next, name: next.name, rest: " is next\(when)"))
        } else if let due = all.first(where: { $0.dueToday && !$0.doneToday && !notNow.contains($0.id) }) {
            updates.append(Update(id: due.id, kind: .next, name: due.name, rest: " is next"))
        }
        let care = all.filter { !notNow.contains($0.id) && !updates.map(\.id).contains($0.id) }
            .sorted { Self.urgency($0) > Self.urgency($1) }
            .first { Self.urgency($0) > 0 }
        if let care {
            let rest = care.health.isBare ? " could begin again"
                : care.health.isWithering ? " needs a little care" : " has fruit to collect"
            updates.append(Update(id: care.id, kind: .care, name: care.name, rest: rest))
        }
        self.updates = updates
        doors = Self.doorNames.map { id, name in
            let members: [WoodlandTree] = switch id {
            case "today": all.filter { $0.dueToday && !$0.doneToday }
            // Every routine today is a workout routine, so it grows in Body. Mind, Home and Across the lake
            // (borrowed from other rooms) fill as those routines arrive.
            case "body": all
            case "fruit": all.filter(\.hasFruit)
            default: []
            }
            return Door(id: id, name: name, count: members.count, lines: Self.doorLines(id: id, members))
        }
    }

    // MARK: Words

    /// "3 done today, 8 to tend, 2 need a little care." then shorter; never "N of M".
    static func stateLine(_ all: [WoodlandTree]) -> [String] {
        guard !all.isEmpty else { return ["Quiet day. Plant the first one."] + ["Quiet day."] }
        let done = all.filter(\.doneToday).count
        let care = all.filter { $0.health.isWithering || $0.health.isBare }.count
        let tend = all.filter { !$0.doneToday && !$0.health.isWithering && !$0.health.isBare }.count
        var long: [String] = []
        var short: [String] = []
        if done > 0 {
            long.append("\(done) done today")
            short.append("\(done) done")
        }
        if tend > 0 {
            long.append("\(tend) to tend")
            short.append("\(tend) to tend")
        }
        if care > 0 {
            long.append("\(care) \(care == 1 ? "needs" : "need") a little care")
            short.append("\(care) need care")
        }
        if long.isEmpty {
            return ["Quiet day."]
        }
        let first = short.first ?? "Quiet day"
        return [long.joined(separator: ", ") + ".", short.joined(separator: ", ") + ".", first + "."]
    }

    /// The door's up to three state lines ("3 to tend", "1 needs a little care", "1 to begin again").
    static func doorLines(id: String, _ members: [WoodlandTree]) -> [String] {
        if members.isEmpty {
            return [id == "lake" ? "Borrowed routines" : "Nothing planted"]
        }
        if id == "fruit" {
            return ["\(members.count) to collect"] + members.prefix(2).map(\.name)
        }
        var lines: [String] = []
        let tend = members.filter { !$0.doneToday && !$0.health.isWithering && !$0.health.isBare }.count
        let care = members.filter(\.health.isWithering).count
        let bare = members.filter(\.health.isBare).count
        let done = members.filter(\.doneToday).count
        if tend > 0 {
            lines.append("\(tend) to tend")
        }
        if care > 0 {
            lines.append("\(care) \(care == 1 ? "needs" : "need") a little care")
        }
        if bare > 0 {
            lines.append("\(bare) to begin again")
        }
        if done > 0, lines.count < 3 {
            lines.append("\(done) done today")
        }
        return Array(lines.prefix(3))
    }

    /// The caption under the scene: the tapped plant, or the oldest one; longest form first.
    static func caption(for tree: WoodlandTree?, selected: Bool) -> [String] {
        guard let tree else { return ["Plant a routine and it grows here."] + ["Nothing planted yet."] }
        let days = "\(tree.days) \(tree.days == 1 ? "day" : "days")"
        let state = tree.stateWords.map { ", \($0)" } ?? ""
        if selected {
            return ["\(tree.name), \(tree.stageWords), \(days)\(state). Tap again to open.",
                    "\(tree.name), \(tree.stageWords)\(state).", "\(tree.name), \(tree.stageWords).", tree.name]
        }
        return [
            "\(tree.name) is the oldest, a \(tree.stageWords) at \(days).",
            "\(tree.name), \(tree.stageWords), \(days).",
            tree.name,
        ]
    }

    /// The oldest healthy plant, for the caption at rest.
    var oldest: WoodlandTree? {
        trees.max { $0.days < $1.days }
    }

    private static func rank(_ tree: WoodlandTree) -> Int {
        if tree.dueToday, !tree.doneToday {
            return 0
        }
        if tree.health.isWithering || tree.health.isBare {
            return 1
        }
        return 2
    }

    private static func urgency(_ tree: WoodlandTree) -> Int {
        if tree.health.isBare {
            return 3
        }
        if tree.health.isWithering {
            return 2
        }
        return tree.hasFruit ? 1 : 0
    }
}

/// "Not now" on a routine row: hidden from the brief for the rest of the day, kept on this phone only (never in the
/// op log, a backup or a widget).
enum RoutinesNotNow {
    static func ids(on day: Date, defaults: UserDefaults = .standard) -> Set<UUID> {
        let key = "routines.notNow.\(Int(day.timeIntervalSince1970))"
        return Set((defaults.stringArray(forKey: key) ?? []).compactMap(UUID.init(uuidString:)))
    }

    static func set(_ id: UUID, on day: Date, hidden: Bool, defaults: UserDefaults = .standard) {
        let key = "routines.notNow.\(Int(day.timeIntervalSince1970))"
        var all = ids(on: day, defaults: defaults)
        if hidden {
            all.insert(id)
        } else {
            all.remove(id)
        }
        defaults.set(all.map(\.uuidString), forKey: key)
    }
}
