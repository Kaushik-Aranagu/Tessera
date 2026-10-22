import SwiftUI
import TesseraCore

/// Lists (screens 9 and 10, lists-9-12.md; first slice, before Core's run, reusable, pick-one and put-away fields).
/// The shelf: LISTS, the context line, then every list by last touched, the newest at Hero 56, the next two at
/// Title 34, the rest at 21, each with its state word under it. Groceries appears once and opens Groceries. A list
/// opens its page: the items as Groceries does them (tap strikes, no checkboxes, no separators), the fold "4 done"
/// (tap to see them, hold to clear), and an Add line whose receipt names the thing first.
struct ListsView: View {
    /// A path, so the landing can push a list after starting it (design 131; Review switch "Landing pages").
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            front
                .navigationDestination(for: UUID.self) { ListPage(listID: $0) }
                .navigationDestination(for: PutAwayShelf.self) { _ in PutAwayShelf.Page() }
                .navigationDestination(for: ListsDoor.self) { door in
                    switch door {
                    case .shelf: ListsShelfPage()
                    case .reusable, .picks: ListsKindPage(door: door) { path.append($0) }
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
        }
        .environment(\.animateEntrance, true)
    }
}

extension ListsView {
    /// The landing when "Landing pages" is on, else the shelf as it was.
    @ViewBuilder
    private var front: some View {
        if LandingSwitch.isOn {
            ListsLandingPage(openList: { path.append($0) }, openDoor: { path.append($0) })
        } else {
            ListsShelfPage()
        }
    }
}

struct ListsShelfPage: View {
    @Environment(AppModel.self) private var model
    @State private var spoke = false
    @Environment(\.openHomeLink) private var openLink
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let _ = model.revision
        let shelf = ListsShelf(store: model.store, classes: model.classes,
                               lastWeightKg: BodyWeight.lastKg(in: model.store), engine: model.engine)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BackWord(title: "Kitchen") { dismiss() }
                    .entrance(0)
                Text("Lists")
                    .textRole(.title)
                    .wordFit("Lists")
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .entrance(0)
                Text(shelf.context)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(1)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(shelf.rows.enumerated()), id: \.element.id) { index, row in
                        shelfRow(row)
                            .padding(.top, index == 0 ? 0 : Self.gap(after: shelf.rows[index - 1].tier))
                            .entrance(2 + min(index, 4))
                    }
                }
                .padding(.top, Theme.Spacing.xxl)
                if shelf.rows.allSatisfy(\.isGroceries) {
                    Text("No other lists yet.")
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .padding(.top, Theme.Spacing.xxl)
                }
                // The foot: "Put away" at 21/400, 45%, only once something has been (9.6, 10.12). Never "Archived".
                if shelf.awayCount > 0 {
                    NavigationLink(value: PutAwayShelf()) {
                        Text("Put away")
                            .font(Theme.voice(size: 21))
                            .foregroundStyle(Theme.Colors.ink.opacity(0.45))
                            .frame(minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityLabel("Put away, \(shelf.awayCount)")
                    .accessibilityHint("Lists set aside for later")
                    .padding(.top, Theme.Spacing.xxl)
                }
            }
            // Held to the leading edge, so a short page is never centred (Kaushik, Oct 21).
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.vertical, Theme.Spacing.l)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .onAppear {
            // Once per visit, the running list's fact (13.3); never an item's words.
            guard !spoke, let line = shelf.tess else { return }
            spoke = true
            TessVoice.shared.say(line)
        }
    }

    /// 108 pt after a 56, 80 after a 34, 58 after a 21 (from baseline to baseline, roughly).
    private static func gap(after tier: ListsShelf.Tier) -> CGFloat {
        switch tier {
        case .hero: 44
        case .title: 28
        case .body: 16
        }
    }

    @ViewBuilder
    private func shelfRow(_ row: ListsShelf.Row) -> some View {
        let label = VStack(alignment: .leading, spacing: 8) {
            Text(row.name)
                .textRole(row.tier == .hero ? .hero : row.tier == .title ? .title : .body)
                .fontWeight(.medium)
                .foregroundStyle(Theme.Colors.ink.opacity(row.tier == .body ? 0.75 : 1))
                .multilineTextAlignment(.leading)
            Text(Choice.fontIsNew() ? ListsCopy.sentence(row.state) : row.state)
                .textRole(.label)
                // A run's state word is vermilion, the live colour (9.3).
                .foregroundStyle(row.isRunning ? Theme.Colors.live : Theme.Colors.inkSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)

        if row.isGroceries {
            Button { openLink(.groceries) } label: { label }
                .buttonStyle(HandleButtonStyle())
                .accessibilityHint("Opens Groceries")
        } else {
            NavigationLink(value: row.id) { label }
                .buttonStyle(HandleButtonStyle())
                .accessibilityHint("Opens the list")
        }
    }
}

