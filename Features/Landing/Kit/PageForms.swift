// swiftlint:disable identifier_name
import CoreGraphics
import SwiftUI

// Sheet 293, page forms (drawn on the Watch's Today). Builder B's room pages choose their rows; this file is the
// shared part: the form enum, the layouts, the by-time order, the Undo line, and the one switch move.

/// The forms of a level 1 page.
enum PageForm: String, CaseIterable, Sendable {
    /// The designed form: row weights 1.7 to 0.84; the first row is 700 in a darkened room colour.
    case ranked
    /// Every row the same height and size; the first keeps its colour but not its weight.
    case even
    /// Names only, two across.
    case columns
    /// A 52 pt time column then the names in time order; offered only where rows have times.
    case byTime

    /// The `ElementForms` name that draws it (ranked, even and by time are all "rows" with traits).
    var elementForm: String {
        self == .columns ? "columns" : "rows"
    }

    /// How the Undo line says it: "Page by time  Undo".
    var phrase: String {
        switch self {
        case .ranked: "ranked"
        case .even: "even"
        case .columns: "in columns"
        case .byTime: "by time"
        }
    }

    /// The Undo line's words: two spaces before Undo. Tess's version names her: "Tess set the page by time  Undo".
    func undoLine(byTess: Bool) -> String {
        byTess ? "Tess set the page \(phrase)  Undo" : "Page \(phrase)  Undo"
    }

    /// Whether the form shows second lines and values (columns leaves them out: it is for finding, not reading).
    var showsDetails: Bool {
        self != .columns
    }
}

/// One row a page hands the switch: its name (the thing that travels, matched by name), its second line or value,
/// and a clock time where it has one.
struct PageFormRow: Identifiable, Equatable, Sendable {
    var name: String
    var detail = ""
    /// Minutes after midnight; nil for a row with no time (done, thirsty).
    var minutes: Int?
    /// A row with no time shows its word at 13 pt in its own colour ("done"); nil otherwise.
    var word: String?

    var id: String {
        name
    }
}

/// Where one row's pieces go in the page frame (page-local coordinates).
struct PageRowPlace: Equatable, Sendable, Identifiable {
    var id: String
    var name: CGRect
    var detail: CGRect?
    var time: CGRect?
    var size: CGFloat
    var bold: Bool
    /// Rows already behind him (no time) are ink 2.
    var behind: Bool
    var weight: CGFloat
}

enum PageForms {
    static let columnWidth: CGFloat = 171
    static let columnGap: CGFloat = 12
    static let columnRow: CGFloat = 22
    static let columnMaxHeight: CGFloat = 76
    static let timeColumn: CGFloat = 52
    static let rankedWeights: ClosedRange<CGFloat> = 0.84 ... 1.7

    /// The rows of a time-ordered page: those with no time first (they are already behind him), then by the next time
    /// each comes after `now`. A bare clock time means its next occurrence, so at 5:10 pm 6:00 is tonight and sorts
    /// before 9:00, which is tomorrow morning.
    static func byTime(_ rows: [PageFormRow], nowMinutes: Int) -> [PageFormRow] {
        let behind = rows.filter { $0.minutes == nil }
        let timed = rows.filter { $0.minutes != nil }.sorted {
            until($0.minutes ?? 0, now: nowMinutes) < until($1.minutes ?? 0, now: nowMinutes)
        }
        return behind + timed
    }

    /// Minutes from `now` to the next occurrence of `clock` (0 is now, so a time exactly now comes first).
    static func until(_ clock: Int, now: Int) -> Int {
        ((clock - now) % 1440 + 1440) % 1440
    }

    /// Whether the page offers the by-time form: only where rows have times.
    static func offersByTime(_ rows: [PageFormRow]) -> Bool {
        rows.contains { $0.minutes != nil }
    }

    /// The row weights of the ranked form, 1.7 down to 0.84 across the rows.
    static func rankedWeight(index: Int, count: Int) -> CGFloat {
        guard count > 1 else { return rankedWeights.upperBound }
        let t = CGFloat(index) / CGFloat(count - 1)
        return rankedWeights.upperBound - t * (rankedWeights.upperBound - rankedWeights.lowerBound)
    }

