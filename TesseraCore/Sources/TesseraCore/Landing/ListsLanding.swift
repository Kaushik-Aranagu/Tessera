import Foundation

/// What the Lists landing says (design 131, Product build sheet Oct 22). Counts and names only, computed on the phone.
/// A walled list reads "Private list", a walled item "Private item", a private recipe "Private recipe", all masked
/// before any template sees them. An item's due date is the `due:` stamp line in its notes (the catalog is frozen).
@MainActor
public struct ListsLanding {
    public struct Lead: Equatable, Sendable {
        public let list: UUID
        public let name: String
        public let sentence: LandingSentence
        /// Up to four open items, in order, as large words.
        public let nextItems: [String]
        public let left: Int
        public let total: Int
        /// "6 left of 24", small, under the items.
        public let leftOf: String?
    }

    public struct Other: Equatable, Sendable {
        public let list: UUID
        public let name: String
        public let done: Int
        public let total: Int
        /// done / total, the share the name fills with ink from the left.
        public let fill: Double
        public let line: String?
    }

    public struct Margin: Equatable, Sendable {
        public enum Kind: Sendable { case waiting, new }
        public let kind: Kind
        public let sentence: LandingSentence
        public let action: String?
        /// The list the line is about, and the item when it is about one. Ids only; never a private name.
        public let list: UUID
        public let item: UUID?
    }

    public struct Doors: Equatable, Sendable {
        public let reusable: Int
        public let picks: Int
        public let runs: Int
    }

    public struct Facts: Equatable, Sendable {
        public let lead: Lead?
        public let others: [Other]
        public let margin: [Margin]
        public let doors: Doors
        public let subtitle: LandingSentence
    }

    public struct Options: Sendable {
        /// listsMargin: the margin lines show at all.
        public var margin = true
        /// listsLeadByDue: with nothing running, the list due soonest leads.
        public var leadByDue = false
        public var lastSeen: Date?
        public var now: Date = .now
        public var calendar: Calendar = .current

        public init(margin: Bool = true, leadByDue: Bool = false, lastSeen: Date? = nil, now: Date = .now,
                    calendar: Calendar = .current)
        {
            self.margin = margin
            self.leadByDue = leadByDue
            self.lastSeen = lastSeen
            self.now = now
            self.calendar = calendar
        }
    }

    public static let maxOthers = 6
    public static let maxMargin = 3
    public static let nextItemCount = 4

    public let engine: ActionEngine

    var store: ObjectStore {
        engine.store
    }

    var classes: [SystemCatalog.Key: ClassDef] {
        engine.classes
    }

    var contents: ListContents {
        ListContents(store: store, classes: classes)
    }

    public init(engine: ActionEngine) {
        self.engine = engine
    }

    // MARK: Reading

    struct Row {
        let list: ObjectRecord
        let name: String
        let items: [ListContents.Item]
        var left: Int {
            items.count { !$0.isDone }
        }

        var done: Int {
            items.count(where: \.isDone)
        }

        var total: Int {
            items.count
        }

        var touched: Date
    }

    func dueDate(_ item: ListContents.Item) -> Date? {
        ListNoteTags.stamp(ListNoteTags.duePrefix, in: store.value("notes", of: item.object)?.stringValue)
    }

    func itemName(_ item: ListContents.Item) -> String {
        ObjectPrivacy.isPrivateWord(item.text, in: store) ? "Private item" : item.text
    }

    func rows() -> [Row] {
        contents.lists().filter { !$0.isDeleted }.map { list in
            let items = contents.items(of: list)
            let touched = ([list.updatedAt] + items.flatMap { [$0.object.updatedAt, $0.checkedAt ?? .distantPast] })
                .max()
                ?? list.updatedAt
            return Row(list: list, name: ListContents.shownName(of: list, in: store), items: items, touched: touched)
        }
    }

    func runningLists() -> [UUID: Date] {
        var started: [UUID: Date] = [:]
        for process in ProcessTable(engine: engine).all() where process.state == .running {
            if let subject = process.subject, subject.classDef?.id == classes[.list]?.id {
                started[subject.id] = max(started[subject.id] ?? .distantPast, process.startedAt ?? .distantPast)
            }
        }
        return started
    }