/// A list page (screen 10, first slice).
private struct ListPage: View {
    let listID: UUID
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @State private var striking: Set<UUID> = []
    @State private var foldOpen = false
    /// The pick moment, while it's up.
    @State private var picking: PickState?
    @State private var picked = 0
    /// The name's underline while the hold fills it (0 to 1).
    @State private var pickHold: CGFloat = 0
    /// The reset's moment: the fold's strikes drain before the items rise back.
    @State private var unpainting = false
    /// The drain's paint: nil at rest (a plain strike at full secondary ink, readable at every size and in dark mode),
    /// 1 → 0 only while a reset drains it (QA on #844).
    @State private var drain: Double?
    /// The option words under the context line (10.5): unfolded in place by a tap, no sheet.
    @State private var optionsOpen = false
    /// Bumped by a real remove; the haptic lives here because the removed row leaves in the same update. It's
    /// .notNow, the row leaving (Design on #786); UNDO plays its own.
    @State private var removed = 0
    @State private var reset = 0
    @State private var runChanged = 0
    @State private var runStarted = 0
    /// The open reset ask after "done" on a reusable list; nil when none.
    @State private var resetAsk: UUID?
    /// NOT NOW on the reset ask: its own trigger for .notNow (Design on #823).
    @State private var notNow = 0
    /// Private rows read "Private item" on every surface; nothing opens them (G102).
    @State private var rows = ShopTrip()
    @FocusState private var writing: Bool

