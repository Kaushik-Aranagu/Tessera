import SwiftUI
import TesseraCore

// The Purse (Money) landing (landing contract v2): the index system in the keystone slot (PurseChart.swift), no
// amount anywhere on the page; the categories on the dial; one line about the last spend; "Log" at the foot. Money
// stays on this page: nothing here reaches Home, a widget, a log or Claude, and an undo reads "Reversed".
// There is no Bills, Subscriptions, Income or Savings model in Core yet, so the wall holds spend categories only and
// those doors say so when opened.

// MARK: - Facts

/// What the Money landing shows, as data, so the no-amounts and privacy rules have tests. Words only: categories,
/// counts of spends and days. Never a figure of money.
struct MoneyWall: Equatable {
    var words: [WallWord] = []
    /// The header line, longest form first (FitLine).
    var stateLine: [String] = []
    /// Spends this month (a count, never a sum).
    var monthCount = 0
    /// Categories that are walled words, counted, never named.
    var hidden = 0
    /// The newest spend's category ("lunch"), or nil when it is walled or there is none.
    var lastCategory: String?
    var lastAt: Date?
    var lastIsPrivate = false
    /// The categories by use, for the dial's facts.
    var top: [String] = []

    static let maxWords = 14

    struct Spend: Equatable {
        let category: String
        let at: Date
        let isPrivate: Bool
    }

    /// `spends` newest first, from the last three months; `monthCount` is this month's count; `trend` is Core's
    /// clause sentence ("October is running a little under September."), which never holds a figure.
    static func build(spends: [Spend], monthCount: Int, monthName: String, trend: String?) -> MoneyWall {
        var wall = MoneyWall()
        wall.monthCount = monthCount
        var uses: [String: (count: Int, newest: Date)] = [:]
        var walled: Set<String> = []
        for spend in spends {
            let key = spend.category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !Self.looksLikeAmount(key) else { continue }
            if spend.isPrivate {
                walled.insert(key)
                continue
            }
            let old = uses[key]
            uses[key] = ((old?.count ?? 0) + 1, max(old?.newest ?? .distantPast, spend.at))
        }
        wall.hidden = walled.count
        // Ranked by how often and how lately, never by how much.
        let ranked = uses.sorted { lhs, rhs in
            lhs.value.count != rhs.value.count ? lhs.value.count > rhs.value.count : lhs.value.newest > rhs.value.newest
        }
        let most = Double(ranked.first?.value.count ?? 1)
        wall.words = ranked.prefix(maxWords).enumerated().map { index, entry in
            WallWord(id: "category:\(entry.key)", text: NotesLandingPage.short(entry.key.capitalized),
                     weight: max(0.15, 0.5 * Double(entry.value.count) / most + 0.5 * (1 - Double(index) / 14)))
        }
        wall.top = ranked.prefix(3).map(\.key.capitalized)
        if let newest = spends.first {
            wall.lastAt = newest.at
            wall.lastIsPrivate = newest.isPrivate
            let key = newest.category.trimmingCharacters(in: .whitespacesAndNewlines)
            wall.lastCategory = newest.isPrivate || key.isEmpty || looksLikeAmount(key) ? nil : key.lowercased()
        }
        wall.stateLine = stateLine(monthCount: monthCount, monthName: monthName, trend: trend)
        return wall
    }

    /// "October is running a little under September, 12 spends so far." / the trend alone / "12 spends in October."
    /// / "12 spends." Nothing logged this month: "Nothing yet".
    static func stateLine(monthCount: Int, monthName: String, trend: String?) -> [String] {
        guard monthCount > 0 else { return ["Nothing yet"] }
        let spends = monthCount == 1 ? "1 spend" : "\(monthCount) spends"
        var forms: [String] = []
        if let trend {
            let bare = trend.hasSuffix(".") ? String(trend.dropLast()) : trend
            forms.append("\(bare), \(spends) so far.")
            forms.append(trend)
        }
        forms.append("\(spends) in \(monthName).")
        forms.append("\(spends).")
        return forms
    }

    /// A category that is itself a figure ("12.40") is never shown: the wall holds no amounts.
    static func looksLikeAmount(_ word: String) -> Bool {
        word.contains { $0.isNumber } || word.contains { "$€£₹¥".contains($0) }
    }
}

// MARK: - The page