    func dayWord(_ date: Date, _ options: Options) -> String {
        let day = TesseraDay(calendar: options.calendar)
        let today = day.today(options.now)
        let target = day.day(of: date)
        let gap = options.calendar.dateComponents([.day], from: today, to: target).day ?? 0
        switch gap {
        case ..<1: return "today"
        case 1: return "tomorrow"
        default:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.calendar = options.calendar
            formatter.timeZone = options.calendar.timeZone
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }

    /// The soonest due date among a list's open items.
    func soonestDue(_ row: Row) -> Date? {
        row.items.filter { !$0.isDone }.compactMap(dueDate).min()
    }

    // MARK: Facts

    public func facts(_ options: Options = Options()) -> Facts {
        let all = rows()
        let running = runningLists()
        let groceries = Groceries.listID
        var lead: Lead?
        var leadID: UUID?
        if let pick = pickLead(all, running: running, options: options) {
            lead = pick.lead
            leadID = pick.row.list.id
        }
        // Groceries is always there; it is a band only once something is on it.
        let others = all.filter { $0.list.id != leadID && !($0.list.id == groceries && $0.total == 0) }
            .sorted { $0.touched > $1.touched }
            .prefix(Self.maxOthers)
            .map { row in other(row, running: running, groceries: groceries, options: options) }
        let margin = options.margin ? marginLines(all, groceries: groceries, options: options) : []
        let table = ProcessTable(engine: engine).all().filter { $0.subject?.classDef?.id == classes[.list]?.id }
        let doors = Doors(
            reusable: all.count { ListNoteTags.isReusable($0.list, in: store) },
            picks: all.count { contents.isPickOne($0.list) },
            runs: table.count
        )
        return Facts(lead: lead, others: Array(others), margin: margin, doors: doors,
                     subtitle: lead?.sentence ?? LandingSentences.startOneList)
    }

    func pickLead(_ all: [Row], running: [UUID: Date], options: Options) -> (row: Row, lead: Lead)? {
        func lead(_ row: Row, _ sentence: LandingSentence) -> (Row, Lead) {
            let open = row.items.filter { !$0.isDone }
            return (row, Lead(
                list: row.list.id, name: row.name, sentence: sentence,
                nextItems: open.prefix(Self.nextItemCount).map(itemName),
                left: row.left, total: row.total,
                leftOf: LandingSentences.leftOf(left: row.left, total: row.total)
            ))
        }
        if let newest = all.filter({ running[$0.list.id] != nil })
            .max(by: { (running[$0.list.id] ?? .distantPast) < (running[$1.list.id] ?? .distantPast) })
        {
            return lead(newest, LandingSentences.listRunning(newest.name, left: newest.left))
        }
        if options.leadByDue,
           let due = all.compactMap({ row in soonestDue(row).map { (row, $0) } }).min(by: { $0.1 < $1.1 })
        {
            return lead(due.0, LandingSentences.listDue(due.0.name, day: dayWord(due.1, options)))
        }
        guard let touched = all.filter({ !$0.items.isEmpty }).max(by: { $0.touched < $1.touched }) else { return nil }
        return lead(touched, LandingSentences.listTouchedLast(touched.name))
    }

    func other(_ row: Row, running: [UUID: Date], groceries: UUID, options: Options) -> Other {
        let fill = row.total == 0 ? 0 : Double(row.done) / Double(row.total)
        var line: String? = if row.list.id == groceries {
            LandingSentences.listLine(toGet: row.left, newFrom: newSource(row, options))
        } else if running[row.list.id] != nil {
            LandingSentences.listRunningLine(left: row.left)
        } else if row.total == 0 {
            "Empty"
        } else if row.left == 0 {
            "All done"
        } else if let due = soonestDue(row) {
            LandingSentences.listDueLine(day: dayWord(due, options), left: row.left)
        } else {
            LandingSentences.listLeft(row.left)
        }
        return Other(list: row.list.id, name: row.name, done: row.done, total: row.total, fill: fill, line: line)
    }

    /// The recipe a list's new open items came from, "Private recipe" when it is walled.
    func newSource(_ row: Row, _ options: Options) -> String? {
        guard let seen = options.lastSeen else { return nil }
        for item in row.items.filter({ !$0.isDone && $0.object.createdAt > seen }) {
            let shares = GroceryShare.decode(store.value("shares", of: item.object)?.stringValue)
            if let id = shares.compactMap(\.recipe).first, let recipe = store.object(id: id), !recipe.isDeleted {
                // A recipe is private by its words only: it has no flag.
                return ObjectPrivacy.isPrivateWord(recipe.title, in: store) ? "Private recipe" : recipe.title
            }
        }
        return nil
    }

    func marginLines(_ all: [Row], groceries: UUID, options: Options) -> [Margin] {
        var waiting: [Margin] = []
        var fresh: [Margin] = []
        let day = TesseraDay(calendar: options.calendar)
        let tomorrow = day.day(1, after: options.now)
        // An open item due tomorrow.
        outer: for row in all {
            for item in row.items where !item.isDone {
                if let due = dueDate(item), day.day(of: due) == tomorrow {
                    waiting.append(Margin(kind: .waiting, sentence: LandingSentences.itemDueTomorrow(
                        itemName(item), on: row.name
                    ), action: nil, list: row.list.id, item: item.id))
                    break outer
                }
            }
        }
        // A reusable list that is all done.
        if let done = all.first(where: {
            $0.total > 0 && $0.left == 0 && ListNoteTags.isReusable($0.list, in: store)
        }) {
            waiting.append(Margin(kind: .waiting, sentence: LandingSentences.listDoneReset(done.name),
                                  action: LandingSentences.resetIt, list: done.list.id, item: nil))
        }
        if let seen = options.lastSeen {
            let counted = all.compactMap { row -> (Row, Int)? in
                let count = row.items.count { !$0.isDone && $0.object.createdAt > seen }
                return count > 0 ? (row, count) : nil
            }.sorted { $0.1 > $1.1 }
            if let top = counted.first {
                let source = top.0.list.id == groceries ? newSource(top.0, options) : nil
                fresh.append(Margin(kind: .new, sentence: LandingSentences.listHasNew(top.0.name, count: top.1,
                                                                                      from: source),
                                    action: nil, list: top.0.list.id, item: nil))
            }
        }
        return Array((waiting + fresh).prefix(Self.maxMargin))
    }
}

// MARK: - Due this week (the Lists landing's word wall)

public extension ListsLanding {
    /// One open item with a due day. Names arrive masked: a walled list reads "Private list", a walled item
    /// "Private item", and `isPrivate` says either was walled so a surface can leave it out.
    struct DueItem: Equatable, Sendable {
        public let list: UUID
        public let listName: String
        public let item: UUID
        public let text: String
        public let due: Date
        public let isPrivate: Bool
        /// "today", "tomorrow", "Fri".
        public let day: String

