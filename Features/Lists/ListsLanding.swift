import SwiftUI
import TesseraCore

// The Lists landing, design 131 section 2 and 2d, and the build sheet
// product/notes-lists-landing-build-sheet-oct22.md section 2B. Behind Review switch "Landing pages" (Builder B's
// `LandingSwitch`), with `listsLeadByDue` and `listsMargin` as the sheet's own switches (default Off).
// Which list leads, the lines, the margin and the subtitle come from Core's `ListsLanding` (#1230).

// MARK: - Facts

struct ListsLandingFacts {
    /// One list as the landing needs it. Names are already masked ("Private list"); a private list has no item words.
    struct Line: Identifiable, Equatable {
        let id: UUID
        let name: String
        let isGroceries: Bool
        let isPrivate: Bool
        let isRunning: Bool
        let isReusable: Bool
        let isPickOne: Bool
        let left: Int
        let total: Int
        /// The next open items as words, up to four, for the lead only; empty for a private list.
        var nextItems: [(text: String, isPrivate: Bool)] = []
        /// New since last looked, and the one source they came from when there is one ("Tacos").
        var newCount = 0
        var newSource: String?
        var touched = Date.distantPast
        /// Picks: the last pick, as the item's shown words and its day.
        var lastPick: (text: String, on: Date)?
        /// Core's one short line for it (T-L6 to T-L10), when Core gave one.
        var coreLine: String?

        static func == (lhs: Line, rhs: Line) -> Bool {
            lhs.id == rhs.id && lhs.left == rhs.left && lhs.total == rhs.total && lhs.isRunning == rhs.isRunning
        }

        /// The share done, for the filling line: 0 for an empty list.
        var fraction: Double {
            total > 0 ? Double(total - left) / Double(total) : 0
        }

        /// T-L6 to T-L10: the one short line under a name.
        var line: String {
            if let coreLine {
                return coreLine
            }
            if total == 0 {
                return "Empty"
            }
            if left == 0 {
                return "All done"
            }
            if isGroceries {
                return LandingSentences.listLine(toGet: left, newFrom: newSource) ?? "\(left) to get"
            }
            return isRunning ? "Running, \(left) left" : "\(left) left"
        }
    }

    struct Margin: Identifiable, Equatable {
        enum Act: Equatable {
            case open(UUID)
            case reset(UUID)
        }

        let id: String
        let text: String
        let word: String?
        let act: Act
    }

    var lead: Line?
    var others: [Line] = []
    var waiting: [Margin] = []
    var new: [Margin] = []
    var hasReusable = false
    var hasPicks = false
    /// Core's subtitle (T-L1 to T-L5).
    var subtitle: LandingSentence?

