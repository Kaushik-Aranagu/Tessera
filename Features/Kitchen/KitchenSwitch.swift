import Foundation

/// The Kitchen v2 Review switches (huddle batches 6 and 10; kitchen-v2 build-ready rows, Oct 19). Each reads On only
/// when its Review row is live and set to On; a row that isn't there yet, or isn't live, reads Off, so every Kitchen v2
/// surface stays hidden and today's screens stand.
@MainActor
enum KitchenSwitch {
    static func isOn(_ id: String) -> Bool {
        ReviewChoices.shared.value(of: id) == "On"
    }

    /// Each pantry thing reads In, Low or Out; the recipe page shows need against have.
    static var pantryState: Bool {
        isOn("pantryState")
    }

    /// The CAN COOK shelf on Recipes.
    static var canCookShelf: Bool {
        isOn("canCookShelf")
    }

    /// The Mon to Sun dinners strip on Kitchen, with its one key to add the week to Groceries.
    static var weekStrip: Bool {
        isOn("weekStrip")
    }

    /// Up to 4 names he buys on a rhythm, at the foot of Groceries and Pantry.
    static var usuallyLine: Bool {
        isOn("usuallyLine")
    }

    /// FIX on the recipe page: change it in place.
    static var fixRecipe: Bool {
        isOn("fixRecipe")
    }
}
