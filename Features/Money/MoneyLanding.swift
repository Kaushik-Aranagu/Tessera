import SwiftUI
import TesseraCore

// The Money landing on the shared kit (landing contract §12, §11.4-5): a word wall of what the money went on, with no
// amount anywhere on the page; the doors on the dial; one line about the last spend; "Add a spend" at the foot. Money
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
    @State private var focus = 0
    @State private var adding = false
    @State private var draft = ""

    var body: some View {
        let _ = model.revision
        let wall = load()
        LandingFrame(title: "Money", accent: LandingAccent.money, stateLine: wall.stateLine,
                     keystone: {
                         LandingKeystone(label: "What the money went on") {
                             WordWallView(words: wall.words, open: { _ in
                                 TessVoice.shared.say("Spends by category come with the Spending page.")
                             }, label: { "\($0.text.capitalized), category" })
                         }
                     },
                     doors: doors(wall), focus: $focus,
                     openDoor: { door in
                         TessVoice.shared.say("\(door.name) isn't set up yet.")
                     },
                     brief: { LandingBrief(forms: brief(wall)) },
                     action: LandingFootAction(word: "Add a spend", hint: "Logs a spend, like 12.40 lunch") {
                         draft = ""
                         adding = true
                     },
                     onBack: { dismiss() })
            .toolbar(.hidden, for: .navigationBar)
            .alert("Add a spend", isPresented: $adding) {
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

    /// Bills, Subscriptions, Income, Savings (contract §12). None has a model yet; Bills carries the categories as
    /// its fact so the dial still says something true.
    private func doors(_ wall: MoneyWall) -> [DialDoor] {
        let slate = scheme == .dark ? Color(hex: 0xA7BCD6) : Color(hex: 0x34506F)
        var doors = [
            DialDoor(id: "bills", name: "Bills", color: LandingAccent.money, label: "Not set up yet",
                     lines: wall.top.isEmpty ? [] : ["Most spends on"] + wall.top.prefix(2)),
            DialDoor(id: "subscriptions", name: "Subscriptions", color: Theme.Colors.ink, label: "Not set up yet"),
            DialDoor(id: "income", name: "Income", color: Theme.Colors.ink, label: "Not set up yet"),
            DialDoor(id: "savings", name: "Savings", color: Theme.Colors.ink, label: "Not set up yet"),
        ]
        if wall.hidden > 0 {
            doors.append(DialDoor(id: "private", name: "Private", count: "\(wall.hidden)", color: slate,
                                  label: "Kept off the wall",
                                  lines: ["\(wall.hidden) private \(wall.hidden == 1 ? "category" : "categories")"]))
        }
        return doors
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