    @MainActor
    static func load(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], engine: ActionEngine?,
                     lastSeen: Date?, margin: Bool, leadByDue: Bool = false) -> ListsLandingFacts
    {
        let contents = ListContents(store: store, classes: classes)
        let lists = contents.shelf().filter { !$0.isDeleted }
        let open = (engine.map { ProcessTable(engine: $0).all() } ?? []).filter(\.state.isOpen)
        let runs = Dictionary(open.compactMap { process in
            process.subject.map { ($0.id, process.startedAt ?? .distantPast) }
        }, uniquingKeysWith: max)

        var lines: [Line] = lists.map { list in
            let isGroceries = list.id == Groceries.listID
            let name = ListContents.shownName(of: list, in: store)
            let isPrivate = name == ListContents.privateListLabel
            let items = contents.items(of: list)
            let openItems = items.filter { !$0.isDone }
            var line = Line(id: list.id, name: name, isGroceries: isGroceries, isPrivate: isPrivate,
                            isRunning: !isGroceries && runs[list.id] != nil,
                            isReusable: !isGroceries && contents.isReusable(list),
                            isPickOne: !isGroceries && contents.isPickOne(list),
                            left: openItems.count, total: items.count)
            line.touched = ListsShelf.touched(list)
            if !isPrivate {
                line.nextItems = openItems.prefix(4).map { item in
                    let shown = ObjectPrivacy.isPrivateWord(item.text, in: store) ? "Private item" : item.text
                    return (shown, shown != item.text)
                }
            }
            if line.isPickOne {
                line.lastPick = items.compactMap { item in
                    contents.pickedAt(item.object).map { (
                        ObjectPrivacy.isPrivateWord(item.text, in: store) ? "Private item" : item.text,
                        $0
                    ) }
                }.max { $0.1 < $1.1 }.map { (text: $0.0, on: $0.1) }
            }
            if let lastSeen {
                let fresh = items.filter { $0.object.createdAt > lastSeen }
                line.newCount = fresh.count
                let sources = Set(fresh.compactMap { item -> String? in
                    store.linkedObjects("about", of: item.object).first.map { source in
                        ObjectPrivacy.shownLabel(of: source, in: store, classes: classes) ?? source.title
                    }
                })
                line.newSource = sources.count == 1 ? sources.first : nil
            }
            return line
        }
        // Groceries is Pantry's To get now, not a list line here (Design on #1226).
        lines.removeAll(where: \.isGroceries)
        // Running first, the newer run first; then by last touched (the shelf's own order).
        lines.sort { lhs, rhs in
            switch (runs[lhs.id], runs[rhs.id]) {
            case let (left?, right?): left > right
            case (.some, nil): true
            case (nil, .some): false
            case (nil, nil): lhs.touched > rhs.touched
            }
        }

        // Which list leads, the others in order, their lines, the margin and the subtitle: Core's `ListsLanding`
        // (#1230), the single source. The per-list flags the page draws (reusable, pick one, new) stay as read above.
        var facts = ListsLandingFacts()
        facts.hasReusable = lines.contains { $0.isReusable }
        facts.hasPicks = lines.contains { $0.isPickOne }
        guard let engine else {
            facts.lead = lines.first
            facts.others = Array(lines.dropFirst().prefix(6))
            return facts
        }
        let core = ListsLanding(engine: engine)
            .facts(ListsLanding.Options(margin: margin, leadByDue: leadByDue, lastSeen: lastSeen, now: AppClock.now))
        let byID = Dictionary(lines.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        facts.subtitle = core.subtitle
        if let lead = core.lead, var line = byID[lead.list] {
            line.nextItems = lead.nextItems.map { ($0, $0 == "Private item") }
            facts.lead = line
        }
        facts.others = core.others.compactMap { other in
            guard var line = byID[other.list] else { return nil }
            line.coreLine = other.line
            return line
        }
        for (index, entry) in core.margin.enumerated() {
            let act: Margin.Act = entry.action == "Reset it for next time" ? .reset(entry.list) : .open(entry.list)
            let line = Margin(id: "\(entry.kind)-\(index)", text: entry.sentence.text, word: entry.action, act: act)
            switch entry.kind {
            case .waiting: facts.waiting.append(line)
            case .new: facts.new.append(line)
            }
        }
        return facts
    }

    /// T-L1 to T-L5 (the due form has no source yet): the subtitle. The key word is the list's name.
    func sentence() -> AccentedSentence {
        if let subtitle {
            return AccentedSentence(text: subtitle.text, key: subtitle.key)
        }
        guard let lead else { return AccentedSentence(text: "Start one with a few words.", key: nil) }
        if lead.isRunning {
            return AccentedSentence(text: "\(lead.name) is running, \(lead.left) left.", key: lead.name)
        }
        return AccentedSentence(text: "\(lead.name) is the one you touched last.", key: lead.name)
    }
}

// MARK: - Which page opens from the landing

/// The doors that are pages of their own: the old shelf, and the Reusable and Picks lists.
enum ListsDoor: Hashable {
    case shelf, reusable, picks
}

// MARK: - The wall (landing contract §2, §12: what is due this week)

/// The Lists landing's words as data, so the wall, the state line and the doors have tests. Walled lists and items
/// never reach the wall: they are only counted.
@MainActor
struct ListsWall: Equatable {
    /// Every word on the wall, with the list a tap opens.
    var words: [WallWord] = []
    var opens: [String: UUID] = [:]
    /// The header line, longest form first (FitLine).
    var stateLine: [String] = []
    /// Lists or due items that are walled, counted, never named.
    var hidden = 0
    /// Open items due this week across every list (walled ones counted).
    var dueCount = 0
    /// The soonest due list a tap on "Due soon" opens; nil when it is walled or nothing is due.
    var soonest: UUID?
    var dueLines: [String] = []

    static let maxWords = 14