struct MoneyLandingView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var category = 0
    @State private var index = 0
    @State private var adding = false
    @State private var draft = ""
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let _ = model.revision
        let wall = load()
        let categories = PurseBook(model: model, now: AppClock.now).categories()
        LandingFrame(title: "Purse", accent: LandingAccent.money, stateLine: wall.stateLine, stateSize: 26,
                     doorsTop: 540,
                     keystone: {
                         LandingKeystone(label: "You are the stock") {
                             PurseIndexView(categories: categories, category: $category, index: $index)
                         }
                     },
                     doors: doors(categories), focus: $category,
                     openDoor: { door in
                         TessVoice.shared.say("\(door.name) opens with the full chart soon.")
                     },
                     caption: typeSize.isAccessibilitySize ? [] : [caption(wall)],
                     briefTop: 424,
                     brief: { LandingBrief(forms: brief(wall)) },
                     action: LandingFootAction(word: "Log", hint: "Logs a spend, like 12.40 lunch") {
                         draft = ""
                         adding = true
                     },
                     onBack: { dismiss() })
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: category) { _, _ in index = 0 }
            .alert("Log a spend", isPresented: $adding) {
                TextField("12.40 lunch", text: $draft)
                    .keyboardType(.numbersAndPunctuation)
                Button("Log") { log() }
                Button("Cancel", role: .cancel) {}
            }
    }

    // MARK: Facts

    private func load() -> MoneyWall {
        let now = AppClock.now
        let calendar = Calendar.current
        let ledger = SpendLedger(store: model.store, classes: model.classes)
        var spends: [SpendLedger.Entry] = []
        for back in 0 ..< 3 {
            guard let month = calendar.date(byAdding: .month, value: -back, to: now) else { continue }
            spends += ledger.entries(inMonthOf: month, calendar: calendar)
        }
        let monthCount = ledger.entries(inMonthOf: now, calendar: calendar).count
        let shown = spends.sorted { $0.spentAt > $1.spentAt }.map { entry in
            MoneyWall.Spend(category: entry.category, at: entry.spentAt,
                            isPrivate: ObjectPrivacy.isPrivateWord(entry.category, in: model.store))
        }
        let monthName = now.formatted(Date.FormatStyle().locale(Locale(identifier: "en_US")).month(.wide))
        let trend = MoneyTrend(store: model.store, classes: model.classes).compare(now: now, calendar: calendar)
        let sentence = trend.map { LandingSentences.money(nothingLate: false, due: nil, trend: $0.clause).text }
        return MoneyWall.build(spends: shown, monthCount: monthCount, monthName: monthName, trend: sentence)
    }

    /// The categories are the doors too (contract v2 §12): turning the dial turns the chart, and the other way round.
    private func doors(_ categories: [PurseCategory]) -> [DialDoor] {
        categories.map { item in
            DialDoor(id: item.id, name: item.name, color: item.indices.isEmpty ? Theme.Colors.ink : LandingAccent.money,
                     label: item.indices.isEmpty ? "Not set up yet" : "Indices",
                     lines: Array(item.indices.prefix(4).map(\.name.capitalized)))
        }
    }

    /// The chart in words, never a figure: "Heading down at this pace." / "Nothing yet".
    private func caption(_ wall: MoneyWall) -> String {
        wall.monthCount == 0 ? "Nothing yet" : "The dashed line is where this pace ends the month."
    }

    private func brief(_ wall: MoneyWall) -> [LandingBrief.Form] {
        guard let at = wall.lastAt else { return [] }
        let raw = NotesCopy.when(at, now: AppClock.now)
        let when = raw == "now" ? "just now" : raw
        if let category = wall.lastCategory {
            return [LandingBrief.Form(text: "You last spent on \(category), \(when).", key: category),
                    LandingBrief.Form(text: "Last spend: \(category).", key: category)]
        }
        return [LandingBrief.Form(text: wall.lastIsPrivate ? "You last logged a private spend, \(when)."
                    : "You last logged a spend, \(when)."),
        LandingBrief.Form(text: "Last spend, \(when).")]
    }

    // MARK: Adding

    /// "12.40 lunch": the amount first, then what it was for. The receipt names the category only, never the amount,
    /// and Undo reads "Reversed".
    private func log() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        draft = ""
        guard !text.isEmpty else { return }
        if looksLikeClaudeKey(text) {
            TessVoice.shared.say(claudeKeyLine)
            return
        }
        guard let amount = MoneyAmount.parse(text) else {
            TessVoice.shared.say("Start with the amount, like 12.40 lunch.")
            return
        }
        let note = MoneyAmount.note(after: text)
        let pools = ReviewChoices.shared.value(of: "moneyPools") == "On"
        guard let result = try? model.engine.perform(
            LogSpend(amount: NSDecimalNumber(decimal: amount.amount).doubleValue, typed: amount.typed,
                     currency: amount.currency, note: note.isEmpty ? nil : note, spentAt: AppClock.now,
                     autoPool: pools ? true : nil),
            by: .user
        ) else {
            TessVoice.shared.say("Didn't log that. Try again.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        let word = note.split(separator: " ").first.map { String($0).capitalized }
        let shown = word.map { ObjectPrivacy.isPrivateWord($0, in: model.store) ? "Private spend" : $0 } ?? "Spend"
        TessVoice.shared.say("\(shown), logged.", undo: result.record)
    }
}

