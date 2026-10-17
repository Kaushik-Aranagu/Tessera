import Foundation
import Observation
import TesseraCore

/// Groceries' private rows, in the list and on the trip (SHOP mode, K46; B8, B11): the aisles come in the shop's walk
/// order (K7.3: produce, bakery, dairy and
/// eggs, meat and seafood, cans and jars, pantry, spices, frozen, household, other), and a private item reads
/// "Private item" until he taps its row. That tap shows its words for that row only, and the next tap strikes it as
/// any row's would. Leaving SHOP mode or the page, or locking the phone, masks every row again.
@MainActor @Observable
final class ShopTrip {
    static let privateLabel = "Private item"

    /// Rows he has tapped open this trip.
    private(set) var revealed: Set<UUID> = []

    /// Whether an item is walled: secret words, money, body facts and medicines (the recipe-title wall).
    static func isPrivate(_ text: String, lastWeightKg: Double?) -> Bool {
        ObjectPrivacy.isPrivateRecipeTitle(text, lastWeightKg: lastWeightKg)
    }

    /// What a row reads: its words, or "Private item" until it's tapped open.
    func label(for item: ListContents.Item, name: String, lastWeightKg: Double?) -> String {
        guard Self.isPrivate(item.text, lastWeightKg: lastWeightKg), !revealed.contains(item.id) else { return name }
        return Self.privateLabel
    }

    enum Tap: Equatable {
        /// The first tap on a masked row shows its words.
        case reveal
        /// Any other tap strikes it into the basket.
        case strike
    }

    /// What a tap on a row does.
    func tap(_ item: ListContents.Item, lastWeightKg: Double?) -> Tap {
        if Self.isPrivate(item.text, lastWeightKg: lastWeightKg), !revealed.contains(item.id) {
            revealed.insert(item.id)
            return .reveal
        }
        return .strike
    }

    /// The recipes a row is for, each private one only "Private recipe".
    static func recipeNames(_ titles: [String], lastWeightKg: Double?) -> [String] {
        titles
            .map { ObjectPrivacy.isPrivateRecipeTitle($0, lastWeightKg: lastWeightKg) ? ObjectPrivacy.recipeLabel : $0 }
    }

    /// Leaving SHOP mode: every private row masks again.
    func end() {
        revealed = []
    }

    /// The walk order of aisle names (unknown names last, in their given order).
    static func walkOrder(_ names: [String]) -> [String] {
        names.enumerated().sorted { lhs, rhs in
            let left = Aisle.order(of: lhs.element), right = Aisle.order(of: rhs.element)
            return left != right ? left < right : lhs.offset < rhs.offset
        }.map(\.element)
    }
}