    static func build(due: [ListsLanding.DueItem], lists: [ListsLandingFacts.Line]) -> ListsWall {
        var wall = ListsWall()
        wall.dueCount = due.count
        var seenLists: Set<UUID> = []
        var index = 0
        func add(_ id: String, _ text: String, list: UUID, weight: Double) {
            guard wall.words.count < maxWords, wall.opens[id] == nil else { return }
            wall.words.append(WallWord(id: id, text: NotesLandingPage.short(text), weight: weight))
            wall.opens[id] = list
        }
        for item in due where !item.isPrivate {
            // The list first, then its due thing: the heaviest words are the soonest.
            if !seenLists.contains(item.list) {
                seenLists.insert(item.list)
                add(
                    "list:\(item.list.uuidString)",
                    item.listName,
                    list: item.list,
                    weight: max(0.55, 1 - 0.06 * Double(index))
                )
            }
            add(
                "item:\(item.item.uuidString)",
                item.text,
                list: item.list,
                weight: max(0.5, 0.95 - 0.06 * Double(index))
            )
            wall.dueLines.append("\(item.text), \(item.day)")
            index += 1
        }
        wall.soonest = due.first.flatMap { $0.isPrivate ? nil : $0.list }
        // Then the rest of the shelf, last touched first, lighter.
        for (offset, line) in lists.enumerated() where !line.isPrivate && !seenLists.contains(line.id) {
            add("list:\(line.id.uuidString)", line.name, list: line.id, weight: max(0.1, 0.45 - 0.04 * Double(offset)))
        }
        wall.hidden = lists.count(where: \.isPrivate)
            + due.count { $0.isPrivate && $0.listName != ListContents.privateListLabel }
        wall.stateLine = stateLine(due)
        return wall
    }

    /// "Trip is due Fri, 4 things due this week." / "Trip is due Fri." / "4 due this week." A walled list reads
    /// "Private list". Nothing due: "Nothing due this week."
    static func stateLine(_ due: [ListsLanding.DueItem]) -> [String] {
        guard let first = due.first else { return ["Nothing due this week."] }
        let name = first.listName
        let lead = "\(name) is due \(first.day)"
        if due.count == 1 {
            return ["\(lead).", "1 due this week."]
        }
        return ["\(lead), \(due.count) things due this week.", "\(lead).", "\(due.count) due this week."]
    }
}

// MARK: - The page

/// The Lists landing on the shared kit (landing contract §12): the word wall of what is due this week, the doors on
/// the dial, one line about the list in hand, "New list" at the foot. Walled lists never reach the wall.
struct ListsLandingPage: View {
    let openList: (UUID) -> Void
    let openDoor: (ListsDoor) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var seenAtOpen: Date?
    @State private var focus = 0
    @State private var naming = false
    @State private var draft = ""

    private var margin: Bool {
        Choice.value("listsMargin", options: ["Off", "On"], default: "Off") == "On"
    }

    private struct Shown {
        let facts: ListsLandingFacts
        let lines: [ListsLandingFacts.Line]
        let wall: ListsWall
        let doors: [DialDoor]
    }

    var body: some View {
        let _ = model.revision
        let shown = load()
        LandingFrame(title: "Lists", accent: LandingAccent.lists, stateLine: shown.wall.stateLine,
                     onTitle: { openDoor(.shelf) },
                     keystone: {
                         LandingKeystone(label: "Due this week") {
                             WordWallView(words: shown.wall.words) { id in
                                 if let list = shown.wall.opens[id] {
                                     openList(list)
                                 }
                             }
                         }
                     },
                     doors: shown.doors, focus: $focus,
                     openDoor: { door in open(door, shown) },
                     brief: { LandingBrief(forms: brief(shown.facts, lines: shown.lines)) },
                     action: LandingFootAction(word: "New list", hint: "Makes a list") {
                         draft = ""
                         naming = true
                     },
                     onBack: { dismiss() })
            .toolbar(.hidden, for: .navigationBar)
            .alert("New list", isPresented: $naming) {
                TextField("", text: $draft)
                Button("Make") { make() }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                if seenAtOpen == nil {
                    seenAtOpen = LandingSeen.date("lists")
                }
                LandingSeen.mark("lists", at: AppClock.now)
            }
    }

    // MARK: Facts

