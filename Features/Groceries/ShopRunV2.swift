import SwiftUI
import TesseraCore

/// The shop run, v2 (Design 155), behind Settings > Review > Kitchen v2 > Shop run (default Off). The aisle you are in
/// is a small word above (it rolls over when the aisle changes); the next item leads in large words, the rest of its
/// aisle under it. Swipe right (or tap) strikes it. After a strike an optional price line asks for a number; the
/// running "about $N" total sits under the list. Prices live in this phone's defaults only (ShopPrices).
struct ShopRunV2: View {
    let aisles: [(aisle: String, items: [ListContents.Item])]
    let striking: Set<UUID>
    let recipes: (ListContents.Item) -> [String]
    /// What each row reads: a private one is always masked (G102).
    let label: (ListContents.Item) -> String
    let onStrike: (ListContents.Item) -> Void
    let basketCount: Int
    /// The items struck (checked) in this shop: only their prices count toward the total.
    let basketIDs: Set<UUID>
    /// The running shop's id: a new shop starts with no prices.
    let shopID: UUID
    /// "Done shopping" was tapped: the page says what was got and what waits.
    let summary: Bool
    @Binding var prices: ShopPrices

    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var struck: (id: UUID, name: String)?
    @State private var priceText = ""
    @State private var badPrice = false
    @State private var priced = 0

    private var open: Int {
        aisles.reduce(0) { $0 + $1.items.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            if summary {
                Text(ShopV2Copy.gotLeft(got: basketCount, left: open))
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            } else if let current = aisles.first {
                aisle(current)
            } else {
                Text("All in the basket.")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if struck != nil, !summary {
                priceLine
            }
            if let about = ShopV2Copy.about(prices.total(counting: basketIDs)) {
                Text(about)
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .contentTransition(.numericText())
                    .tesseraAnimation(value: about)
                    .accessibilityLabel("Basket total, \(about)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tesseraFeedback(.selection, trigger: priced)
        .onChange(of: shopID, initial: true) { _, id in
            prices.beginShop(id)
        }
    }

    private func aisle(_ current: (aisle: String, items: [ListContents.Item])) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(current.aisle)
                .textRole(.data)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .contentTransition(.numericText())
                .tesseraAnimation(value: current.aisle)
                .accessibilityAddTraits(.isHeader)
            if let next = current.items.first {
                ShopLead(item: next, name: label(next), isStriking: striking.contains(next.id)) { strike(next) }
                    .id(next.id)
                    .transition(.opacity)
                    .tesseraAnimation(value: next.id)
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(current.items.dropFirst()) { item in
                    GroceryRow(item: item, isStriking: striking.contains(item.id), recipes: recipes(item),
                               height: 44, name: label(item)) { strike(item) }
                        .transition(.opacity)
                }
            }
        }
    }

    /// "Milk, got. Price?" with a number field and Add. Optional: leaving it blank costs nothing.
    private var priceLine: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.m))
        return VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            layout {
                Text("\(struck?.name ?? "It"), got. Price?")
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                TextField("0", text: $priceText)
                    .keyboardType(.decimalPad)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(minWidth: 72, maxWidth: 140, minHeight: 44, alignment: .leading)
                    .onChange(of: priceText) { badPrice = false }
                Button("Add", action: addPrice)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(minHeight: 44)
                    .disabled(priceText.isEmpty)
            }
            if badPrice {
                // One ink sentence and one plain word; the typed number stays.
                HStack(spacing: Theme.Spacing.m) {
                    Text(ShopV2Copy.badPrice)
                        .textRole(.data)
                        .foregroundStyle(Theme.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Clear") { priceText = "" }
                        .textRole(.data)
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(minHeight: 44)
                }
            }
        }
    }

    private func addPrice() {
        guard let struck else { return }
        guard let value = ShopV2Copy.price(priceText) else {
            badPrice = true
            return
        }
        prices.set(value, for: struck.id)
        self.struck = nil
        priceText = ""
        priced += 1
    }

    /// A new strike takes a price that is already typed and valid; the price line then asks about this item.
    private func strike(_ item: ListContents.Item) {
        if struck != nil, ShopV2Copy.price(priceText) != nil {
            addPrice()
        }
        struck = (item.id, label(item))
        priceText = ""
        badPrice = false
        onStrike(item)
    }
}

/// The next item, large, with the right swipe that strikes it. A tap strikes it too.
private struct ShopLead: View {
    let item: ListContents.Item
    let name: String
    let isStriking: Bool
    let onStrike: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pull: CGFloat = 0
    @State private var cue = HapticCue()
    private static let arm: CGFloat = 72

    var body: some View {
        Button(action: onStrike) {
            (Text(item.quantity.map { "\($0) " } ?? "").fontWeight(.semibold) + Text(name).fontWeight(.regular))
                .textRole(.title)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .textRenderer(StrikeRenderer(progress: isStriking ? 1 : 0, color: Theme.Colors.ink))
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        // The row stays put; a 2 pt ink line draws from the leading edge with the finger (as the Tasks app does).
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Theme.Colors.ink)
                .frame(height: 2)
                .scaleEffect(x: min(max(pull / Self.arm, 0), 1), anchor: .leading)
                .opacity(isStriking ? 0 : 1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 24)
                .onChanged { value in
                    guard value.translation.width > 0, value.translation.width > abs(value.translation.height) else {
                        return
                    }
                    pull = min(value.translation.width, Self.arm)
                }
                .onEnded { _ in
                    let armed = pull >= Self.arm
                    if armed {
                        // One soft tap as the strike lands, not at the arm point.
                        cue.play(.done)
                        onStrike()
                    }
                    withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { pull = 0 }
                }
        )
        .tesseraFeedback(cue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel((item.quantity.map { "\($0) " } ?? "") + name)
        .accessibilityHint("Puts it in the basket")
        .accessibilityAction(named: "Got it", onStrike)
    }
}

/// Put away: each item in the basket goes to the Pantry place it already has, or to the one its aisle suggests
/// (as the demo shop does). Items with neither stay unplaced. Returns how many have a place.
@MainActor
enum ShopPutAway {
    static func walk(basket: [ListContents.Item], model: AppModel) -> Int {
        let groceries = Groceries(store: model.store, classes: model.classes)
        let places = PantryPlaces(store: model.store, classes: model.classes)
        let ledger = PantryLedger(store: model.store, classes: model.classes)
        var placed = 0
        for item in basket {
            guard let ingredient = groceries.ingredient(of: item.object) else { continue }
            if places.place(of: ingredient) != nil {
                placed += 1
            } else if let home = PantryBoard.suggested(ledger.entry(for: ingredient).aisle),
                      (try? model.engine.perform(SetItemPlace(item: ingredient.id, place: home.place,
                                                              section: home.section), by: .user)) != nil
            {
                placed += 1
            }
        }
        return placed
    }
}
