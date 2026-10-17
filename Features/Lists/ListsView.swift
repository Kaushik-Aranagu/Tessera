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
    @Environment(\.openHomeLink) private var openLink
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let _ = model.revision
        let shelf = ListsShelf(store: model.store, classes: model.classes,
                               lastWeightKg: BodyWeight.lastKg(in: model.store))
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
                .foregroundStyle(Theme.Colors.inkSecondary)
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
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    BackWord(title: "Lists") { dismiss() }
                    Button {
                        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { optionsOpen.toggle() }
                    } label: {
                        Text(ListsCopy.pageContext(open: open.count, all: open.count + done.count))
                            .font(Theme.voice(size: 21))
                            .foregroundStyle(Theme.Colors.context)
                            .frame(minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityHint(optionsOpen ? "Hides the list's options" : "Shows the list's options")
                    .entrance(0)
                    if optionsOpen, list.id != Groceries.listID {
                        options(list, name: name, reusable: contents.isReusable(list))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    Text(name)
                        .textRole(.hero)
                        .foregroundStyle(Theme.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, Theme.Spacing.xs)
                        .entrance(1)
                    addLine(name)
                        .padding(.top, Theme.Spacing.xl)
                        .entrance(2)
                    VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                        ForEach(Array(sections(open).enumerated()), id: \.offset) { _, section in
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
            .toolbar(.hidden, for: .navigationBar)
            .tesseraFeedback(.notNow, trigger: removed)
            .tesseraFeedback(.done, trigger: reset)
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

    private func row(_ item: ListContents.Item) -> some View {
        let shown = label(item)
        return Button { tap(item) } label: {
            (Text(item.quantity.map { "\($0) " } ?? "").fontWeight(.semibold) + Text(shown))
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(2)
                .textRenderer(StrikeRenderer(progress: striking.contains(item.id) ? 1 : 0, color: Theme.Colors.ink))
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
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
    private func options(_: ObjectRecord, name: String, reusable: Bool) -> some View {
        HStack(spacing: Theme.Spacing.l) {
            Button {
                setReusable(!reusable, name: name)
            } label: {
                Text("Reusable")
                    .textRole(.labelStrong)
                    .textCase(.uppercase)
                    .foregroundStyle(reusable ? Theme.Colors.ink : Theme.Colors.inkSecondary)
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

    /// "Packing, reusable." / "Packing, not reusable." with UNDO 10 s, a change.
    private func setReusable(_ isOn: Bool, name: String) {
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
        guard let record = try? model.engine.perform(ClearDoneItems(list: listID), by: .user).record else { return }
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