    private func load() -> Shown {
        let facts = ListsLandingFacts.load(store: model.store, classes: model.classes, engine: model.engine,
                                           lastSeen: seenAtOpen, margin: margin,
                                           leadByDue: Choice.value("listsLeadByDue", options: ["Off", "On"],
                                                                   default: "Off") == "On")
        let lines = [facts.lead].compactMap(\.self) + facts.others
        let due = ListsLanding(engine: model.engine).dueItems(within: 7, now: AppClock.now)
        let wall = ListsWall.build(due: due, lists: lines)
        return Shown(facts: facts, lines: lines, wall: wall, doors: doors(lines: lines, wall: wall, facts: facts))
    }

    private func doors(lines: [ListsLandingFacts.Line], wall: ListsWall, facts: ListsLandingFacts) -> [DialDoor] {
        let dark = scheme == .dark
        let wine = dark ? Color(hex: 0xEE8E9C) : Color(hex: 0x9A2541)
        let slate = dark ? Color(hex: 0xA7BCD6) : Color(hex: 0x34506F)
        let open = lines.filter { !$0.isPrivate }
        var doors = [DialDoor(id: "all", name: "All lists", count: lines.isEmpty ? nil : "\(lines.count)",
                              color: Theme.Colors.ink, label: open.isEmpty ? nil : "Touched last",
                              lines: open.prefix(3).map(\.name))]
        if wall.dueCount > 0 {
            doors.append(DialDoor(id: "due", name: "Due soon", count: "\(wall.dueCount)", color: wine,
                                  label: "This week", lines: Array(wall.dueLines.prefix(3))))
        }
        if facts.hasReusable {
            let reusable = open.filter(\.isReusable)
            doors.append(DialDoor(id: "reusable", name: "Reusable", count: "\(lines.count(where: \.isReusable))",
                                  color: LandingAccent.lists, label: "Used again and again",
                                  lines: reusable.prefix(3).map(\.name)))
        }
        if facts.hasPicks {
            let picks = open.filter(\.isPickOne)
            doors.append(DialDoor(id: "picks", name: "Picks", count: "\(lines.count(where: \.isPickOne))",
                                  color: Theme.Colors.ink, label: "Pick one thing from",
                                  lines: picks.prefix(3).map(\.name)))
        }
        if wall.hidden > 0 {
            doors.append(DialDoor(id: "private", name: "Private", count: "\(wall.hidden)", color: slate,
                                  label: "Kept off the wall", lines: ["\(wall.hidden) kept private"]))
        }
        return doors
    }

    /// The list in hand, from Core's subtitle (running, due or touched last), its name in ink 600.
    private func brief(_ facts: ListsLandingFacts, lines: [ListsLandingFacts.Line]) -> [LandingBrief.Form] {
        // Groceries is Pantry's To get, not a list here: when Core's subtitle leads with it, the shelf's newest list
        // speaks instead.
        let sentence = facts.lead == nil && !lines.isEmpty
            ? AccentedSentence(text: "\(lines[0].name) is the one you touched last.", key: lines[0].name)
            : facts.sentence()
        var forms = [LandingBrief.Form(text: sentence.text, key: sentence.key)]
        if let lead = facts.lead, lead.left > 0 {
            forms.append(LandingBrief.Form(text: "\(lead.name), \(lead.left) left.", key: lead.name))
        }
        return forms
    }

    private func open(_ door: DialDoor, _ shown: Shown) {
        switch door.id {
        case "due":
            if let list = shown.wall.soonest {
                openList(list)
            } else {
                openDoor(.shelf)
            }
        case "reusable": openDoor(.reusable)
        case "picks": openDoor(.picks)
        default: openDoor(.shelf)
        }
    }

    // MARK: Making

    private func make() {
        let name = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if looksLikeClaudeKey(name) {
            draft = ""
            TessVoice.shared.say(claudeKeyLine)
            return
        }
        guard let result = try? model.engine.perform(CreateList(name: name), by: .user) else {
            TessVoice.shared.say("That can't be a list name.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            draft = ""
            model.touch()
        }
        if let receipt = result.record.receipt {
            TessVoice.shared.say(receipt, undo: CreateList.wasRepeat(result.record) ? nil : result.record)
        }
        openList(result.output.id)
    }
}

// MARK: - Every other list (L4): the line that fills

/// A list's name in large type, filled with ink from the left by the share done (unfilled 66% ink so it stays
/// readable), one short line under it. The fill is the strike and count in one stroke. Swipe right ticks the next
/// open item. Under Reduce Motion the fill simply appears.
struct FillingLine: View {
    let line: ListsLandingFacts.Line
    let accent: Color
    let open: () -> Void
    let tick: () -> Void
    /// Picks are never "done": a plain name, no fill.
    var filled = true
    /// The words under the name when the page says something other than the line (Reusable, Picks).
    var valueText: String?
    /// Sheet 139 part 3 (Review > Together > Finish moments): a finished list reads "All packed." or "All done."
    /// and, when reusable, offers "Reset it for next time". Off leaves the line as it was.
    var finishOn = false
    var reset: () -> Void = {}

