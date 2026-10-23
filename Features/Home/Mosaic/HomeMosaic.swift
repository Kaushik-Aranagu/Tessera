import Foundation

/// Home as a mosaic (sheet 199): three lines about the day, a picture of it, and the next three things. Behind
/// Settings › Review › "Mosaic" (default Off: Home exactly as it is). "Apps list" adds sheet 197's list under Next.
enum HomeMosaic {
    nonisolated static let choiceID = "homeMosaic"
    nonisolated static let appsListID = "homeAppsList"

    /// The page side margin on this page. Theme.Spacing.gutter is 22; this page is 24.
    static let gutter: CGFloat = 24
    static let sectionGap: CGFloat = 16
    static let mosaicHeight: CGFloat = 250
    static let rowHeight: CGFloat = 40
    /// A row open on its why line.
    static let openRowHeight: CGFloat = 78

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }

    @MainActor static var appsListIsOn: Bool {
        ReviewChoices.shared.value(of: appsListID) == "On"
    }

    /// The sentence shows at most three lines, one clause each; with more, the first three.
    static func firstThree<T>(_ clauses: [T]) -> [T] {
        Array(clauses.prefix(3))
    }
}

/// Only one Next row is open at a time: opening one closes the other; tapping the open one closes it.
struct OneOpenRow: Equatable {
    private(set) var open: UUID?

    mutating func tap(_ id: UUID) {
        open = open == id ? nil : id
    }

    mutating func close() {
        open = nil
    }

    func isOpen(_ id: UUID) -> Bool {
        open == id
    }
}
