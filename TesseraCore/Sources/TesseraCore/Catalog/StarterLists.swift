import Foundation

/// The three starter lists (product/starter-lists.md, lists 4c): Gym bag, Leaving the house and Packing, so the Lists
/// app isn't empty on day one. All reusable, items open. Installed like the seed content: once, by stable id, so he can
/// delete one and it is never put back. Called at launch by the app (not by `prepareCatalog`, so a test store only
/// has them when it asks).
@MainActor
public enum StarterLists {
    struct Starter {
        let key: String
        let title: String
        /// Section name (nil for none) and its items, in order.
        let sections: [(name: String?, items: [String])]
    }

    static let all: [Starter] = [
        Starter(key: "gymBag", title: "Gym bag", sections: [
            ("Clothes", ["shorts", "t-shirt", "socks", "trainers"]),
            ("Kit", ["lifting belt", "chalk", "headphones", "water bottle"]),
            ("After", ["towel", "shower gel"]),
        ]),
        Starter(key: "leavingTheHouse", title: "Leaving the house", sections: [
            (nil, ["keys", "wallet", "phone", "headphones", "lights off", "windows shut"]),
        ]),
        Starter(key: "packing", title: "Packing", sections: [
            ("Clothes", ["socks", "t-shirts", "underwear", "pants", "sweater"]),
            ("Tech", ["phone charger", "adapter", "headphones"]),
            ("Papers", ["passport", "tickets", "cards"]),
        ]),
    ]

    static func id(_ key: String) -> UUID {
        SystemCatalog.stableID("starter.list.\(key)")
    }

    /// Makes each starter list that has never been made here. A deleted one is still known by its id, so it stays gone.
    /// Returns how many were made.
    @discardableResult
    public static func installIfNeeded(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) throws -> Int {
        guard let listClass = classes[.list], let itemClass = classes[.listItem] else { return 0 }
        var made = 0
        let taken = Set(ListContents(store: store, classes: classes).lists()
            .map { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        for starter in all where store.object(id: id(starter.key)) == nil {
            // A list he already made with this name is his: no second one, and the starter is marked handled (a
            // deleted placeholder under its id) so it is never tried again.
            if taken.contains(starter.title.lowercased()) {
                let placeholder = store.create(listClass, title: starter.title)
                placeholder.id = id(starter.key)
                store.softDelete(placeholder)
                continue
            }
            let list = store.create(listClass, title: starter.title)
            list.id = id(starter.key)
            var index = 0
            for section in starter.sections {
                for text in section.items {
                    let item = store.create(itemClass, title: text, parent: list)
                    item.sortIndex = index
                    index += 1
                    if let name = section.name {
                        try store.set("section", to: .text(name), on: item)
                    }
                }
            }
            try store.set("notes", to: .richText(ListNoteTags.reusable), on: list)
            made += 1
        }
        return made
    }
}