    private var moment: Bool {
        finishOn && FinishMoments.listIsFinished(left: line.left, total: line.total, isPickOne: line.isPickOne)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            row
            if moment, line.isReusable {
                Button(FinishMoments.resetWord, action: reset)
                    .buttonStyle(LandingWordStyle())
            }
        }
    }

    private var row: some View {
        Button(action: open) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                nameView
                Text(value)
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .rowSwipe(.leading, arm: CGFloat(GestureTuning.armUndrawn)) { event in
            if case .committed = event {
                tick()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(line.name), \(moment ? value : line.line)")
        .accessibilityHint("Opens the list")
        .accessibilityAction(named: Text("Check off next")) { tick() }
    }

    private var value: String {
        moment ? FinishMoments.listLine(name: line.name) : valueText ?? line.line
    }

    @ViewBuilder
    private var nameView: some View {
        let base = Text(line.name).textRole(.title)
        if filled, line.total > 0 {
            base
                .foregroundStyle(Theme.Colors.ink.opacity(0.66))
                .overlay(alignment: .leading) {
                    Text(line.name)
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.ink)
                        .mask(alignment: .leading) {
                            Rectangle()
                                .scaleEffect(x: max(0, min(1, line.fraction)), anchor: .leading)
                        }
                }
                .fixedSize(horizontal: false, vertical: true)
                .tesseraAnimation(value: line.fraction)
        } else {
            base
                .foregroundStyle(Theme.Colors.ink.opacity(filled ? 0.66 : 1))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Reusable and Picks (2d)

/// Reusable or Picks as a plain page of lines (the rail version waits for RailPage): the same filling line, a
/// different value under each. Swipe right on a reusable list is Reset; on a pick-one list it opens the list, where
/// the pick moment lives.
struct ListsKindPage: View {
    let door: ListsDoor
    let openList: (UUID) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let _ = model.revision
        let facts = ListsLandingFacts.load(store: model.store, classes: model.classes, engine: model.engine,
                                           lastSeen: nil, margin: false)
        let all = ([facts.lead].compactMap(\.self) + facts.others)
        let lines = all.filter { door == .reusable ? $0.isReusable : $0.isPickOne }
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    Text("‹ Lists")
                        .textRole(.data)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(HandleButtonStyle())
                Text(door == .reusable ? "Reusable" : "Picks")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(door == .reusable ? "Lists you use again and again." : "Lists you pick one thing from.")
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .padding(.top, Theme.Spacing.s)
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    ForEach(lines) { line in
                        KindRow(line: line, door: door, open: { openList(line.id) }, reset: { reset(line) })
                    }
                }
                .padding(.top, Theme.Spacing.xxl)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.m)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func reset(_ line: ListsLandingFacts.Line) {
        guard let result = try? model.engine.perform(ResetList(list: line.id, time: AppClock.now), by: .user) else {
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        TessVoice.shared.say(ListsCopy.reset(line.name), undo: result.record)
    }
}

private struct KindRow: View {
    let line: ListsLandingFacts.Line
    let door: ListsDoor
    let open: () -> Void
    let reset: () -> Void

    var body: some View {
        FillingLine(line: line, accent: LandingAccent.lists, open: open,
                    tick: door == .reusable ? reset : open, filled: door == .reusable, valueText: value)
    }

    /// Reusable: "6 left of 24", or "all done. Reset it for next time". Picks: "12 to pick from, picked Dune on Oct
    /// 18".
    private var value: String {
        if door == .reusable {
            if line.total > 0, line.left == 0 {
                return "all done. Reset it for next time"
            }
            return LandingSentences.leftOf(left: line.left, total: line.total) ?? line.line
        }
        var text = "\(line.left) to pick from"
        if let pick = line.lastPick {
            text += ", picked \(pick.text) on \(pick.on.formatted(.dateTime.month(.abbreviated).day()))"
        }
        return text
    }
}
