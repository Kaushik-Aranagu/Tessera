import Foundation

/// The one definition of a staple (Pantry v2 spec S11, P-F1): the ingredient's own flag, or the shop guide's list. The
/// recipe page, Groceries, the pantry and `RecipeMath.missing` all ask this, so salt is a staple on every screen.
@MainActor
public enum Staples {
    public static func isStaple(_ ingredient: ObjectRecord, in store: ObjectStore) -> Bool {
        store.value("isStaple", of: ingredient) == .bool(true)
            || AisleGuide.isStaple(IngredientLine.key(for: store.displayTitle(of: ingredient)))
    }
}
