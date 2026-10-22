import SwiftUI
import TesseraCore

/// Pantry by places (Design 118 §1–3 and §7, Kaushik's layout C, Oct 22): one page, the first user of RailPage. To
/// get (the Groceries list) is pinned above the dial in the hot colour; Fridge, Freezer, Shelf and Counter turn
/// through it. The open place fills the right half under its section words. A To get row taps off into the basket,
/// like Groceries; a place's row opens its ingredient (a private one opens nothing). The item sheet and the swipes
/// come next (118 §4, §2–3).
struct PantryView: View {
    var body: some View {
        NavigationStack {
            PantryPage()
                .navigationDestination(for: Route.self) { ObjectPage(route: $0) }
        }
        .environment(\.animateEntrance, true)
    }
}

private struct PantryPage: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// To get opens first while it has things on it; else the fridge.
    @State private var open: String?
    @State private var trip = ShopTrip()
    @State private var landed = 0

    var body: some View {
        let _ = model.revision
        let board = PantryBoard(store: model.store, classes: model.classes) { item in
            trip.label(for: item, name: GroceriesCopy.name(item), lastWeightKg: BodyWeight.lastKg(in: model.store))
        }
        let pinned = RailPlace(id: PantryPlaces.toGet, name: PantryPlaces.toGet, count: board.toGetCount)
        let places = board.places.map { RailPlace(id: $0.id.uuidString, name: $0.name, count: $0.count) }
        let current = open ?? (board.toGetCount > 0 || places.isEmpty ? pinned.id : places[0].id)
        RailPage(title: "Pantry", subtitle: board.subtitle(for:), back: (title: "Kitchen", action: { dismiss() }),
                 pinned: pinned, places: places,
                 open: Binding(get: { current }, set: { open = $0 }),
                 sections: { id in
                     if id == PantryPlaces.toGet {
                         return board.toGet.map { RailPage<PantryBoard.Row, PantryRow>.Section(label: $0.label,
                                                                                               rows: $0.rows) }
                     }
                     let place = board.places.first { $0.id.uuidString == id }
                     return (place?.groups ?? []).map { .init(label: $0.label, rows: $0.rows) }
                 },
                 empty: board.empty(for:))
        { row in
            PantryRow(row: row, onTick: tick)
        }
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .toolbar(.hidden, for: .navigationBar)
        .tesseraFeedback(.notNow, trigger: landed)
    }

    /// A To get row tapped: in the basket, as on Groceries (Done on Groceries clears the basket into the Pantry).
    private func tick(_ item: ListContents.Item) {
        let checked = try? model.engine.perform(CheckListItem(item: item.id, time: AppClock.now), by: .user)
        withTesseraAnimation(RailMetrics.crossfade, reduceMotion: reduceMotion) { model.touch() }
        if checked == nil {
            GroceriesCopy.sayDidntSave()
        } else {
            landed += 1
        }
    }
}

/// One row on the right half: the name left, one value right. To get shows its quantity; a place shows "low" or "out"
/// in the hot colour when the ledger knows it, and nothing when it is simply in (no amounts are guessed).
private struct PantryRow: View {
    let row: PantryBoard.Row
    let onTick: (ListContents.Item) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        switch row {
        case let .toGet(item, label):
            Button { onTick(item) } label: { line(label, value: item.quantity, hot: false) }
                .buttonStyle(HandleButtonStyle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(item.quantity.map { "\(label), \($0)" } ?? label)
                .accessibilityHint("Puts it in the basket")
        case let .stock(entry):
            let state = entry.state == .low || entry.state == .out ? entry.state.word : nil
            Group {
                if PantryLine.opens(entry) {
                    NavigationLink(value: Route.object(entry.ingredient.id)) {
                        line(entry.label, value: state, hot: true)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityHint("Opens \(entry.label)")
                } else {
                    line(entry.label, value: state, hot: true)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(state.map { "\(entry.label), \($0)" } ?? entry.label)
        }
    }

    private func line(_ name: String, value: String?, hot: Bool) -> some View {
        // At accessibility sizes the value goes under the name, nothing clipped.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.s))
        return layout {
            Text(name)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if !typeSize.isAccessibilitySize {
                Spacer(minLength: Theme.Spacing.s)
            }
            if let value {
                Text(value)
                    .textRole(.data)
                    .foregroundStyle(hot ? Theme.Colors.now : Theme.Colors.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 37, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// What a place's line may do.
enum PantryLine {
    /// A private row opens nothing: its page would show the name (pantry-acceptance S15, K26.16; QA on #724).
    static func opens(_ entry: PantryLedger.Entry) -> Bool {
        !entry.isPrivate
    }
}
