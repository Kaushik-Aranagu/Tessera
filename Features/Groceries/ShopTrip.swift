import Foundation
import Observation
import TesseraCore

/// Groceries' private rows, in the list and on the trip (SHOP mode, K46; B8, B11): the aisles come in the shop's walk
/// order (K7.3: produce, bakery, dairy and eggs, meat and seafood, cans and jars, pantry, spices, frozen, household,
/// other), and a private item always reads "Private item". One tap strikes it as any row's would; there is no
/// tap-to-reveal (Product G102: masking stays at the source, no screen exempt).
@MainActor @Observable
final class ShopTrip {
    static let privateLabel = "Private item"

    /// Whether an item is walled: secret words, money, body facts and medicines (the recipe-title wall).
    static func isPrivate(_ text: String, lastWeightKg: Double?) -> Bool {
        ObjectPrivacy.isPrivateRecipeTitle(text, lastWeightKg: lastWeightKg)
    }

    /// What a row reads, everywhere (list, SHOP mode, basket, receipts): its words, or "Private item".
    func label(for item: ListContents.Item, name: String, lastWeightKg: Double?) -> String {
        Self.isPrivate(item.text, lastWeightKg: lastWeightKg) ? Self.privateLabel : name
    }

    /// The same as `label`: kept for the call sites that name the basket and receipts.
    func maskedLabel(for item: ListContents.Item, name: String, lastWeightKg: Double?) -> String {
        label(for: item, name: name, lastWeightKg: lastWeightKg)
    }

    /// The recipes a row is for, each private one only "Private recipe".
    static func recipeNames(_ titles: [String], lastWeightKg: Double?) -> [String] {
        titles
            .map { ObjectPrivacy.isPrivateRecipeTitle($0, lastWeightKg: lastWeightKg) ? ObjectPrivacy.recipeLabel : $0 }
    }

    /// The walk order of aisle names (unknown names last, in their given order).
    static func walkOrder(_ names: [String]) -> [String] {
        names.enumerated().sorted { lhs, rhs in
            let left = Aisle.order(of: lhs.element), right = Aisle.order(of: rhs.element)
            return left != right ? left < right : lhs.offset < rhs.offset
        }.map(\.element)
    }
}
