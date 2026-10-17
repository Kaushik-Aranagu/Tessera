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
        /// "3 OF 7", "EMPTY", "14 TO GET", "RUNNING, 9 LEFT", "REUSABLE".
        let state: String
        /// A run is open (running, or waiting in the ledger): the state word is vermilion (9.3).
        var isRunning = false
    }

    let rows: [Row]
    /// "2 lists", "1 list", "2 lists, 1 running", "Just Groceries" (sheet 87 empty), never "0 lists".
    let context: String
    /// Tess's line for the newest run: "Packing has 9 left." (13.3); nil with nothing running.
    let tess: String?

    init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], lastWeightKg: Double?,
         engine: ActionEngine? = nil)
    {
        let contents = ListContents(store: store, classes: classes)
        let lists = contents.lists().filter { !$0.isDeleted }
        // One read of the process table for the whole shelf, not one per list (QA on #814).
        let open = (engine.map { ProcessTable(engine: $0).all() } ?? []).filter(\.state.isOpen)
        let runs = Dictionary(open.compactMap { process in
            process.subject.map { ($0.id, process.startedAt ?? .distantPast) }
        }, uniquingKeysWith: max)
        // Running lists first, the newer run first (9.2, G11); then by last touched.
        let ordered = lists.sorted { lhs, rhs in
            switch (runs[lhs.id], runs[rhs.id]) {
            case let (left?, right?): left > right
            case (.some, nil): true
            case (nil, .some): false
            case (nil, nil): Self.touched(lhs) > Self.touched(rhs)
            }
        }
        rows = ordered.enumerated().map { index, list in
            let isGroceries = list.id == Groceries.listID
            let open = contents.open(in: list).count, all = contents.items(of: list).count
            let title = store.displayTitle(of: list)
            let isRunning = !isGroceries && runs[list.id] != nil
            return Row(id: list.id,
                       name: Self.shownName(title, lastWeightKg: lastWeightKg),
                       isGroceries: isGroceries,
                       tier: index == 0 ? .hero : index < 3 ? .title : .body,
                       state: isRunning ? ListsCopy.runState(left: open)
                           : !isGroceries && contents.isReusable(list) ? "REUSABLE"
                           : Self.state(open: open, all: all, isGroceries: isGroceries),
                       isRunning: isRunning)
        }
        let others = rows.filter { !$0.isGroceries }.count
        let running = rows.filter(\.isRunning)
        context = others == 0 && rows.contains(where: \.isGroceries) ? "Just Groceries" : ListsCopy
            .context(lists: rows.count, running: running.count)
        tess = running.first.flatMap { row in
            lists.first { $0.id == row.id }.map { ListsCopy.tess(list: row.name, left: contents.open(in: $0).count) }
        }
    }

    /// When a list was last touched: the list itself, or any of its items (adding and checking touch only the item;
    /// QA on #760).
    static func touched(_ list: ObjectRecord) -> Date {
        ([list.updatedAt] + (list.children ?? []).map(\.updatedAt)).max() ?? list.updatedAt
    }

    /// The state word under a name: Groceries counts what's left to buy; any other list its done of all.
    static func state(open: Int, all: Int, isGroceries: Bool) -> String {
        if isGroceries {
            return open == 0 ? "NOTHING TO GET" : "\(open) TO GET"
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
