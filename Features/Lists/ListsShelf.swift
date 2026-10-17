import Foundation
import TesseraCore

/// The Lists shelf as data (screen 9, lists-9-12.md), before Core's run, reusable and pick-one fields land: every
/// list by last touched, Groceries once among them, each with its tier and its state word. A walled list name reads
/// "Private list"; a walled item, "Private item".
@MainActor
struct ListsShelf {
    /// A name's size on the shelf: the most recently touched at Hero 56, the next two at Title 34, the rest at 21.
    enum Tier: Equatable {
        case hero, title, body
    }

    struct Row: Identifiable, Equatable {
        let id: UUID
        let name: String
        let isGroceries: Bool
        let tier: Tier
        /// "3 OF 7", "EMPTY", "14 TO BUY".
        let state: String
    }

    let rows: [Row]
    /// "2 lists", "1 list", "Just Groceries" (sheet 87 empty), never "0 lists".
    let context: String

    init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], lastWeightKg: Double?) {
        let contents = ListContents(store: store, classes: classes)
        let lists = contents.lists().filter { !$0.isDeleted }
        let ordered = lists.sorted { $0.updatedAt > $1.updatedAt }
        rows = ordered.enumerated().map { index, list in
            let isGroceries = list.id == Groceries.listID
            let open = contents.open(in: list).count, all = contents.items(of: list).count
            let title = store.displayTitle(of: list)
            return Row(id: list.id,
                       name: Self.shownName(title, lastWeightKg: lastWeightKg),
                       isGroceries: isGroceries,
                       tier: index == 0 ? .hero : index < 3 ? .title : .body,
                       state: Self.state(open: open, all: all, isGroceries: isGroceries))
        }
        let others = rows.filter { !$0.isGroceries }.count
        context = others == 0 && rows.contains(where: \.isGroceries) ? "Just Groceries" : ListsCopy
            .context(lists: rows.count)
    }

    /// The state word under a name: Groceries counts what's left to buy; any other list its done of all.
    static func state(open: Int, all: Int, isGroceries: Bool) -> String {
        if isGroceries {
            return open == 0 ? "NOTHING TO GET" : "\(open) TO BUY"
        }
        if all == 0 {
            return "EMPTY"
        }
        return "\(all - open) OF \(all)"
    }

    /// A list name the walls call private reads "Private list" (QA's note on ListsCopy).
    static func shownName(_ title: String, lastWeightKg: Double?) -> String {
        ObjectPrivacy.isPrivateRecipeTitle(title, lastWeightKg: lastWeightKg) ? "Private list" : title
    }
}
