import Foundation

/// Queues a book (Reading slice 1): the title as said, an author and a page count if given. A title that exists
/// returns the existing book, never a second copy. The thing comes first in every line (amendment 1).
public struct QueueBook: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "queueBook", summary: "Queue a book to read",
        parameters: [
            .init("title", .string, "The book, e.g. Dune"),
            .init("author", .string, "Who wrote it", required: false),
            .init("pages", .integer, "How many pages", required: false),
        ]
    )

    public var title: String
    public var author: String?
    public var pages: Int?

    public init(title: String, author: String? = nil, pages: Int? = nil) {
        self.title = title
        self.author = author
        self.pages = pages
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "title is empty")
        }
        let shelf = Bookshelf(store: transaction.store, classes: transaction.classes)
        let book: ObjectRecord
        if let existing = shelf.book(named: name) {
            book = existing
        } else {
            book = try transaction.create(transaction.classDef(.book), title: name)
            try transaction.set("state", to: .choice("queued"), on: book)
        }
        if let author = author?.trimmingCharacters(in: .whitespaces), !author.isEmpty,
           transaction.store.value("author", of: book) == nil
        {
            try transaction.set("author", to: .text(author), on: book)
        }
        if let pages, pages > 0, pages < 20000, transaction.store.number("pages", of: book) == nil {
            try transaction.set("pages", to: .number(Double(pages)), on: book)
        }
        return book
    }

    public func summary(in _: ObjectStore) -> String {
        "\(title), in the queue"
    }

    public func summary(in _: ObjectStore, output book: ObjectRecord) -> String {
        "\(book.title), in the queue"
    }

    public func receipt(in _: ObjectStore, output book: ObjectRecord) -> String? {
        "\(book.title), in the queue."
    }
}

/// Changes a book's title, author or page count.
public struct EditBook: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "editBook", summary: "Change a book",
        parameters: [
            .init("book", .object, "The book"), .init("title", .string, "New title", required: false),
            .init("author", .string, "Author", required: false), .init("pages", .integer, "Pages", required: false),
            .init("isPrivate", .boolean, "Keep this book private", required: false),
        ], isOfferedToModel: false
    )

    public var book: UUID
    public var title: String?
    public var author: String?
    public var pages: Int?
    public var isPrivate: Bool?

    public init(book: UUID, title: String? = nil, author: String? = nil, pages: Int? = nil, isPrivate: Bool? = nil) {
        self.book = book
        self.title = title
        self.author = author
        self.pages = pages
        self.isPrivate = isPrivate
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(book, is: .book)
        if let title, !title.trimmingCharacters(in: .whitespaces).isEmpty {
            transaction.setTitle(title.trimmingCharacters(in: .whitespaces), on: object)
        }
        if let author {
            try transaction.set("author", to: .text(author), on: object)
        }
        if let pages, pages > 0, pages < 20000 {
            try transaction.set("pages", to: .number(Double(pages)), on: object)
        }
        if let isPrivate {
            try transaction.set("isPrivate", to: .bool(isPrivate), on: object)
        }
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: book)?.title ?? "A book"), changed"
    }
}

/// Starts reading: state reading, and a Reading process that opens suspended, so it sits in What's running and
/// never takes Now from a workout or a task (decision 1). Resume makes it running through `ResumeProcess`.
public struct StartReading: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "startReading", summary: "Start reading a book",
        parameters: [.init("book", .object, "The book"), .init("time", .date, "Defaults to now", required: false)]
    )

    public var book: UUID
    public var time: Date?

    public init(book: UUID, time: Date? = nil) {
        self.book = book
        self.time = time
    }

    @discardableResult
    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let object = try transaction.object(book, is: .book)
        let now = time ?? .now
        try transaction.set("state", to: .choice("reading"), on: object)
        let shelf = Bookshelf(store: transaction.store, classes: transaction.classes)
        let step = shelf.line(for: object)
        let point = ResumePoint(index: shelf.page(of: object))
        if let existing = transaction.openProcess(for: object) {
            try transaction.saveContext(existing, resumePoint: point, nextStep: step, at: now)
            return object
        }
        let process = try transaction.create(transaction.classDef(.process), title: object.title)
        try transaction.setLinks("subject", on: process, to: [object])
        try transaction.set("ownerApp", to: .text(Bookshelf.ownerApp), on: process)
        try transaction.set("state", to: .choice(ProcessState.suspended.rawValue), on: process)
        try transaction.set("startedAt", to: .date(now), on: process)
        try transaction.saveContext(process, resumePoint: point, nextStep: step, at: now)
        return object
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: book)?.title ?? "A book"), started"
    }

    public func receipt(in _: ObjectStore, output book: ObjectRecord) -> String? {
        "\(book.title), started."
    }
}

