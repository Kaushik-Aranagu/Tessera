import SwiftUI
import TesseraCore

// CLOUD-WRITTEN, NOT COMPILED (see the PR). The Money landing, design 131 section 2: one sentence of clauses, one
// total rule with the month so far on the decimal line, then the doors. Behind Review switch "Landing pages".
//
// There is no build sheet for Money yet, and no Bills, Saving, Cash or Owed model in Core, so this draws only what the
// engine can answer today: the month's spends (SpendLedger), the trend clause (Core's MoneyTrend, #1222), the total
// per currency and one "about" dollar total from the ECB table already cached on the phone (RatesCache). The doors
// (Due, Spending, Bills, Saving, Cash, Owed) are not drawn until their pages exist.

// MARK: - Facts

@MainActor
struct MoneyLandingFacts {
    /// A month's spends in one currency (nil: no currency typed). The exact sum of the typed digits.
    struct Total: Identifiable, Equatable {
        let currency: String?
        let amount: Decimal

        nonisolated var id: String {
            currency ?? ""
        }

        @MainActor var shown: String {
            SpendLedger.shown(amount, currency: currency, grouped: true)
        }
    }

    /// "October".
    let month: String
    /// Per currency, the biggest first. Spends in two currencies never add up in one figure.
    let totals: [Total]
    /// "about $1,234.00" across currencies, from the ECB table on the phone; nil with one currency or no table.
    let aboutDollars: String?
    let sentence: LandingSentence

    init(model: AppModel, now: Date, calendar: Calendar = .current) {
        let ledger = SpendLedger(store: model.store, classes: model.classes)
        let entries = ledger.entries(inMonthOf: now, calendar: calendar)
        var sums: [String: Decimal] = [:]
        for entry in entries {
            sums[entry.currency ?? "", default: 0] += entry.amount
        }
        totals = sums.map { Total(currency: $0.key.isEmpty ? nil : $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
        month = now.formatted(Date.FormatStyle().locale(Locale(identifier: "en_US")).month(.wide))
        aboutDollars = Self.about(totals)
        // The sentence is clauses, never figures. A late bill and the due bill need a Bills model that does not exist
        // yet, so "Nothing is late" is not claimed: only the trend is said.
        let trend = MoneyTrend(store: model.store, classes: model.classes).compare(now: now, calendar: calendar)
        sentence = LandingSentences.money(nothingLate: false, due: nil, trend: trend?.clause)
    }

    /// One dollar total across currencies, marked "about"; a spend with no currency counts as dollars. Nil when there
    /// is a single currency, or a currency the table does not know.
    private static func about(_ totals: [Total]) -> String? {
        guard totals.count > 1, let table = RatesCache().current() else { return nil }
        var dollars = 0.0
        for total in totals {
            let value = (total.amount as NSDecimalNumber).doubleValue
            guard let converted = table.convert(value, from: total.currency ?? "USD", to: "USD") else { return nil }
            dollars += converted
        }
        return "about " + SpendLedger.shown(Decimal(dollars), currency: "USD", grouped: true)
    }
}

// MARK: - The page

struct MoneyLandingView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let _ = model.revision
        let facts = MoneyLandingFacts(model: model, now: AppClock.now)
        let accent = LandingAccent.money
        LandingPage(back: (title: "Home", action: { dismiss() }),
                    title: "Money",
                    sentence: LandingText.build(facts.sentence, accent: accent),
                    accent: accent,
                    lead: { TotalRule(facts: facts, accent: accent) },
                    // Due, Spending, Bills, Saving, Cash and Owed join when their pages do.
                    doors: [])
            .background { ThemedBackground() }
            .environment(\.animateEntrance, true)
    }
}

/// The signature line: "October so far", the total on the decimal line (whole part large, cents smaller, one
/// baseline), and the rule under it in sage. Never red. Other currencies sit under it in the same figures, then the
/// one "about" dollar total. Absent when nothing is logged.
private struct TotalRule: View {
    let facts: MoneyLandingFacts
    let accent: Color

    var body: some View {
        if let first = facts.totals.first {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("\(facts.month) so far")
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                figure(first, large: true)
                Rectangle()
                    .fill(accent)
                    .frame(height: 2)
                    .accessibilityHidden(true)
                ForEach(facts.totals.dropFirst()) { total in
                    figure(total, large: false)
                        .padding(.top, Theme.Spacing.xs)
                }
                if let about = facts.aboutDollars {
                    Text(about)
                        .textRole(.data)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .padding(.top, Theme.Spacing.xs)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// "$1,234" large, ".56" smaller on the same baseline: the decimal line.
    private func figure(_ total: MoneyLandingFacts.Total, large: Bool) -> some View {
        let parts = total.shown.split(separator: ".", maxSplits: 1).map(String.init)
        let whole = parts.first ?? total.shown
        let cents = parts.count > 1 ? "." + parts[1] : ""
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(whole).textRole(large ? .heroNumber : .titleNumber)
                Text(cents).textRole(.titleNumber)
            }
            .foregroundStyle(Theme.Colors.ink)
            .lineLimit(1)
            // At large sizes the figure steps down rather than breaking.
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(whole).textRole(.titleNumber)
                Text(cents).textRole(.titleNumber)
            }
            .foregroundStyle(Theme.Colors.ink)
        }
    }
}