        public init(list: UUID, listName: String, item: UUID, text: String, due: Date, isPrivate: Bool, day: String) {
            self.list = list
            self.listName = listName
            self.item = item
            self.text = text
            self.due = due
            self.isPrivate = isPrivate
            self.day = day
        }
    }

    /// Open items due before the end of the next `days` house days (late ones included), soonest first. Groceries is
    /// left out (it is Pantry's To get).
    func dueItems(within days: Int = 7, now: Date = .now, calendar: Calendar = .current) -> [DueItem] {
        let house = TesseraDay(calendar: calendar)
        let today = house.today(now)
        guard let end = calendar.date(byAdding: .day, value: days, to: today) else { return [] }
        let options = Options(now: now, calendar: calendar)
        var found: [DueItem] = []
        for row in rows() where row.list.id != Groceries.listID {
            let listPrivate = row.name == ListContents.privateListLabel
            for item in row.items where !item.isDone {
                guard let due = dueDate(item), due < end else { continue }
                let text = itemName(item)
                found.append(DueItem(list: row.list.id, listName: row.name, item: item.id, text: text, due: due,
                                     isPrivate: listPrivate || text == "Private item", day: dayWord(due, options)))
            }
        }
        return found.sorted { $0.due != $1.due ? $0.due < $1.due : $0.item.uuidString < $1.item.uuidString }
    }
}