    /// The places of every row in `frame` (page-local). Names are the matched pieces; details and times fade.
    static func layout(rows: [PageFormRow], form: PageForm, in frame: CGRect, nowMinutes: Int = 0) -> [PageRowPlace] {
        switch form {
        case .ranked: stacked(rows, frame: frame, ranked: true, withTime: false)
        case .even: stacked(rows, frame: frame, ranked: false, withTime: false)
        case .byTime: stacked(byTime(rows, nowMinutes: nowMinutes), frame: frame, ranked: false, withTime: true)
        case .columns: columns(rows, frame: frame)
        }
    }

    private static func stacked(_ rows: [PageFormRow], frame: CGRect, ranked: Bool, withTime: Bool) -> [PageRowPlace] {
        var places: [PageRowPlace] = []
        var y: CGFloat = 0
        let left: CGFloat = withTime ? timeColumn : 0
        for (index, row) in rows.enumerated() {
            let weight = ranked ? rankedWeight(index: index, count: rows.count) : 1
            // 13 pt at the lightest weight up to 24 pt at the heaviest; even rows are 17 pt.
            let size: CGFloat = ranked
                ? 13 + (weight - rankedWeights.lowerBound) / (rankedWeights.upperBound - rankedWeights.lowerBound) * 11
                : 17
            let height = max(28, ceil(size * 1.5))
            let behind = withTime && row.minutes == nil
            let nameWidth = frame.width - left - (row.detail.isEmpty ? 0 : 96)
            places.append(PageRowPlace(
                id: row.id,
                name: CGRect(x: left, y: y, width: nameWidth, height: height),
                detail: row.detail.isEmpty ? nil : CGRect(x: frame.width - 92, y: y, width: 92, height: height),
                time: withTime ? CGRect(x: 0, y: y, width: timeColumn, height: height) : nil,
                size: behind ? 15 : size, bold: ranked && index == 0, behind: behind, weight: weight
            ))
            y += height
        }
        return places
    }

    /// Two columns, 171 pt wide with a 12 pt gap, filled down the left first (3 and 2 for five rows). Rows are 22 pt
    /// and the block is at most 76 pt tall, so at most three rows a column. Names only.
    private static func columns(_ rows: [PageFormRow], frame _: CGRect) -> [PageRowPlace] {
        let perColumn = max(Int(columnMaxHeight / columnRow), 1)
        let leftCount = min(max((rows.count + 1) / 2, 1), perColumn)
        return rows.enumerated().map { index, row in
            let column = index < leftCount ? 0 : 1
            let line = column == 0 ? index : index - leftCount
            return PageRowPlace(
                id: row.id,
                name: CGRect(x: CGFloat(column) * (columnWidth + columnGap), y: CGFloat(line) * columnRow,
                             width: columnWidth, height: columnRow),
                detail: nil, time: nil, size: 15, bold: false, behind: false, weight: 1
            )
        }
    }
}

/// The page's form and its switch: what the row names, the wash and the Undo line do together (sheet 293).
@MainActor @Observable
final class PageFormSwitch {
    private(set) var form: PageForm
    private var previous: PageForm?
    /// The wash over the page while Tess sets a form (600 ms), before the names travel.
    private(set) var washing = false
    private(set) var undoLine: String?
    /// Bumped on every switch, so a view can key its haptic.
    private(set) var changes = 0

    init(form: PageForm = .ranked) {
        self.form = form
    }

    /// Switches the page. By hand the names travel at once; by Tess the wash comes first (600 ms), then the travel,
    /// then the Undo line. `isShown` false sets the form with no frames.
    func set(_ new: PageForm, byTess: Bool, isShown: Bool = true, reduceMotion: Bool = false) async {
        guard new != form else { return }
        previous = form
        if byTess, isShown, !reduceMotion {
            washing = true
            try? await Task.sleep(for: .milliseconds(600))
            washing = false
        }
        let apply = {
            self.form = new
            self.undoLine = new.undoLine(byTess: byTess)
            self.changes += 1
        }
        if isShown {
            withTesseraAnimation(Theme.Motion.travel, reduceMotion: reduceMotion, apply)
        } else {
            apply()
        }
    }

