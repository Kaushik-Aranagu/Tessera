import SwiftUI
import TesseraCore

/// Lists (screens 9 and 10, lists-9-12.md; first slice, before Core's run, reusable, pick-one and put-away fields).
/// The shelf: LISTS, the context line, then every list by last touched, the newest at Hero 56, the next two at
/// Title 34, the rest at 21, each with its state word under it. Groceries appears once and opens Groceries. A list
/// opens its page: the items as Groceries does them (tap strikes, no checkboxes, no separators), the fold "4 done"
/// (tap to see them, hold to clear), and an Add line whose receipt names the thing first.
struct ListsView: View {
    var body: some View {
        NavigationStack {
            ListsShelfPage()
                .navigationDestination(for: UUID.self) { ListPage(listID: $0) }
                .toolbar(.hidden, for: .navigationBar)
        }
        .environment(\.animateEntrance, true)
    }
}

private struct ListsShelfPage: View {
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
            }
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
            Text(row.state)
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
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @State private var striking: Set<UUID> = []
    @State private var foldOpen = false
    /// The option words under the context line (10.5): unfolded in place by a tap, no sheet.
    @State private var optionsOpen = false
    /// Bumped by a real remove; the haptic lives here because the removed row leaves in the same update. It's
    /// .notNow, the row leaving (Design on #786); UNDO plays its own.
    @State private var removed = 0
    @State private var reset = 0
    @State private var runChanged = 0
    /// The open reset ask after "done" on a reusable list; nil when none.
    @State private var resetAsk: UUID?
    /// Private rows: "Private item" until tapped, masked again on leaving (as Groceries, B11).
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
                        options(list, name: name, reusable: contents.isReusable(list), running: run != nil)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    Text(name)
                        .textRole(.hero)
                        .foregroundStyle(Theme.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, Theme.Spacing.xs)
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
                        ForEach(sections(open), id: \.name) { section in
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                if let title = section.name {
                                    Text(title)
                                        .textRole(.title)
                                        .foregroundStyle(Theme.Colors.ink.opacity(0.85))
                                        .accessibilityAddTraits(.isHeader)
                                }
                                ForEach(section.items) { item in
                                    row(item)
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
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.vertical, Theme.Spacing.l)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !done.isEmpty {
                    fold(done, name: name, reusable: contents.isReusable(list))
                }
            }
            .background { ThemedBackground() }
            .background { EdgeSwipeBack() }
            // A run lights the page: the vermilion seam at the top, as the shop does (10.7).
            .overlay(alignment: .top) {
                if run?.state == .running {
                    ProcessSeam(color: Theme.Colors.live)
                        .ignoresSafeArea(edges: .top)
                        .transition(.opacity)
                }
            }
            .tesseraFeedback(.done, trigger: runChanged)
            .toolbar(.hidden, for: .navigationBar)
            .tesseraFeedback(.notNow, trigger: removed)
            // A cleared run (Design on #806); .done is for finishing.
            .tesseraFeedback(.aisleCleared, trigger: reset)
            .onDisappear { rows.end() }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    rows.end()
                }
            }
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

    /// Whether this list has a run open: rows grow to 64 pt (10.7).
    private var running: Bool {
        model.store.object(id: listID).flatMap {
            ListContents(store: model.store, classes: model.classes).run(of: $0, in: model.engine)
        } != nil
    }

    private func row(_ item: ListContents.Item) -> some View {
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
        .accessibilityHint(shown == ShopTrip.privateLabel ? "Shows it" : "Checks it off")
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
        guard rows.tap(item, lastWeightKg: BodyWeight.lastKg(in: model.store)) == .strike else { return }
        withTesseraAnimation(.smooth(duration: 0.26), reduceMotion: reduceMotion) { _ = striking.insert(item.id) }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 150 : 420))
            _ = try? model.engine.perform(CheckListItem(item: item.id), by: .user)
            striking.remove(item.id)
            model.touch()
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

    /// The fold: "4 done". Tap shows them (a tap on one takes it back out); hold 0.7 s clears them.
    /// The option words, ink words with no shape: Reusable now; Run it, Pick one and Put away arrive with their
    /// engine actions. The on word is ink at full weight, the off word secondary ink.
    private func options(_: ObjectRecord, name: String, reusable: Bool, running: Bool) -> some View {
        HStack(spacing: Theme.Spacing.l) {
            // Run it starts (or picks back up) a run; while one is open the word is Done (10.5, 10.11).
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
            .accessibilityHint(running ? "Finishes the run" : "Runs the list on Now")
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
        }
        .contentShape(Rectangle())
        .onTapGesture { withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { optionsOpen = false } }
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
        runChanged += 1
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
        TessVoice.shared.say(ListsCopy.runDone(name, left: result.output.left), undo: result.record)
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
    private func reset(name: String) {
        guard let record = try? model.engine.perform(ResetList(list: listID, time: AppClock.now), by: .user).record
        else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        withTesseraAnimation(reduceMotion ? Theme.Motion.house : .smooth(duration: 0.48), reduceMotion: reduceMotion) {
            foldOpen = false
            model.touch()
        }
        reset += 1
        TessVoice.shared.say(ListsCopy.reset(name), undo: record)
    }

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
                        .strikethrough()
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
                .textRole(.label)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .frame(minHeight: 44)
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityLabel("Back to \(title)")
    }
}
