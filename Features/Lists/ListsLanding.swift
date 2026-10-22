import SwiftUI
import TesseraCore

// CLOUD-WRITTEN, NOT COMPILED (see the PR). The Lists landing, design 131 section 2 and 2d, and the build sheet
// product/notes-lists-landing-build-sheet-oct22.md section 2B. Behind Review switch "Landing pages" (Builder B's
// `LandingSwitch`), with `listsLeadByDue` and `listsMargin` as the sheet's own switches (default Off).
//
// Core's `ListsLanding.facts` (Core PR 1) is not on master, so `ListsLandingFacts` below computes the same facts from
// APIs that exist today. List items carry no due date in the catalog, so the "due" forms (T-L3, T-L11, the
// `listsLeadByDue` lead) have no source yet and are not drawn; see the PR.

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

        static func == (lhs: Line, rhs: Line) -> Bool {
            lhs.id == rhs.id && lhs.left == rhs.left && lhs.total == rhs.total && lhs.isRunning == rhs.isRunning
        }

        /// The share done, for the filling line: 0 for an empty list.
        var fraction: Double {
            total > 0 ? Double(total - left) / Double(total) : 0
        }

        /// T-L6 to T-L10: the one short line under a name.
        var line: String {
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

    @MainActor
    static func load(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], engine: ActionEngine?,
                     lastSeen: Date?, margin: Bool) -> ListsLandingFacts
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
                    let shown = AddListItem.shownTitle(item.text, store: store)
                    return (shown, shown != item.text)
                }
            }
            if line.isPickOne {
                line.lastPick = items.compactMap { item in
                    contents.pickedAt(item.object).map { (AddListItem.shownTitle(item.text, store: store), $0) }
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
        // Running first, the newer run first; then by last touched (the shelf's own order).
        lines.sort { lhs, rhs in
            switch (runs[lhs.id], runs[rhs.id]) {
            case let (left?, right?): left > right
            case (.some, nil): true
            case (nil, .some): false
            case (nil, nil): lhs.touched > rhs.touched
            }
        }

        var facts = ListsLandingFacts()
        // The lead: running (newest), else the last touched. A "due soonest" lead waits for a date on items.
        facts.lead = lines.first
        facts.others = Array(lines.dropFirst().prefix(6))
        facts.hasReusable = lines.contains { $0.isReusable }
        facts.hasPicks = lines.contains { $0.isPickOne }

        if margin {
            // T-L12: a reusable list fully done.
            for line in lines where line.isReusable && line.total > 0 && line.left == 0 {
                facts.waiting.append(Margin(id: "reset-\(line.id)", text: "\(line.name) is done.",
                                            word: "Reset it for next time", act: .reset(line.id)))
            }
            // T-L13: items added since last looked.
            for line in lines where line.newCount > 0 {
                let text = line.newSource.map { "\(line.name) has \(line.newCount) new, from \($0)." }
                    ?? "\(line.name) has \(line.newCount) new."
                facts.new.append(Margin(id: "new-\(line.id)", text: text, word: nil, act: .open(line.id)))
            }
        }
        return facts
    }

    /// T-L1 to T-L5 (the due form has no source yet): the subtitle. The key word is the list's name.
    func sentence() -> AccentedSentence {
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

// MARK: - The page

struct ListsLandingPage: View {
    let openList: (UUID) -> Void
    let openDoor: (ListsDoor) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openHomeLink) private var openHomeLink
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var seenAtOpen: Date?
    @State private var ticked = 0

    private var margin: Bool {
        Choice.value("listsMargin", options: ["Off", "On"], default: "Off") == "On"
    }

    var body: some View {
        let _ = model.revision
        let facts = ListsLandingFacts.load(store: model.store, classes: model.classes, engine: model.engine,
                                           lastSeen: seenAtOpen, margin: margin)
        let accent = LandingAccent.lists
        LandingPage(back: (title: "Home", action: { dismiss() }),
                    title: "Lists",
                    sentence: facts.sentence().attributed(accent: accent),
                    accent: accent,
                    waiting: facts.waiting.map(line),
                    new: facts.new.map(line),
                    lead: {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                            if let lead = facts.lead {
                                LeadList(line: lead, accent: accent, open: { open(lead) },
                                         resume: { resume(lead) })
                            }
                            ForEach(facts.others) { other in
                                FillingLine(line: other, accent: accent, open: { open(other) },
                                            tick: { tickNext(other) })
                            }
                        }
                    },
                    doors: doors(facts),
                    action: LandingAction(word: "New list", hint: "Tess makes a list from a few words") {
                        TessVoice.shared.say("Say \"list: films\" and I'll make it.")
                    })
            .background { ThemedBackground() }
            .toolbar(.hidden, for: .navigationBar)
            .tesseraFeedback(.selection, trigger: ticked)
            .onAppear {
                if seenAtOpen == nil {
                    seenAtOpen = LandingSeen.date("lists")
                }
                LandingSeen.mark("lists", at: AppClock.now)
            }
    }

    // MARK: Doors and bands

    private func doors(_ facts: ListsLandingFacts) -> [LandingDoor] {
        guard facts.lead != nil else { return [] }
        var doors = [LandingDoor(word: "Shelf") { openDoor(.shelf) }]
        if facts.hasReusable {
            doors.append(LandingDoor(word: "Reusable") { openDoor(.reusable) })
        }
        if facts.hasPicks {
            doors.append(LandingDoor(word: "Picks") { openDoor(.picks) })
        }
        return doors
    }

    private func line(_ entry: ListsLandingFacts.Margin) -> LandingLine {
        guard let word = entry.word else {
            return LandingLine(text: entry.text, link: (word: "Open", action: { run(entry.act) }))
        }
        return LandingLine(text: entry.text, link: (word: word, action: { run(entry.act) }))
    }

    private func run(_ act: ListsLandingFacts.Margin.Act) {
        switch act {
        case let .open(id): openList(id)
        case let .reset(id): reset(id)
        }
    }

    // MARK: Actions

    /// Tap on the lead's words opens its page (already running when it runs).
    private func open(_ line: ListsLandingFacts.Line) {
        if line.isGroceries {
            openHomeLink(.groceries)
        } else {
            openList(line.id)
        }
    }

    /// Resume opens the running list; on a plain list not yet running it reads "Start" and starts the run first.
    private func resume(_ line: ListsLandingFacts.Line) {
        guard !line.isGroceries, !line.isRunning else { return open(line) }
        var record: OpRecord?
        if let refusal = RecipeCopy.startCook({
            record = try model.engine.perform(StartListRun(list: line.id, time: AppClock.now), by: .user).record
        }) {
            TessVoice.shared.say(refusal)
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        TessVoice.shared.say(ListsCopy.runStarted(line.name, left: line.left), undo: record, holds: .seconds(4))
        openList(line.id)
    }

    /// Swipe right on a line ticks its next open item, with the existing strike haptic and UNDO 10 s on that row.
    private func tickNext(_ line: ListsLandingFacts.Line) {
        let contents = ListContents(store: model.store, classes: model.classes)
        guard let list = model.store.object(id: line.id), let next = contents.open(in: list).first,
              let result = try? model.engine.perform(CheckListItem(item: next.id, time: AppClock.now), by: .user)
        else { return }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        ticked += 1
        if let receipt = result.record.receipt {
            TessVoice.shared.say(receipt, undo: result.record)
        }
    }

    /// "Packing, reset." with UNDO 10 s: every item opens, a new run starts.
    private func reset(_ id: UUID) {
        guard let list = model.store.object(id: id),
              let result = try? model.engine.perform(ResetList(list: id, time: AppClock.now), by: .user)
        else { return }
        let name = ListContents.shownName(of: list, in: model.store)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        TessVoice.shared.say(ListsCopy.reset(name), undo: result.record)
    }
}

// MARK: - The lead list (L3)

/// The lead list: its name large, its next items left as large words, "6 left of 24" small in olive, and Resume.
private struct LeadList: View {
    let line: ListsLandingFacts.Line
    let accent: Color
    let open: () -> Void
    let resume: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Button(action: open) {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text(line.name)
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if !line.nextItems.isEmpty {
                        Text(words)
                            .textRole(.title)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let left = LandingSentences.leftOf(left: line.left, total: line.total) {
                        Text(left)
                            .textRole(.data)
                            .foregroundStyle(accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(spoken)
            .accessibilityHint("Opens the list")
            Button(line.isRunning || line.isGroceries ? "Resume" : "Start", action: resume)
                .buttonStyle(LandingWordStyle())
                .accessibilityLabel(line.isRunning || line.isGroceries ? "Resume, button" : "Start, button")
        }
    }

    /// "Socks, underwear, charger, passport": a private item reads "Private item" at 66% ink.
    private var words: AttributedString {
        var result = AttributedString()
        for (index, item) in line.nextItems.enumerated() {
            var word = AttributedString(item.text)
            word.foregroundColor = Theme.Colors.ink.opacity(item.isPrivate ? 0.66 : 1)
            result += word
            if index < line.nextItems.count - 1 {
                var comma = AttributedString(", ")
                comma.foregroundColor = Theme.Colors.ink
                result += comma
            }
        }
        return result
    }

    private var spoken: String {
        let status = line.isRunning ? "running, " : ""
        let left = LandingSentences.leftOf(left: line.left, total: line.total).map { "\($0): " } ?? ""
        return "\(line.name), \(status)\(left)\(line.nextItems.map(\.text).joined(separator: ", "))"
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

    var body: some View {
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
        .simultaneousGesture(
            DragGesture(minimumDistance: 24).onEnded { drag in
                guard drag.translation.width > 72, abs(drag.translation.width) > abs(drag.translation.height) else {
                    return
                }
                tick()
            }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(line.name), \(line.line)")
        .accessibilityHint("Opens the list")
        .accessibilityAction(named: Text("Check off next")) { tick() }
    }

    private var value: String {
        valueText ?? line.line
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

    /// Reusable: "6 left of 24", or "all done. Reset it for next time". Picks: "12 to pick from, picked Dune on Oct 18".
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
