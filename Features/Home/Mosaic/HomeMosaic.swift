import Foundation

/// Home as a mosaic (sheet 199): three lines about the day, a picture of it, and the next three things. Behind
/// Settings › Review › "Mosaic" (default Off: Home exactly as it is). "Apps list" adds sheet 197's list under Next.
enum HomeMosaic {
    nonisolated static let choiceID = "homeMosaic"
    nonisolated static let appsListID = "homeAppsList"
    nonisolated static let moodsID = "homeMosaicMoods"

    /// The page side margin on this page. Theme.Spacing.gutter is 22; this page is 24.
    static let gutter: CGFloat = 24
    static let sectionGap: CGFloat = 16
    static let mosaicHeight: CGFloat = 250
    /// Sheet 200: the narrower block (248x160, the mosaic changes size by mood inside it), 14 pt under the sentence.
    static let moodsMosaicSize = CGSize(width: 248, height: 160)
    static let moodsMosaicGap: CGFloat = 14
    /// Sheet 200: from the top of the safe area to the top of the sentence; the 44 pt date row sits inside it.
    static let moodsTopInset: CGFloat = 64
    static let headerHeight: CGFloat = 44

    static let rowHeight: CGFloat = 40
    /// A row open on its why line.
    static let openRowHeight: CGFloat = 78

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }

    @MainActor static var appsListIsOn: Bool {
        ReviewChoices.shared.value(of: appsListID) == "On"
    }

    /// Sheet 200: the departure board over the sentence. It rides on the Mosaic, so it needs both On.
    @MainActor static var moodsIsOn: Bool {
        isOn && ReviewChoices.shared.value(of: moodsID) == "On"
    }

    /// Sheet 201: moments (weather, an announcement, Tess, an app's event) take the mosaic for a while.
    @MainActor static var momentsIsOn: Bool {
        MosaicMomentsSwitch.isOn
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