/// Saves the page without changing state. "Dune, p 120 to 142".
public struct SetBookPage: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setBookPage", summary: "Set the page you are on",
        parameters: [
            .init("book", .object, "The book"), .init("page", .integer, "The page"),
            .init("pages", .integer, "How many pages in all", required: false),
            .init("time", .date, "Defaults to now", required: false),
        ]
    )

    public var book: UUID
    public var page: Int
    public var pages: Int?
    public var time: Date?

    public init(book: UUID, page: Int, pages: Int? = nil, time: Date? = nil) {
        self.book = book
        self.page = page
        self.pages = pages
        self.time = time
    }

    /// The old page, so the summary reads "p 120 to 142".
    public struct Moved: Sendable {
        public let title: String
        public let from: Int
        public let to: Int
        public let pages: Int?
    }

    public func apply(_ transaction: inout Transaction) throws -> Moved {
        guard page >= 0, page < 100_000 else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "page must be 0 or more")
        }
        let object = try transaction.object(book, is: .book)
        let shelf = Bookshelf(store: transaction.store, classes: transaction.classes)
        let old = shelf.page(of: object)
        let now = time ?? .now
        if let pages, pages > 0, pages < 20000, transaction.store.number("pages", of: object) == nil {
            try transaction.set("pages", to: .number(Double(pages)), on: object)
        }
        try transaction.set("page", to: .number(Double(page)), on: object)
        object.updatedAt = now
        if let process = transaction.openProcess(for: object) {
            try transaction.saveContext(
                process,
                resumePoint: ResumePoint(index: page),
                nextStep: shelf.line(for: object),
                at: now
            )
        }
        return Moved(title: object.title, from: old, to: page, pages: shelf.pages(of: object))
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: book)?.title ?? "A book"), p \(page)"
    }

    public func summary(in _: ObjectStore, output moved: Moved) -> String {
        moved.from == moved.to ? "\(moved.title), p \(moved.to)" : "\(moved.title), p \(moved.from) to \(moved.to)"
    }

    public func receipt(in _: ObjectStore, output moved: Moved) -> String? {
        var line = moved.pages.map { "\(moved.title), p \(moved.to) of \($0)." } ?? "\(moved.title), p \(moved.to)."
        if let total = moved.pages, moved.to > total {
            line += " Last page. Finished?"
        }
        return line
    }
}

/// Finishes a book, with a one-line review if given, and ends its process.
public struct FinishBook: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "finishBook", summary: "Finish a book",
        parameters: [
            .init("book", .object, "The book"), .init("review", .string, "One line on it", required: false),
            .init("time", .date, "Defaults to now", required: false),
        ]
    )

    public var book: UUID
    public var review: String?
    public var time: Date?

    public init(book: UUID, review: String? = nil, time: Date? = nil) {
        self.book = book
        self.review = review
        self.time = time
    }

    @discardableResult
    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let object = try transaction.object(book, is: .book)
        let now = time ?? .now
        try transaction.set("state", to: .choice("finished"), on: object)
        try transaction.set("finishedAt", to: .date(now), on: object)
        let line = review?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        if let line {
            try transaction.set("review", to: .text(line), on: object)
        }
        if let process = transaction.openProcess(for: object) {
            try transaction.end(process, reason: .done, at: now)
        }
        return object
    }

    public func summary(in store: ObjectStore) -> String {
        let title = store.object(id: book)?.title ?? "A book"
        return review.map { "\(title), finished: \($0)" } ?? "\(title), finished"
    }

    public func receipt(in store: ObjectStore, output book: ObjectRecord) -> String? {
        let line = store.value("review", of: book)?.stringValue.flatMap { $0.isEmpty ? nil : $0 }
        return line.map { "\(book.title), finished: \($0)." } ?? "\(book.title), finished. One line on it?"
    }
}

/// Sets a book aside (dropped) and ends its process; "reading Dune" brings it back at its saved page.
public struct SetBookAside: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setBookAside", summary: "Set a book aside",
        parameters: [.init("book", .object, "The book"), .init("time", .date, "Defaults to now", required: false)]
    )

    public var book: UUID
    public var time: Date?

    public init(book: UUID, time: Date? = nil) {
        self.book = book
        self.time = time
    }

    @discardableResult
    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let object = try transaction.object(book, is: .book)
        try transaction.set("state", to: .choice("dropped"), on: object)
        if let process = transaction.openProcess(for: object) {
            try transaction.end(process, reason: .closed, at: time ?? .now)
        }
        return object
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: book)?.title ?? "A book"), set aside"
    }

    public func receipt(in _: ObjectStore, output book: ObjectRecord) -> String? {
        "\(book.title), set aside."
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
