import SwiftUI
import TesseraCore

/// Running low by rhythm (kitchen-v2 RL), behind the Review switch Usually line: up to 4 names he buys on a rhythm and
/// is about due for, one line at the foot of Groceries (USUALLY) and of Pantry (USUALLY HAVE). Nothing is added
/// without his tap; a tap puts it on Groceries with the house receipt and UNDO.
///
/// The engine is Core's (B10 ruling): `UsuallyDue` is the local shape with Product's numbers (RL-E1, RL-E2). When
/// Core's rhythm lands (`usualSkippedAt`, the one-mark-per-shop rule), `UsuallyDue.names` is where it plugs in.
enum UsuallyDue {
    /// The cap on both pages (RL-S1).
    static let cap = 4
    /// Buys older than this don't count (RL-E2).
    static let window = 56
    /// As Core's `BuyCadence.minimumBuys` (SL-I5: two buys is no rhythm).
    static let minimumBuys = 3

    /// Due between 0.85 and 2 rhythms after the last buy (RL-E1), counting only the last 56 days' buys, 3 or more.
    static func isDue(buys: [Date], now: Date, calendar: Calendar = .current) -> Bool {
        let house = TesseraDay(calendar: calendar)
        let today = house.today(now)
        let recent = Set(buys.map { house.day(of: $0) }).filter { day in
            (calendar.dateComponents([.day], from: day, to: today).day ?? .max) <= window
        }.sorted()
        guard recent.count >= minimumBuys, let first = recent.first, let last = recent.last else { return false }
        let span = Double(calendar.dateComponents([.day], from: first, to: last).day ?? 0)
        let rhythm = span / Double(recent.count - 1)
        guard rhythm > 0 else { return false }
        let since = Double(calendar.dateComponents([.day], from: last, to: today).day ?? 0)
        return since >= 0.85 * rhythm && since <= 2 * rhythm
    }

    /// The due things not already on Groceries, in walking order, then by name.
    @MainActor
    static func names(model: AppModel, now: Date) -> [(ingredient: ObjectRecord, label: String)] {
        let groceries = Groceries(store: model.store, classes: model.classes)
        let weight = BodyWeight.lastKg(in: model.store)
        // Only things a shop cleared can have a rhythm (each read once).
        var seen = Set<UUID>()
        let candidates = groceries.shopClears().map(\.ingredient)
            .filter { !$0.isDeleted && seen.insert($0.id).inserted }
        let due = candidates.filter { ingredient in
            PantryFront.listed(ingredient, groceries: groceries, store: model.store) == .none
                && isDue(buys: BuyCadence(of: ingredient, engine: model.engine).days, now: now)
        }
        return due.map { ingredient in
            let title = model.store.displayTitle(of: ingredient)
            let walled = ObjectPrivacy.isPrivateTitle(title, lastWeightKg: weight)
            return (ingredient, walled ? ShopTrip.privateLabel : title)
        }
        .sorted { lhs, rhs in
            let left = Aisle.order(of: AisleGuide.aisle(for: lhs.label)?.rawValue)
            let right = Aisle.order(of: AisleGuide.aisle(for: rhs.label)?.rawValue)
            return left != right ? left < right : lhs.label < rhs.label
        }
        .prefix(cap)
        .map(\.self)
    }
}

/// The line itself: the label, then each name as an ink word at 55%. A tap adds that one.
struct UsuallyLine: View {
    /// "Usually" on Groceries, "Usually have" on Pantry (ruling 3).
    let label: String
    @Environment(AppModel.self) private var model
    @State private var names: [(ingredient: ObjectRecord, label: String)] = []
    @State private var added = 0

    var body: some View {
        let _ = model.revision
        Group {
            if !names.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(label)
                        .textRole(.label)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .accessibilityAddTraits(.isHeader)
                    FlowWords(names.map(\.label)) { index in add(names[index]) }
                }
                .accessibilityElement(children: .contain)
            }
        }
        .task(id: model.revision) { names = UsuallyDue.names(model: model, now: AppClock.now) }
        .tesseraFeedback(.made, trigger: added)
    }

    private func add(_ entry: (ingredient: ObjectRecord, label: String)) {
        let name = model.store.displayTitle(of: entry.ingredient)
        guard let record = try? model.engine.perform(AddGroceries(lines: [name]), by: .user).record else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        model.touch()
        added += 1
        TessVoice.shared.say(PantryCopy.added(entry.label), undo: record, holds: .seconds(4))
    }
}

/// Names as tappable words at 55% ink, wrapping like a sentence.
private struct FlowWords: View {
    let words: [String]
    let tap: (Int) -> Void

    init(_ words: [String], tap: @escaping (Int) -> Void) {
        self.words = words
        self.tap = tap
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.Spacing.m) { buttons }
            VStack(alignment: .leading, spacing: 0) { buttons }
        }
    }

    private var buttons: some View {
        ForEach(Array(words.enumerated()), id: \.offset) { index, word in
            Button { tap(index) } label: {
                Text(word)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink.opacity(0.55))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HandleButtonStyle())
            .accessibilityLabel("\(word), add to Groceries")
        }
    }
}
