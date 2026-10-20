import SwiftUI
import TesseraCore

/// Dinners, the week page (sheet 104 section 3, sheet 114 section 1), behind the Review switch Week strip. Title,
/// "week of Oct 19", then seven rows Monday to Sunday: the day word at 16, the dinner at 21 (or "Nothing planned" in
/// secondary ink). A list, not a calendar grid; no band, no image. A tap opens the day in place with its choices as ink
/// words: his recent dinners, then the rest. A planned day shows what it is short of and the word to put that on
/// Groceries; nothing goes on until he taps (WD-S2). The one key at the foot adds the whole week. THE WEEK'S SHOP
/// closes the page: counts per aisle, never a list of names.
struct DinnersView: View {
    var body: some View {
        NavigationStack {
            DinnersPage()
        }
        .environment(\.animateEntrance, true)
    }
}

private struct DinnersPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @State private var open: Date?
    @State private var added = 0
    @State private var picked = 0

    var body: some View {
        let _ = model.revision
        let week = WeekOfDinners(store: model.store, classes: model.classes, now: AppClock.now)
        let states = PantryLedger(store: model.store, classes: model.classes).states()
        let skipIn = KitchenSwitch.pantryState
        let missing = week.days.compactMap(\.plan).filter { !$0.isDone }.reduce(into: [UUID: [DinnerShop.Need]]()) {
            guard let recipe = model.store.object(id: $1.recipe) else { return }
            $0[$1.task] = DinnerShop.missing(
                DinnerShop.needs(of: recipe, store: model.store, classes: model.classes, states: states),
                skipIn: skipIn
            )
        }
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BackWord(title: "Kitchen") { dismiss() }
                    .entrance(0)
                Text("Dinners")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .entrance(0)
                Text(week.context)
                    .textRole(.label)
                    .foregroundStyle(Theme.Colors.context)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(1)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(week.days) { day in
                        DinnerRow(day: day, short: day.plan.flatMap { missing[$0.task] }?.count ?? 0,
                                  isOpen: open == day.id,
                                  toggle: {
                                      withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                                          open = open == day.id ? nil : day.id
                                      }
                                  },
                                  choices: open == day.id
                                      ? WeekOfDinners.choices(store: model.store, classes: model.classes) : [],
                                  pick: { pick($0, on: day) },
                                  clear: { day.plan.map(clear) },
                                  shop: { day.plan.map { shop([$0], receiptName: $0.name) } })
                    }
                }
                .padding(.top, Theme.Spacing.xl)
                .entrance(2)

                let planned = week.days.compactMap(\.plan).filter { !$0.isDone }
                if !planned.isEmpty {
                    Button("Add the week to Groceries") { shop(planned, receiptName: "Week") }
                        .buttonStyle(.labelWord(Theme.Colors.ink))
                        .frame(minHeight: 44)
                        .padding(.top, Theme.Spacing.l)
                        .accessibilityHint("Puts what the planned dinners are short of on Groceries")
                        .entrance(3)
                }

                WeekShop(lines: DinnerShop.byAisle(planned.flatMap { missing[$0.task] ?? [] }))
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(3)
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.vertical, Theme.Spacing.l)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .toolbar(.hidden, for: .navigationBar)
        .tesseraFeedback(.made, trigger: added)
        .tesseraFeedback(.selection, trigger: picked)
    }

    /// A pick sets the day's dinner: a plan, as "cook tacos thu" makes it, at 7 pm. Groceries is untouched.
    private func pick(_ recipe: ObjectRecord, on day: WeekOfDinners.Day) {
        var records: [OpRecord] = []
        do {
            if let plan = day.plan {
                try records.append(model.engine.perform(DeleteObject(object: plan.task), by: .user).record)
            }
            try records.append(model.engine.perform(
                CreateTask(title: WeekOfDinners.taskTitle(for: recipe, store: model.store, classes: model.classes),
                           startsAt: WeekOfDinners.dinnerTime(on: day.id), about: [recipe.id]),
                by: .user
            ).record)
        } catch {
            undo(records)
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        let name = ObjectPrivacy.label(of: recipe, in: model.store, classes: model.classes) ?? recipe.title
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            open = nil
            model.touch()
        }
        picked += 1
        TessVoice.shared.say("\(name), \(TesseraDay.weekdayName(of: day.id, calendar: .current)).",
                             takeBack: { undo(records) })
    }

    private func clear(_ plan: WeekOfDinners.Plan) {
        guard let record = try? model.engine.perform(DeleteObject(object: plan.task), by: .user).record else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            open = nil
            model.touch()
        }
        TessVoice.shared.say("\(plan.name), off the week.", takeBack: { undo([record]) })
    }

    /// The add, on his tap only: each plan's missing lines onto Groceries, one receipt and one UNDO for all of it
    /// ("Week, 5 added.", 4 s: a new add).
    private func shop(_ plans: [WeekOfDinners.Plan], receiptName: String) {
        let states = PantryLedger(store: model.store, classes: model.classes).states()
        var records: [OpRecord] = []
        var count = 0
        do {
            for plan in plans where !plan.isDone {
                guard let recipe = model.store.object(id: plan.recipe) else { continue }
                let needs = DinnerShop.needs(of: recipe, store: model.store, classes: model.classes, states: states)
                switch DinnerShop.add(needs, skipIn: KitchenSwitch.pantryState, isPrivate: plan.isPrivate) {
                case .nothing:
                    continue
                case .recipe:
                    let result = try model.engine.perform(AddRecipeToGroceries(recipe: plan.recipe), by: .user)
                    count += result.output.added.count
                    if !result.record.ops.isEmpty {
                        records.append(result.record)
                    }
                case let .lines(lines):
                    let result = try model.engine.perform(AddGroceries(lines: lines), by: .user)
                    count += result.output.count
                    records.append(result.record)
                }
            }
        } catch {
            undo(records)
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        let line = DinnerShop.receipt(receiptName, added: count)
        guard !records.isEmpty else {
            TessVoice.shared.say(line)
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        added += 1
        TessVoice.shared.say(line, holds: .seconds(4), takeBack: { undo(records) })
    }

    private func undo(_ records: [OpRecord]) {
        for record in records.reversed() {
            model.engine.undo(record)
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
    }
}

/// One day: the day word, the dinner (struck when cooked), and at the right what it is short of. Open, the choices
/// sit under it as ink words.
private struct DinnerRow: View {
    let day: WeekOfDinners.Day
    let short: Int
    let isOpen: Bool
    let toggle: () -> Void
    let choices: [ObjectRecord]
    let pick: (ObjectRecord) -> Void
    let clear: () -> Void
    let shop: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: toggle) {
                let layout = typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.xs))
                    : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.m))
                layout {
                    Text(day.word)
                        .textRole(.label)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(minWidth: typeSize.isAccessibilitySize ? nil : 48, alignment: .leading)
                    if let plan = day.plan {
                        Text(plan.name)
                            .textRole(.body)
                            .strikethrough(plan.isDone)
                            .foregroundStyle(plan.isDone ? Theme.Colors.inkSecondary : Theme.Colors.ink)
                            .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                    } else {
                        Text("Nothing planned")
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                    }
                    if !typeSize.isAccessibilitySize {
                        Spacer(minLength: Theme.Spacing.m)
                    }
                    if day.plan?.isDone == false, short > 0 {
                        Text("\(short) to get")
                            .textRole(.label)
                            .monospacedDigit()
                            .foregroundStyle(Theme.Colors.ink)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityHint(isOpen ? "Closes the day" : "Opens the day to pick a dinner")
            .accessibilityAddTraits(.isHeader)

            if isOpen {
                VStack(alignment: .leading, spacing: 0) {
                    if let plan = day.plan, !plan.isDone, short > 0 {
                        Button("Add \(short) to Groceries", action: shop)
                            .buttonStyle(.labelWord(Theme.Colors.ink))
                            .frame(minHeight: 44)
                    }
                    ForEach(choices.filter { $0.id != day.plan?.recipe }, id: \.id) { recipe in
                        let name = ObjectPrivacy.label(of: recipe, in: model.store, classes: model.classes)
                            ?? recipe.title
                        Button(name) { pick(recipe) }
                            .buttonStyle(.labelWord(Theme.Colors.ink))
                            .frame(minHeight: 44)
                            .accessibilityHint("Sets \(day.word) to \(name)")
                    }
                    if choices.isEmpty {
                        Text("No recipes yet.")
                            .font(Theme.voice)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                    }
                    if day.plan != nil {
                        Button("Nothing planned", action: clear)
                            .buttonStyle(.labelWord(Theme.Colors.inkSecondary))
                            .frame(minHeight: 44)
                            .accessibilityHint("Takes the dinner off this day")
                    }
                }
                .padding(.leading, typeSize.isAccessibilitySize ? 0 : 48 + Theme.Spacing.m)
                .padding(.bottom, Theme.Spacing.s)
                .transition(.opacity)
            }
        }
    }

    private var label: String {
        let full = TesseraDay.weekdayName(of: day.id, calendar: .current)
        guard let plan = day.plan else { return "\(full), nothing planned" }
        let done = plan.isDone ? ", cooked" : ""
        let shortWords = !plan.isDone && short > 0 ? ", \(short) to get" : ""
        return "\(full), \(plan.name)\(done)\(shortWords)"
    }
}

/// THE WEEK'S SHOP: what the planned dinners are short of, by aisle, counts only (sheet 104). "Nothing to buy."
private struct WeekShop: View {
    let lines: [(aisle: String, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("The week's shop")
                .textRole(.labelStrong)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Colors.areaLean(.kitchen))
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, Theme.Spacing.xs)
            if lines.isEmpty {
                Text("Nothing to buy.")
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
            ForEach(lines, id: \.aisle) { line in
                HStack(alignment: .firstTextBaseline) {
                    Text(line.aisle)
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.ink)
                    Spacer(minLength: Theme.Spacing.m)
                    Text("\(line.count)")
                        .textRole(.body)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Colors.ink)
                }
                .frame(minHeight: 40)
                .accessibilityElement(children: .combine)
            }
        }
    }
}