// MARK: - The indices

/// Reads the ledger into the Purse's categories and indices (279): MONTH and SPEND under This month, a flow per kind
/// under Kinds. Saving, Investing, Debts and Mine wait for their models. One currency is drawn (the month's most used);
/// a figure never leaves as text.
@MainActor
struct PurseBook {
    let model: AppModel
    let now: Date
    var calendar = Calendar.current

    static let names = ["This month", "Kinds", "Saving", "Investing", "Debts", "Mine"]

    func categories() -> [PurseCategory] {
        let ledger = SpendLedger(store: model.store, classes: model.classes)
        let month = ledger.entries(inMonthOf: now, calendar: calendar)
        let priorDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let prior = ledger.entries(inMonthOf: priorDate, calendar: calendar)
        let currency = Dictionary(grouping: month + prior) { $0.currency ?? "" }
            .max { $0.value.count < $1.value.count }?.key ?? ""
        let mine = month.filter { ($0.currency ?? "") == currency }
        let mineBefore = prior.filter { ($0.currency ?? "") == currency }
        let days = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let priorDays = calendar.range(of: .day, in: .month, for: priorDate)?.count ?? 30
        let today = calendar.component(.day, from: now)

        func daily(_ entries: [SpendLedger.Entry], count: Int, sign: Double) -> [Double] {
            var values = Array(repeating: 0.0, count: count)
            for entry in entries {
                let day = calendar.component(.day, from: entry.spentAt) - 1
                if values.indices.contains(day) {
                    values[day] += sign * (entry.amount as NSDecimalNumber).doubleValue
                }
            }
            return values
        }
        var monthIn = Array(repeating: 0.0, count: days)
        var priorIn = Array(repeating: 0.0, count: priorDays)
        for (date, value) in inflows(currency: currency) {
            let day = calendar.component(.day, from: date) - 1
            if calendar.isDate(date, equalTo: now, toGranularity: .month), monthIn.indices.contains(day) {
                monthIn[day] += value
            } else if calendar.isDate(date, equalTo: priorDate, toGranularity: .month), priorIn.indices.contains(day) {
                priorIn[day] += value
            }
        }
        let outNow = daily(mine, count: days, sign: 1)
        let outBefore = daily(mineBefore, count: priorDays, sign: 1)
        let balance = PurseSeries.build(name: "Month", shape: .balance,
                                        daily: zip(monthIn, outNow).map { $0 - $1 }, today: today, daysInMonth: days,
                                        priorDaily: zip(priorIn, outBefore).map { $0 - $1 })
        let spend = PurseSeries.build(name: "Spend", shape: .flow, daily: outNow, today: today, daysInMonth: days,
                                      priorDaily: outBefore)
        // Kinds: the most used open categories this month, by count (never by size).
        let open = mine.filter { !$0.category.isEmpty && !ObjectPrivacy.isPrivateWord($0.category, in: model.store) }
        let kinds = Dictionary(grouping: open, by: \.category).sorted { $0.value.count > $1.value.count }.prefix(5)
        let kindSeries = kinds.map { kind, entries in
            PurseSeries.build(name: kind, shape: .flow, daily: daily(entries, count: days, sign: 1), today: today,
                              daysInMonth: days,
                              priorDaily: daily(mineBefore.filter { $0.category == kind }, count: priorDays, sign: 1))
        }
        return Self.names.enumerated().map { offset, name in
            let indices: [PurseSeries] = switch offset {
            case 0: [balance, spend]
            case 1: kindSeries
            default: []
            }
            return PurseCategory(id: name.lowercased(), name: name, indices: indices)
        }
    }

    /// Money in, by day: each inflow's typed amount in the drawn currency.
    private func inflows(currency: String) -> [(Date, Double)] {
        guard let inflowClass = model.classes[.inflow] else { return [] }
        return model.store.objects(of: inflowClass).compactMap { object in
            guard !object.isDeleted, let at = model.store.value("at", of: object)?.dateValue,
                  let typed = model.store.value("amountTyped", of: object)?.stringValue,
                  let amount = MoneyAmount.parse(typed), (amount.currency ?? currency) == currency || currency.isEmpty
            else { return nil }
            return (at, (amount.amount as NSDecimalNumber).doubleValue)
        }
    }
}