    func undo(reduceMotion: Bool = false) {
        guard let previous else { return }
        withTesseraAnimation(Theme.Motion.travel, reduceMotion: reduceMotion) {
            form = previous
            undoLine = nil
            self.previous = nil
            changes += 1
        }
    }
}

/// The rows of a page in one form. Each row's name is one view, matched by name, so it travels from its place in one
/// form to its place in the next over 520 ms; details and times fade in at 260 ms. Under Reduce Motion the whole
/// page crossfades in 150 ms and nothing travels. Rooms pass their own row drawing for the details they own.
struct PageFormRows: View {
    let rows: [PageFormRow]
    let form: PageForm
    let frame: CGRect
    let color: Color
    var nowMinutes = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.liveScope) private var isShown

    var body: some View {
        let places = PageForms.layout(rows: rows, form: form, in: frame, nowMinutes: nowMinutes)
        ZStack(alignment: .topLeading) {
            ForEach(places) { place in
                name(place)
                if let detail = place.detail, form.showsDetails, let row = rows.first(where: { $0.id == place.id }) {
                    Text(row.detail)
                        .font(.custom("Figtree", fixedSize: 13))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .lineLimit(1)
                        .frame(width: detail.width, height: detail.height, alignment: .trailing)
                        .offset(x: detail.minX, y: detail.minY)
                        .transition(.opacity.animation(Theme.Motion.fadeIn))
                }
                if let time = place.time, let row = rows.first(where: { $0.id == place.id }) {
                    timeText(row, place: time)
                        .transition(.opacity.animation(Theme.Motion.fadeIn))
                }
            }
        }
        .frame(width: frame.width, height: frame.height, alignment: .topLeading)
        .id(reduceMotion ? form.rawValue : "page")
        .transition(.opacity)
        .animation(isShown ? MotionPolicy.resolve(Theme.Motion.travel, reduceMotion: reduceMotion) : nil, value: form)
    }

    private func name(_ place: PageRowPlace) -> some View {
        Text(place.id)
            .font(.custom("Figtree", fixedSize: place.size).weight(place.bold ? .bold : .regular))
            .foregroundStyle(place.behind ? Theme.Colors.inkSecondary : (place.bold ? color : Theme.Colors.ink))
            .lineLimit(1)
            .frame(width: place.name.width, height: place.name.height, alignment: .leading)
            .offset(x: place.name.minX, y: place.name.minY)
    }

    private func timeText(_ row: PageFormRow, place: CGRect) -> some View {
        let word = row.word
        let clock = row.minutes.map { String(format: "%d:%02d", ($0 / 60 + 11) % 12 + 1, $0 % 60) } ?? ""
        return Text(word ?? clock)
            .font(.custom("Outfit", fixedSize: word == nil ? 15 : 13))
            .foregroundStyle(word == nil ? Theme.Colors.inkSecondary : color)
            .lineLimit(1)
            .frame(width: place.width, height: place.height, alignment: .leading)
            .offset(x: place.minX, y: place.minY)
    }
}

/// Tess's wash over the whole page: a 600 ms tint of her colour, a 55% screen blend over type so the type stays
/// readable, gone before the names travel. Reduce Transparency makes it a plain 92% ground dim instead.
struct PageWash: View {
    let active: Bool

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Rectangle()
            .fill(reduceTransparency ? AnyShapeStyle(Theme.Colors.paper.opacity(0.92)) :
                AnyShapeStyle(Theme.Colors.tess))
            .blendMode(reduceTransparency ? .normal : .screen)
            .opacity(active ? (reduceTransparency ? 1 : 0.55) : 0)
            .allowsHitTesting(false)
            .tesseraAnimation(.easeInOut(duration: 0.3), value: active)
            .accessibilityHidden(true)
    }
}
