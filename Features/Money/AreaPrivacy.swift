import Foundation
import TesseraCore

/// Core's receipts carry the raw title, amount or review ("12.40 lunch, logged.", "Dune, finished: slow start.").
/// Before a screen shows one, it goes through here (QA on #1148): a spend outside its own page and the Month page
/// shows no amount, and a private book reads "Private book" with its review left on its page. The UNDO key is built
/// from the line as shown, so it is masked the same way.
enum AreaPrivacy {
    /// A book's receipt as shown: unchanged for a plain book; for a private one the title becomes "Private book"
    /// and a review is dropped ("Private book, finished.").
    static func bookLine(_ receipt: String, title: String, isPrivate: Bool) -> String {
        guard isPrivate else { return receipt }
        var rest = receipt.hasPrefix(title) ? String(receipt.dropFirst(title.count)) : ", changed."
        if rest.hasPrefix(", finished") {
            rest = ", finished."
        }
        return ObjectPrivacy.bookLabel + rest
    }

    @MainActor
    static func bookLine(_ receipt: String, book: ObjectRecord, store: ObjectStore,
                         classes: [SystemCatalog.Key: ClassDef]) -> String
    {
        bookLine(receipt, title: book.title,
                 isPrivate: ObjectPrivacy.label(of: book, in: store, classes: classes) != nil)
    }

    /// The groceries total away from the Month page (Groceries, Now): no amount. "Groceries total, logged."
    static let shopTotalLogged = "Groceries total, logged."

    /// A spend's line where amounts may not show: "Private spend, logged." / "Private spend, deleted."
    static func spendLine(_ receipt: String, onMoneyPage: Bool) -> String {
        guard !onMoneyPage else { return receipt }
        guard let comma = receipt.lastIndex(of: ",") else { return ObjectPrivacy.spendLabel + "." }
        return ObjectPrivacy.spendLabel + receipt[comma...]
    }
}
