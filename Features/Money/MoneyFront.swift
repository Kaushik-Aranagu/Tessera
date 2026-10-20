import Foundation
import TesseraCore

/// The Money front as data (sheet money-reading-grammar, first panel): the context line, the month sentence, then
/// one line per spend under its day, the unmarked spends first and each other currency under its own label. This is
/// the Month page, so amounts show in full here, a masked spend included (Money amendment 2).
@MainActor
struct MoneyFront {
    struct Line: Identifiable, Equatable {
        let id: UUID
        /// The spend's word ("lunch"), or "spend" when it has none.
        let word: String
        /// As typed: "12.40", "€8", "20 eur".
        let amount: String
        let title: String
        /// "Oct 15, lunch, 12 dollars 40".
        let spoken: String
    }

    struct Day: Identifiable, Equatable {
        let id: Date
        /// "Oct 15" (drawn uppercase).
        let label: String
        let lines: [Line]
    }

    struct Group: Identifiable, Equatable {
        /// Nil for the unmarked spends.
        let currency: String?
        /// "In dollars", or nil for the unmarked group.
        let heading: String?
        let days: [Day]

        var id: String {
            currency ?? ""
        }
    }

    let context: String
    let sentence: [String]
    let groups: [Group]
    let isEmpty: Bool

    init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], now: Date, calendar: Calendar = .current) {
        let entries = SpendLedger(store: store, classes: classes).entries(inMonthOf: now, calendar: calendar)
        context = MoneyCopy.context(now: now, calendar: calendar)
        sentence = MoneyCopy.monthSentence(entries)
        isEmpty = entries.isEmpty
        let house = TesseraDay(calendar: calendar)
        let byCurrency = Dictionary(grouping: entries, by: \.currency)
        groups = byCurrency.keys.sorted { ($0 ?? "") < ($1 ?? "") }.map { currency in
            let list = byCurrency[currency] ?? []
            let byDay = Dictionary(grouping: list) { house.day(of: $0.spentAt) }
            let days = byDay.keys.sorted(by: >).map { day in
                Day(id: day, label: MoneyCopy.dayLabel(day, calendar: calendar),
                    lines: (byDay[day] ?? []).sorted { $0.spentAt > $1.spentAt }.map { entry in
                        let note = store.value("note", of: entry.object)?.stringValue ?? ""
                        let word = note.isEmpty ? "spend" : note
                        let typed = store.value("typed", of: entry.object)?.stringValue ?? ""
                        return Line(id: entry.object.id, word: word,
                                    amount: typed.isEmpty ? MoneyCopy.drawn(entry.amount, currency: entry.currency)
                                        : typed,
                                    title: entry.object.title,
                                    spoken: MoneyCopy.spokenLine(day: day, word: word, amount: entry.amount,
                                                                 currency: entry.currency, calendar: calendar))
                    })
            }
            return Group(currency: currency, heading: currency.map(MoneyCopy.currencyHeading), days: days)
        }
    }
}