    var body: some View {
        let _ = model.revision
        if let list = model.store.object(id: listID), !list.isDeleted {
            let contents = ListContents(store: model.store, classes: model.classes)
            let open = contents.open(in: list), done = contents.done(in: list)
            let name = ListsShelf.shownName(model.store.displayTitle(of: list),
                                            lastWeightKg: BodyWeight.lastKg(in: model.store))
            let run = contents.run(of: list, in: model.engine)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    BackWord(title: "Lists") { dismiss() }
                    Button {
                        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { optionsOpen.toggle() }
                    } label: {
                        // The visible cue that it opens (Design on #806): a small mark that turns as it unfolds.
                        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                            // A run reads "Packing, running" (10.7).
                            Text(run != nil ? ListsCopy.running(name)
                                : ListsCopy.pageContext(open: open.count, all: open.count + done.count))
                                .font(Theme.voice(size: 21))
                                .foregroundStyle(Theme.Colors.context)
                            Text("›")
                                .font(Theme.voice(size: 21))
                                .foregroundStyle(Theme.Colors.inkSecondary)
                                .rotationEffect(.degrees(optionsOpen ? 90 : 0))
                                .accessibilityHidden(true)
                        }
                        .frame(minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityHint(optionsOpen ? "Hides the list's options" : "Shows the list's options")
                    .entrance(0)
                    if optionsOpen, list.id != Groceries.listID {
                        options(list, name: name, reusable: contents.isReusable(list), running: run != nil,
                                pickOne: contents.isPickOne(list))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    Text(name)
                        .textRole(.hero)
                        .wordFit(name)
                        .foregroundStyle(Theme.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, Theme.Spacing.xs)
                        // Pick one: a 0.6 s hold on the name fills its underline, then one item lifts out (12.1).
                        .overlay(alignment: .bottomLeading) {
                            if contents.isPickOne(list) {
                                GeometryReader { proxy in
                                    Rectangle()
                                        .fill(Theme.Colors.ink)
                                        .frame(width: proxy.size.width * pickHold, height: Theme.Stroke.hairline * 2)
                                        .frame(maxHeight: .infinity, alignment: .bottom)
                                }
                                .accessibilityHidden(true)
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.6) {
                            guard contents.isPickOne(list) else { return }
                            startPick(list)
                        } onPressingChanged: { pressing in
                            guard contents.isPickOne(list) else { return }
                            withTesseraAnimation(pressing ? .linear(duration: 0.6) : .easeOut(duration: 0.15),
                                                 reduceMotion: reduceMotion)
                            {
                                pickHold = pressing ? 1 : 0
                            }
                        }
                        .accessibilityAction(named: "Pick one") {
                            if contents.isPickOne(list) {
                                startPick(list)
                            }
                        }
                        .entrance(1)
                    if resetAsk != nil {
                        resetAskView(name: name)
                            .padding(.top, Theme.Spacing.l)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    addLine(name)
                        .padding(.top, Theme.Spacing.xl)
                        .entrance(2)
                    VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                        // Keyed by name, so a section that finishes folds away rather than the rows shuffling up
                        // (10.7; a removed last row finishes it the same way).
                        // Names are unique here: sections() groups every item of a name into one section, so the
                        // name is a stable key; an index in the key would re-key every later section when one folds.
                        ForEach(sections(open), id: \.name) { section in
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                if let title = section.name {
                                    Text(title)
                                        .textRole(.title)
                                        .wordFit(title)
                                        .foregroundStyle(Theme.Colors.ink.opacity(0.85))
                                        .accessibilityAddTraits(.isHeader)
                                }
                                ForEach(section.items) { item in
                                    row(item, running: run != nil)
                                        .swipeToRemove { remove(item, from: name) }
                                }
                                .padding(.leading, section.name == nil ? 0 : 42)
                            }
                            .transition(reduceMotion ? .opacity
                                : .asymmetric(
                                    insertion: .opacity,
                                    removal: .opacity.combined(with: .scale(scale: 0.96,
                                                                            anchor: .top))
                                ))
                        }
                    }
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(3)
                }
                // Held to the leading edge, so a short page is never centred (QA on #1198).
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.vertical, Theme.Spacing.l)
            }
            .scrollIndicators(.hidden)
            // A tap anywhere outside the option words folds them (10.5), down to the foot of a short list too (QA on
            // #844); rows and words take their own taps first.
            .background {
                if optionsOpen {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { optionsOpen = false
                            }
                        }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !done.isEmpty {
                    fold(done, name: name, reusable: contents.isReusable(list))
                }
            }
            // While a pick is up the page, done fold included, dims to 14% with a 2 pt blur (12.2) and is hidden from
            // VoiceOver (QA on #851); Reduce Motion keeps the dim, drops the blur.
            .opacity(picking == nil ? 1 : 0.14)
            .blur(radius: picking == nil || reduceMotion ? 0 : 2)
            .allowsHitTesting(picking == nil)
            .accessibilityHidden(picking != nil)
            .background { ThemedBackground() }
            .background { EdgeSwipeBack() }
            // The pick moment over the page: the rest dims to 14% with a 2 pt blur (12.2).
            .overlay {
                if picking != nil {
                    PickMoment(listID: listID, picking: $picking, picked: $picked, rows: rows)
                }
            }
            .tesseraFeedback(.pickedUp, trigger: picked)
            // A run lights the page: the vermilion seam at the top, as the shop does (10.7).
            .overlay(alignment: .top) {
                if run?.state == .running {
                    ProcessSeam(color: Theme.Colors.live)
                        .ignoresSafeArea(edges: .top)
                        .transition(.opacity)
                }
            }
            .tesseraFeedback(.done, trigger: runChanged)
            .tesseraFeedback(.made, trigger: runStarted)
            .tesseraFeedback(.notNow, trigger: notNow)
            .toolbar(.hidden, for: .navigationBar)
            .tesseraFeedback(.notNow, trigger: removed)
            // A cleared run (Design on #806); .done is for finishing.
            .tesseraFeedback(.aisleCleared, trigger: reset)
        } else {
            Text("List gone.")
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.context)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background { ThemedBackground() }
        }
    }

    private func sections(_ items: [ListContents.Item]) -> [(name: String?, items: [ListContents.Item])] {
        var order: [String?] = []
        var grouped: [String?: [ListContents.Item]] = [:]
        for item in items {
            if grouped[item.section] == nil {
                order.append(item.section)
            }
            grouped[item.section, default: []].append(item)
        }
        return order.map { ($0, grouped[$0] ?? []) }
    }

    private func label(_ item: ListContents.Item) -> String {
        rows.label(for: item, name: item.text, lastWeightKg: BodyWeight.lastKg(in: model.store))
    }

    /// A row; with a run open it grows to 64 pt (10.7). The run is read once in `body` and passed down (QA on #814).
    private func row(_ item: ListContents.Item, running: Bool) -> some View {
        let shown = label(item)
        return Button { tap(item) } label: {
            (Text(item.quantity.map { "\($0) " } ?? "").fontWeight(.semibold) + Text(shown))
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(2)
                .textRenderer(StrikeRenderer(progress: striking.contains(item.id) ? 1 : 0, color: Theme.Colors.ink))
                .frame(maxWidth: .infinity, minHeight: running ? 64 : 48, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityHint("Checks it off")
    }

    /// "Rice, removed." with UNDO 10 s; UNDO puts it back where it was and says "Rice, back on Packing." A private
    /// row is "Private item" in both (13.8). The rows close up as it goes.
    private func remove(_ item: ListContents.Item, from list: String) -> Bool {
        let thing = rows.maskedLabel(for: item, name: item.text, lastWeightKg: BodyWeight.lastKg(in: model.store))
        guard let record = try? model.engine.perform(DeleteObject(object: item.id), by: .user).record else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return false
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        removed += 1
        TessVoice.shared.say(ListsCopy.removed(thing), takeBack: { [model] in
            model.engine.undo(record)
            model.touch()
            // The band clears its line right after UNDO runs; the back-on line follows it.
            Task { @MainActor in TessVoice.shared.say(ListsCopy.backOn(thing, list: list)) }
        })
        return true
    }

    private func tap(_ item: ListContents.Item) {
        withTesseraAnimation(.smooth(duration: 0.26), reduceMotion: reduceMotion) { _ = striking.insert(item.id) }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 150 : 420))
            _ = try? model.engine.perform(CheckListItem(item: item.id), by: .user)
            // In one animation, so a section whose last row this was folds away (10.7; Kitchen on #823).
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                striking.remove(item.id)
                model.touch()
            }
        }
    }

    private func addLine(_ name: String) -> some View {
        let active = writing || !draft.isEmpty
        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.m) {
                Text("Add")
                    .textRole(.label)
                    .foregroundStyle(active ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                    .accessibilityHidden(true)
                TextField("", text: $draft)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .focused($writing)
                    .submitLabel(.done)
                    .onSubmit(add)
                    .accessibilityLabel("Add to \(name)")
            }
            Rectangle()
                .fill(active ? Theme.Colors.ink : Theme.Colors.hairline)
                .frame(height: Theme.Stroke.hairline)
        }
        .tesseraAnimation(Theme.Motion.house, value: active)
    }

    /// One new line: "Rice, on Packing." with UNDO 4 s; a walled thing reads "Private item, on Packing."
    private func add() {
        guard let list = model.store.object(id: listID) else { return }
        let attempt = ListsCopy.add(draft) { text in
            try? model.engine.perform(AddListItem(list: listID, text: text), by: .user).record
        }
        draft = attempt.draft
        if let line = attempt.line {
            TessVoice.shared.say(line)
        }
        guard let record = attempt.record else { return }
        model.touch()
        let title = model.store.displayTitle(of: list)
        let shown = ListsShelf.shownName(title, lastWeightKg: BodyWeight.lastKg(in: model.store))
        guard let receipt = record.receipt else { return }
        TessVoice.shared.say(ListsCopy.spoken(receipt: receipt, listTitle: title, shownList: shown), undo: record,
                             holds: .seconds(4))
    }
}

