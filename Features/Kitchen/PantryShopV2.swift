import SwiftUI
import TesseraCore

/// The two Kitchen v2 switches (Design 161 and 155), both default Off; Off leaves the app as it was.
enum PantryShopSwitch {
    /// 161: a level line under each Pantry place's subtitle, and "N to get" after the place lines on the landing.
    @MainActor static var levelsOn: Bool {
        ReviewChoices.shared.value(of: "pantryLevelsV2") == "On"
    }

    /// 155: the shop run leads with the next item, strikes on a swipe and ends with Put away.
    @MainActor static var shopOn: Bool {
        ReviewChoices.shared.value(of: "shopV2") == "On"
    }
}

/// The shop run's words and numbers, pure so each has a test. Nothing here leaves the phone.
enum ShopV2Copy {
    static let badPrice = "That isn't a price."

    /// "12 got, 2 left for next time."
    static func gotLeft(got: Int, left: Int) -> String {
        switch (got, left) {
        case (0, 0): "Nothing in the basket."
        case (_, 0): "\(got) got, nothing left."
        case (0, _): "Nothing got, \(left) left for next time."
        default: "\(got) got, \(left) left for next time."
        }
    }

    /// "about $14": whole dollars, nil until a price is in.
    static func about(_ total: Double) -> String? {
        guard total > 0 else { return nil }
        return "about $\(Int(total.rounded()))"
    }

    /// A typed price: digits with a dot or one comma as the decimal mark, an optional leading "$". Nil when it is not
    /// a price; the field keeps what was typed.
    static func price(_ text: String) -> Double? {
        var clean = text.trimmingCharacters(in: .whitespaces)
        if clean.hasPrefix("$") {
            clean.removeFirst()
        }
        if clean.filter({ $0 == "," }).count == 1, !clean.contains(".") {
            clean = clean.replacingOccurrences(of: ",", with: ".")
        }
        guard !clean.isEmpty, let value = Double(clean), value.isFinite, value >= 0, value < 100_000 else { return nil }
        return value
    }
}

/// The about-basket prices, kept in this phone's defaults only (never in the store, never sent): one number per item
/// struck this shop, cleared when the shop ends.
struct ShopPrices {
    static let key = "shopV2.prices"
    private(set) var byItem: [String: Double]

    init(defaults: UserDefaults = .standard) {
        byItem = (defaults.dictionary(forKey: Self.key) as? [String: Double]) ?? [:]
    }

    var total: Double {
        byItem.values.reduce(0, +)
    }

    mutating func set(_ price: Double, for item: UUID, defaults: UserDefaults = .standard) {
        byItem[item.uuidString] = price
        defaults.set(byItem, forKey: Self.key)
    }

    mutating func clear(defaults: UserDefaults = .standard) {
        byItem = [:]
        defaults.removeObject(forKey: Self.key)
    }
}

extension PantryBoard {
    /// One place's level by the landing's rule (a); nil for To get and for a place where nothing is known.
    func level(for open: String) -> Double? {
        guard let place = places.first(where: { $0.id.uuidString == open }) else { return nil }
        let states = place.groups.flatMap(\.rows).compactMap { row -> PantryLedger.State? in
            if case let .stock(entry) = row {
                return entry.state
            }
            return nil
        }
        return KitchenFront.level(states)
    }
}

/// A thin ink line for a place's level, under its subtitle; sized by itself, never full width.
struct PlaceLevelLine: View {
    let level: Double

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Theme.Colors.ink.opacity(0.12)).frame(height: 1.5)
            Capsule().fill(Theme.Colors.ink)
                .frame(width: max(120 * level, level > 0 ? 6 : 0), height: 2.5)
        }
        .frame(width: 120, height: 12, alignment: .leading)
        .tesseraAnimation(value: level)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level")
        .accessibilityValue(KitchenFront.levelWords(level))
    }
}
