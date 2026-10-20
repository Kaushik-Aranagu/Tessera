import Foundation
import TesseraCore

/// The Reading shelf as data (screen 7 under the one-line grammar): one line per book under READING, NEXT, FINISHED
/// and SET ASIDE, where it is as the value at the right ("P 120 OF 612", "OCT 3", "AT P 88"). No covers, no counts.
/// A private book reads "Private book" here, its page value kept.
@MainActor
struct ReadingShelf {
    struct Row: Identifiable, Equatable {
        let id: UUID
        let name: String
        /// The drawn value at the right, or nil (a queued book has none).
        let value: String?
        /// "Dune, page 120 of 612".
        let spoken: String
    }

    struct Section: Identifiable, Equatable {
        let word: String
        let rows: [Row]

        var id: String {
            word
        }
    }

    let context: String
    let sections: [Section]
    let isEmpty: Bool

    init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], now: Date, calendar: Calendar = .current) {
        let shelf = Bookshelf(store: store, classes: classes)
        func name(_ book: ObjectRecord) -> String {
            ObjectPrivacy.label(of: book, in: store, classes: classes) ?? book.title
        }
        func row(_ book: ObjectRecord, value: String?, spokenValue: String?) -> Row {
            let shown = name(book)
            return Row(id: book.id, name: shown, value: value,
                       spoken: spokenValue.map { "\(shown), \($0)" } ?? shown)
        }
        let reading = shelf.reading().map { book in
            row(book, value: ReadingCopy.page(shelf.page(of: book), of: shelf.pages(of: book)),
                spokenValue: ReadingCopy.spokenPage(shelf.page(of: book), of: shelf.pages(of: book)))
        }
        let next = shelf.queued().map { row($0, value: nil, spokenValue: nil) }
        let finished = shelf.finished().map { book in
            let when = store.value("finishedAt", of: book)?.dateValue
            let drawn = when.map { ReadingCopy.finished($0, calendar: calendar) }
            return row(book, value: drawn, spokenValue: drawn.map { "finished \($0)" })
        }
        let aside = shelf.dropped().map { book in
            row(book, value: ReadingCopy.setAside(at: shelf.page(of: book)),
                spokenValue: "set aside at page \(shelf.page(of: book))")
        }
        sections = [("Reading", reading), ("Next", next), ("Finished", finished), ("Set aside", aside)]
            .filter { !$0.1.isEmpty }
            .map { Section(word: $0.0, rows: $0.1) }
        isEmpty = sections.isEmpty
        context = ReadingCopy.context(
            lastTouched: shelf.lastTouchedReading().map { (name($0), $0.updatedAt) },
            now: now,
            calendar: calendar
        )
    }
}