// MARK: - The option words, runs, the reset and the fold

/// Out of `ListPage`'s body so the type stays inside swiftlint's type_body_length (the release build needs it clean).
extension ListPage {
    /// The option words, ink words with no shape: Run it (or Done and Put away while running), Reusable and Pick one.
    /// The on word is ink at full weight, the off word secondary ink; each says its state in words.
    private func options(_ list: ObjectRecord, name: String, reusable: Bool, running: Bool,
                         pickOne: Bool) -> some View
    {
        // The words wrap to a second line rather than squeeze (four of them at larger sizes).
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.Spacing.l) { optionWords(list, name: name, reusable: reusable, running: running,
                                                           pickOne: pickOne) }
            VStack(alignment: .leading, spacing: 0) { optionWords(list, name: name, reusable: reusable,
                                                                  running: running, pickOne: pickOne) }
        }
        .contentShape(Rectangle())
        .onTapGesture { withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { optionsOpen = false } }
    }

    @ViewBuilder
    private func optionWords(_: ObjectRecord, name: String, reusable: Bool, running: Bool,
                             pickOne: Bool) -> some View
    {
        Button {
            running ? finishRun(name: name) : startRun(name: name)
        } label: {
            Text(running ? "Done" : "Run it")
                .textRole(.labelStrong)
                .textCase(.uppercase)
                .foregroundStyle(running ? Theme.Colors.live : Theme.Colors.ink)
                .contentTransition(.opacity)
                .frame(minHeight: 44)
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityHint(running ? "Finishes the run" : "Runs the list")
        if running {
            Button { putAwayRun(name: name) } label: {
                Text("Put away")
                    .textRole(.labelStrong)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(minHeight: 44)
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityHint("Sets the run aside for later")
        }
        Button {
            setReusable(!reusable, was: reusable, name: name)
        } label: {
            // The state in words, not colour alone (Design on #806).
            Text(ListsCopy.reusableWord(isOn: reusable))
                .textRole(.labelStrong)
                .textCase(.uppercase)
                .foregroundStyle(reusable ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                .contentTransition(.opacity)
                .frame(minHeight: 44)
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityLabel("Reusable")
        .accessibilityValue(reusable ? "On" : "Off")
        .accessibilityHint(reusable ? "Done items stay, to reset" : "Keeps its items for next time")
        Button {
            setPickOne(!pickOne, name: name)
        } label: {
            Text(ListsCopy.pickOneWord(isOn: pickOne))
                .textRole(.labelStrong)
                .textCase(.uppercase)
                .foregroundStyle(pickOne ? Theme.Colors.ink : Theme.Colors.inkSecondary)
                .contentTransition(.opacity)
                .frame(minHeight: 44)
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityLabel("Pick one")
        .accessibilityValue(pickOne ? "On" : "Off")
        .accessibilityHint(pickOne ? "Hold the name to pick an item" : "Lets the list pick an item for you")
    }

    /// "Films, pick one on." with UNDO 10 s.
    private func setPickOne(_ isOn: Bool, name: String) {
        guard let list = model.store.object(id: listID),
              ListContents(store: model.store, classes: model.classes).isPickOne(list) != isOn else { return }
        guard let record = try? model.engine.perform(SetListPickOne(list: listID, on: isOn), by: .user).record
        else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        TessVoice.shared.say(ListsCopy.pickOne(name, isOn: isOn), undo: record)
    }

    /// The pick moment (12.2 to 12.5): the page dims, one open item lifts out to the centre.
    private func startPick(_ list: ObjectRecord) {
        pickHold = 0
        let contents = ListContents(store: model.store, classes: model.classes)
        let first = contents.pick(from: list, now: AppClock.now)
        withTesseraAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.52, bounce: 0.18),
                             reduceMotion: reduceMotion)
        {
            picking = PickState(item: first, skipped: [])
        }
        picked += 1
    }

    /// "Packing, 6 left." with UNDO 4 s, a new run; the page lights (10.7). While a workout runs the engine refuses:
    /// "Workout running." and nothing starts (G56).
    private func startRun(name: String) {
        var record: OpRecord?
        if let refusal = RecipeCopy.startCook({
            record = try model.engine.perform(StartListRun(list: listID, time: AppClock.now), by: .user).record
        }) {
            TessVoice.shared.say(refusal)
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            optionsOpen = false
            model.touch()
        }
        // A run starting is a thing landing (Design on #814); only Done plays .done.
        runStarted += 1
        let left = model.store.object(id: listID).map { ListContents(store: model.store, classes: model.classes)
            .open(in: $0).count
        } ?? 0
        TessVoice.shared.say(ListsCopy.runStarted(name, left: left), undo: record, holds: .seconds(4))
    }

    /// "Packing, done." (or "… done. 3 left") with UNDO 10 s. A plain list loses its checked items; a reusable list
    /// keeps every strike for the reset hold (10.11).
    private func finishRun(name: String) {
        guard let result = try? model.engine.perform(FinishListRun(list: listID, time: AppClock.now), by: .user)
        else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            optionsOpen = false
            model.touch()
        }
        runChanged += 1
        // A reusable list keeps its strikes and asks (10.11): RESET is a hold, NOT NOW or 10 s of quiet changes
        // nothing. A plain list says its receipt with UNDO.
        let checked = model.store.object(id: listID).map {
            ListContents(store: model.store, classes: model.classes).done(in: $0).count
        } ?? 0
        if result.output.wasReusable, checked > 0 {
            let ask = UUID()
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { resetAsk = ask }
            Task { @MainActor in
                try? await Task.sleep(for: TessVoice.hold(undo: true, holds: .seconds(10)))
                if resetAsk == ask {
                    withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { resetAsk = nil }
                }
            }
            return
        }
        // A plain list with everything done is put away, rows kept (G9): back to the shelf, where it sinks to the foot.
        if result.output.putAway {
            TessVoice.shared.say(ListsCopy.putAway(name, basket: 0), undo: result.record)
            dismiss()
            return
        }
        TessVoice.shared.say(ListsCopy.runDone(name, left: result.output.left), undo: result.record)
    }

    /// The Put away option word: the run goes to Later with its basket, "Packing put away. 3 in the basket." with
    /// UNDO 10 s; running it again brings it back.
    private func putAwayRun(name: String) {
        guard let result = try? model.engine.perform(PutAwayListRun(list: listID, time: AppClock.now), by: .user)
        else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            optionsOpen = false
            model.touch()
        }
        TessVoice.shared.say(ListsCopy.putAway(name, basket: result.output), undo: result.record)
        dismiss()
    }

    /// "Packing, done. Reset it for next time?" with RESET (a 0.7 s hold, the ink line filling) and NOT NOW (10.11).
    private func resetAskView(name: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text(ListsCopy.resetAsk(name))
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.tess)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Theme.Spacing.l) {
                PaintKey(paint: Theme.Colors.ink, duration: 0.7, hint: "Unchecks everything for next time",
                         action: {
                             withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { resetAsk = nil }
                             reset(name: name)
                         }, label: { _ in Text("Reset").textRole(.labelStrong) }, meta: { Text("Hold") })
                    .frame(maxWidth: 220)
                Button("Not now") {
                    withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { resetAsk = nil }
                    notNow += 1
                }
                .buttonStyle(.labelWord)
                .frame(minHeight: 44)
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// "Packing, reusable." / "Packing, not reusable." with UNDO 10 s, a change.
    private func setReusable(_ isOn: Bool, was: Bool, name: String) {
        // A fast double tap sends the same value twice; the second is ignored, never "Didn't save" (QA on #806).
        let now = ListContents(store: model.store, classes: model.classes)
        guard let list = model.store.object(id: listID), now.isReusable(list) == was else { return }
        guard let record = try? model.engine.perform(SetListReusable(list: listID, reusable: isOn), by: .user).record
        else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        TessVoice.shared.say(ListsCopy.reusable(name, isOn: isOn), undo: record)
    }

    /// Hold on a reusable list's fold: every item comes back unchecked, "Packing, reset." with UNDO 10 s (10.4).
    /// The strikes un-paint right to left and the items rise back (10.4). Nothing checked (strikes taken back while
    /// the ask was open, or an empty list): "Packing, nothing to reset." with no UNDO (Kitchen on #823).
    private func reset(name: String) {
        let checked = model.store.object(id: listID).map {
            ListContents(store: model.store, classes: model.classes).done(in: $0).count
        } ?? 0
        guard checked > 0 else {
            TessVoice.shared.say(ListsCopy.nothingToReset(name))
            return
        }
        // One reset at a time: a second call during the drain would reset again with an UNDO that restores nothing.
        guard !unpainting else { return }
        unpainting = true
        foldOpen = true
        drain = 1
        Task { @MainActor in
            withTesseraAnimation(
                reduceMotion ? Theme.Motion.house : .easeInOut(duration: 0.36),
                reduceMotion: reduceMotion
            ) { drain = 0 }
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 380))
            unpainting = false
            drain = nil
            guard let record = try? model.engine.perform(ResetList(list: listID, time: AppClock.now), by: .user)
                .record
            else {
                TessVoice.shared.say("Didn't save that. Try again.")
                return
            }
            withTesseraAnimation(reduceMotion ? Theme.Motion.house : .smooth(duration: 0.48),
                                 reduceMotion: reduceMotion)
            {
                foldOpen = false
                model.touch()
            }
            reset += 1
            TessVoice.shared.say(ListsCopy.reset(name), undo: record)
        }
    }

    /// The fold: "4 done". Tap shows them (a tap on one takes it back out); hold 0.7 s clears them.
    private func fold(_ done: [ListContents.Item], name: String, reusable: Bool) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            if foldOpen {
                ForEach(done) { item in
                    Button {
                        _ = try? model.engine.perform(CheckListItem(item: item.id, done: false), by: .user)
                        model.touch()
                    } label: {
                        Text(rows.maskedLabel(
                            for: item,
                            name: item.text,
                            lastWeightKg: BodyWeight.lastKg(in: model.store)
                        ))
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        // The strike as paint, so a reset drains it right to left (10.4).
                        .modifier(FoldStrike(drain: drain))
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityHint("Takes it back out")
                }
            }
            // A reusable list's fold resets rather than clears: "4 done. Hold to reset." (10.4).
            (Text("\(done.count)").fontWeight(.semibold) + Text(reusable ? " done. Hold to reset." : " done"))
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .contentTransition(.numericText(value: Double(done.count)))
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { withTesseraAnimation(reduceMotion: reduceMotion) { foldOpen.toggle() } }
                .onLongPressGesture(minimumDuration: 0.7) { reusable ? reset(name: name) : clear(done.count) }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(reusable ? "Shows them; hold to reset the list" : "Shows them; hold to clear them")
                .accessibilityAction(named: reusable ? "Reset the list" : "Clear them") {
                    reusable ? reset(name: name) : clear(done.count)
                }
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .padding(.bottom, Theme.Spacing.m)
        .background { ThemedBackground() }
    }

    private func clear(_ count: Int) {
        guard let record = try? model.engine.perform(ClearDoneItems(list: listID), by: .user).record else {
            // A refused clear says so; the fold and its items stay (QA on #806).
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        model.touch()
        foldOpen = false
        // A change, so UNDO keeps 10 s (Design on #760).
        TessVoice.shared.say(ListsCopy.cleared(count), undo: record)
    }
}

