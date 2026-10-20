import SwiftUI

/// The "Reading layout" Review switch (sheet 99): "Today" is the look as it was; "Sheet 99" refits Groceries, Home,
/// the Exercise page and Backup to three type sizes each. The value lives in UserDefaults (`review.readingLayout`)
/// like every Review switch; an unset key or a value this build does not know reads Today.
enum ReadingLayout: String, CaseIterable, Sendable {
    case today = "Today"
    case sheet99 = "Sheet 99"

    static let options = ReadingLayout.allCases.map(\.rawValue)

    static func current(defaults: UserDefaults = .standard) -> ReadingLayout {
        ReadingLayout(rawValue: Choice.value("readingLayout", options: options, default: ReadingLayout.today.rawValue,
                                             defaults: defaults)) ?? .today
    }
}

/// Where a size is typed today as a literal (or a token) and what sheet 99 says instead. One lookup, so a page never
/// chooses a size by itself: `size(_:in:)` for the number, `.reading(_:)` to set it.
enum ReadingSlot: CaseIterable, Hashable, Sendable {
    /// The page's name where it is not a hero step-down: Groceries, Backup.
    case pageHead
    /// An aisle's name in the list view (strong 16, in ink).
    case aisleHead
    /// The aisle in shop mode, where it may rise.
    case shopAisle
    /// The line under a page title ("3 things, 2 aisles").
    case contextLine
    /// The one detail line under a lead row.
    case detailLine
    /// "Next", "Later", "Plan" on Home.
    case queueHead
    /// The line under a paused thing on Now.
    case queueDetail
    /// "A restore is waiting".
    case restoreHead
    /// An exercise's name.
    case exerciseName
    /// The number the exercise page leads with.
    case todayNumber
    /// A row of numerals (rep maxes).
    case rowNumeral
    /// The top set at the right of a history row.
    case historyNumber
    /// The date at the left of a history row.
    case historyDate
    /// A note under a grid, a role at a row's end.
    case note

    /// A size is only ever one of sheet 99's: 16, 18 (typing and the one detail line), 21, 28, 44, 56.
    static let sanctioned: Set<CGFloat> = [16, 18, 21, 28, 44, 56]

    /// (today, sheet 99) in points on the Plein scale.
    private var sizes: (today: CGFloat, sheet99: CGFloat) {
        switch self {
        case .pageHead: (56, 44)
        case .aisleHead: (44, 16)
        case .shopAisle: (56, 44)
        case .contextLine: (21, 16)
        case .detailLine: (18, 18)
        case .queueHead: (34, 16)
        case .queueDetail: (18, 16)
        case .restoreHead: (44, 21)
        case .exerciseName: (56, 44)
        case .todayNumber: (44, 56)
        case .rowNumeral: (24, 28)
        case .historyNumber: (21, 28)
        case .historyDate: (18, 21)
        case .note: (18, 16)
        }
    }

    static func size(_ slot: ReadingSlot, in layout: ReadingLayout) -> CGFloat {
        layout == .today ? slot.sizes.today : slot.sizes.sheet99
    }

    /// How a slot is set: the same call the page made before (Today) or the one sheet 99 names.
    enum Face: Sendable {
        case role(TextRole)
        case voice(CGFloat)
        case numeral(CGFloat, Font.Weight)
        case small
    }

    func face(in layout: ReadingLayout) -> Face {
        switch (self, layout) {
        case (.pageHead, .today), (.shopAisle, .today), (.exerciseName, .today): .role(.hero)
        case (.pageHead, .sheet99), (.shopAisle, .sheet99), (.exerciseName, .sheet99): .role(.title)
        case (.aisleHead, .today), (.restoreHead, .today): .role(.title)
        case (.aisleHead, .sheet99): .role(.labelStrong)
        case (.restoreHead, .sheet99): .role(.bodyStrong)
        case (.queueHead, .sheet99): .role(.labelStrong)
        case (.queueDetail, .sheet99), (.note, .sheet99): .role(.label)
        case (.contextLine, .sheet99): .role(.label)
        case (.contextLine, .today), (.detailLine, _), (.queueHead, .today), (.queueDetail, .today):
            .voice(Self.size(self, in: layout))
        case (.todayNumber, _): .numeral(Self.size(self, in: layout), .light)
        case (.rowNumeral, _), (.historyNumber, _): .numeral(Self.size(self, in: layout), .regular)
        case (.historyDate, .sheet99): .role(.body)
        case (.historyDate, .today), (.note, .today): .small
        }
    }
}

private struct ReadingFont: ViewModifier {
    let slot: ReadingSlot
    func body(content: Content) -> some View {
        switch slot.face(in: ReadingLayout.current()) {
        case let .role(role): content.textRole(role)
        case let .voice(size): content.font(Theme.voice(size: size))
        case let .numeral(size, weight): content.font(Theme.numeral(size, weight: weight))
        case .small: content.font(PageType.small)
        }
    }
}

extension View {
    /// Sets a slot's type for the current Reading layout.
    func reading(_ slot: ReadingSlot) -> some View {
        modifier(ReadingFont(slot: slot))
    }

    /// A paragraph column: 330 pt, left aligned, ragged right (sheet 99 A4). Today and above AX2 it has no cap.
    func readingColumn(_ typeSize: DynamicTypeSize) -> some View {
        modifier(ReadingColumn(typeSize: typeSize))
    }
}

private struct ReadingColumn: ViewModifier {
    let typeSize: DynamicTypeSize

    func body(content: Content) -> some View {
        if ReadingLayout.current() == .sheet99, typeSize < .accessibility3 {
            content.frame(maxWidth: 330, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
        } else {
            content
        }
    }
}
