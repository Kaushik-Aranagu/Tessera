import Foundation
import SwiftUI
import TesseraCore

/// Cook notes into the recipe (docs/product/kitchen-v2-build-ready-rows-oct19.md CN). A note is written on Finish in
/// one optional line ("Note for next time", empty by default, no extra step) and rides `FinishCooking(note:)`. The
/// newest one reads on the recipe page and on the cook's first step as "Last time: less salt." Notes are his own
/// words, never sent anywhere, never scaled or edited into lines (CN-E4).
enum CookNotes {
    static let prompt = "Note for next time"
    static let maxLength = 280

    /// "Paprika chicken, cooked." keeps the full title; a private recipe reads "Private recipe, cooked."
    static func cookedLine(_ name: String) -> String {
        "\(name), cooked"
    }

    /// "Last time: less salt." The trailing full stop is not doubled.
    static func lastTimeLine(_ note: String) -> String {
        let text = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = text.hasSuffix(".") ? String(text.dropLast()) : text
        return "Last time: \(body)"
    }

    /// The newest note on this recipe's finished cooks, newest first (CN-E1, the cook half; a note linked with
    /// @recipe would join once Core gathers both).
    @MainActor
    static func latest(of recipe: ObjectRecord, store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) -> String? {
        let cooks = CookLog(store: store, classes: classes).cooks(of: recipe)
        for entry in cooks {
            if let note = store.value("note", of: entry.cook)?.stringValue?
                .trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty
            {
                // A private recipe's note reads "Private note", with no reveal (CN-E3).
                return ObjectPrivacy.isPrivateRecipeTitle(recipe.title, lastWeightKg: BodyWeight.lastKg(in: store))
                    ? "Private note" : note
            }
        }
        return nil
    }
}

/// The note line on the recipe page and the first cook step, in ink, behind the Cook notes switch.
struct CookNoteLine: View {
    let recipeID: UUID
    var dark = false
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.revision
        if Choice.cookNotesIsOn(), let recipe = model.store.object(id: recipeID),
           let note = CookNotes.latest(of: recipe, store: model.store, classes: model.classes)
        {
            Text(note == "Private note" ? note : CookNotes.lastTimeLine(note))
                .font(Theme.voice)
                .foregroundStyle(dark ? Theme.Colors.Workout.inkSecondary : Theme.Colors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(note == "Private note" ? note : CookNotes.lastTimeLine(note))
        }
    }
}
