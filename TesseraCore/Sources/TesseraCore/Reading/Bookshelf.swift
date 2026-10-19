import Foundation

/// The shelf (Reading slice 1): reading books by last touched, queued by when they were added, finished newest first.
/// Never a count anywhere ("47 to read" never appears).
@MainActor
public struct Bookshelf {
    public static let ownerApp = "Reading"
    /// The evening slot: 7 pm to 11 pm, then Now goes back (quiet hours, amendment 5).
    public static let eveningHours = 19 ..< 23

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    public func books(in state: String) -> [ObjectRecord] {
        guard let bookClass = classes[.book] else { return [] }
        return store.objects(of: bookClass).filter {
            !$0.isDeleted && (store.value("state", of: $0)?.stringValue ?? "queued") == state
        }
    }

    /// Last touched first.
    public func reading() -> [ObjectRecord] {
        books(in: "reading").sorted { $0.updatedAt > $1.updatedAt }
    }

    /// In the order they were added.
    public func queued() -> [ObjectRecord] {
        books(in: "queued").sorted { $0.createdAt < $1.createdAt }
    }

    /// Newest first.
    public func finished() -> [ObjectRecord] {
        books(in: "finished").sorted {
            (store.value("finishedAt", of: $0)?.dateValue ?? .distantPast)
                > (store.value("finishedAt", of: $1)?.dateValue ?? .distantPast)
        }
    }

    public func dropped() -> [ObjectRecord] {
        books(in: "dropped").sorted { $0.updatedAt > $1.updatedAt }
    }

    /// Exact title first (any state), then every word contained: the `recipe(named:)` rule.
    public func book(named name: String) -> ObjectRecord? {
        guard let bookClass = classes[.book] else { return nil }
        let wanted = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !wanted.isEmpty else { return nil }
        let all = store.objects(of: bookClass).filter { !$0.isDeleted }
        if let exact = all.first(where: { $0.title.lowercased() == wanted }) {
            return exact
        }
        let words = wanted.split(separator: " ").map(String.init)
        return all.first { book in
            let title = book.title.lowercased()
            return words.allSatisfy { title.contains($0) }
        }
    }

    /// The reading book touched last: where "p 142" goes.
    public func lastTouchedReading() -> ObjectRecord? {
        reading().first
    }

    public func page(of book: ObjectRecord) -> Int {
        Int(store.number("page", of: book) ?? 0)
    }

    public func pages(of book: ObjectRecord) -> Int? {
        store.number("pages", of: book).map { Int($0) }
    }

    /// "Dune, p 142" (the next-step line, and the title of the page line).
    public func line(for book: ObjectRecord) -> String {
        "\(book.title), p \(page(of: book))"
    }

    /// The evening slot on Now: 7 pm to 11 pm, only when nothing runs and no timed item is current, the most
    /// recently touched suspended book with its next step.
    public func eveningPick(at now: Date, calendar: Calendar = .current, somethingRuns: Bool,
                            timedItemCurrent: Bool) -> (book: ObjectRecord, nextStep: String)?
    {
        let hour = calendar.component(.hour, from: now)
        guard Self.eveningHours.contains(hour), !somethingRuns, !timedItemCurrent else { return nil }
        let processes = ProcessTable(engine: ActionEngine(store: store, classes: classes)).all()
        let suspended = processes.filter { $0.ownerApp == Self.ownerApp && $0.state == .suspended }
            .sorted { ($0.lastTouchedAt ?? .distantPast) > ($1.lastTouchedAt ?? .distantPast) }
        guard let first = suspended.first, let book = first.subject else { return nil }
        return (book, first.nextStep ?? line(for: book))
    }
}
