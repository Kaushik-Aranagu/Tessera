import Foundation

/// The Ingredient fields that hold what he has (Pantry v2 spec, section a). They exist after the catalog bump; the
/// shared export already leaves them out (R18, G196): a body-adjacent fact about what he eats stays in the full backup.
public enum PantryFields {
    /// Ingredient field keys that never leave in a shared export.
    public static let keys: Set<String> = ["state", "lastBoughtAt", "stateAt", "usualSkippedAt", "lastUsedAt",
                                           "pantryPrivate"]

    /// The one backfill op's action name (R1): the shared export drops it whole.
    public static let backfillAction = "pantryBackfill"

    /// The ids of the Ingredient fields that are pantry state, from an exported class list.
    static func fieldIDs(in classes: [TesseraExport.ClassEntry]) -> Set<String> {
        Set(classes.filter { $0.systemKey?.hasSuffix("." + SystemCatalog.Key.ingredient.rawValue) == true }
            .flatMap(\.fields).filter { keys.contains($0.key) }.map(\.id.uuidString))
    }
}