/// The back word at the top of a page ("‹ KITCHEN", "‹ LISTS"): with the bar hidden, VoiceOver and Switch Control need
/// a way back (QA on #760).
struct BackWord: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("‹ \(title)")
                .textRole(.keyWord)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(minHeight: 44)
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityLabel("Back to \(title)")
    }
}

/// The lists put away (G9, 9.6): plain names, newest first; one opens its page, and running it again brings it back.
struct PutAwayShelf: Hashable {
    struct Page: View {
        @Environment(AppModel.self) private var model
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            let _ = model.revision
            let away = ListContents(store: model.store, classes: model.classes).putAway()
            let last = BodyWeight.lastKg(in: model.store)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    BackWord(title: "Lists") { dismiss() }
                    Text("Put away")
                        .textRole(.title)
                        .wordFit("Put away")
                        .foregroundStyle(Theme.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        ForEach(away, id: \.id) { list in
                            NavigationLink(value: list.id) {
                                Text(ListsShelf.shownName(model.store.displayTitle(of: list), lastWeightKg: last))
                                    .textRole(.body)
                                    .foregroundStyle(Theme.Colors.ink.opacity(0.75))
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            }
                            .buttonStyle(HandleButtonStyle())
                            .accessibilityHint("Opens the list")
                        }
                    }
                    .padding(.top, Theme.Spacing.xl)
                }
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.vertical, Theme.Spacing.l)
            }
            .scrollIndicators(.hidden)
            .background { ThemedBackground() }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

/// A done item's strike in the fold: a plain strike at rest; the drain's paint only while a reset un-paints it.
private struct FoldStrike: ViewModifier {
    let drain: Double?

    func body(content: Content) -> some View {
        if let drain {
            content.textRenderer(FoldDrainRenderer(progress: drain, color: Theme.Colors.inkSecondary))
        } else {
            content.strikethrough()
        }
    }
}

/// One pick moment: the item lifted out (nil after the last skip, or between two picks), and what was skipped.
struct PickState: Equatable {
    var item: ListContents.Item?
    var skipped: Set<UUID>
    var between = false
}

/// The fold's drain: the text stays at full ink the whole time (no dim flash as it starts; Design on #848) while the
/// strike line shortens right to left as `progress` goes 1 → 0.
private struct FoldDrainRenderer: TextRenderer, Animatable {
    var progress: Double
    var color: Color

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            context.draw(line)
        }
        guard progress > 0 else { return }
        for line in layout {
            let bounds = line.typographicBounds.rect
            let midY = bounds.minY + bounds.height * 0.55
            var path = Path()
            path.move(to: CGPoint(x: bounds.minX, y: midY))
            path.addLine(to: CGPoint(x: bounds.minX + bounds.width * progress, y: midY))
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
    }
}
