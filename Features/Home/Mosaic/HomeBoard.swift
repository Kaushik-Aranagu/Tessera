import SwiftUI
import TesseraCore

/// Where a tapped word on the board goes (sheet 212): the date opens Today, a notice's app word opens its room, and
/// "Sunset" goes to the mosaic's weather page (or Today until weather exists).
enum BoardTarget: Equatable {
    case today
    case room(AppID)
    case weather
    /// A moment's own clause (its `opens` is the one link).
    case clause(HomeSentence.Clause)
}

/// One line of the board: its words and where they lead.
struct BoardLine: Equatable {
    var segments: [DepartureSegment]
    var target: BoardTarget
}

/// The three lines of Home (sheet 212): the date, then two notices from a ranked list that rolls every 6 seconds.
/// Core's
/// ranked notices replace the stand-in list here when its PR lands; until then the day's clauses (and the sunset) are
/// the
/// notices. A moment takes the two lines for its run. Private things come through Core already masked.
@MainActor
enum HomeBoard {
    static let rotationSeconds: Double = 6
    static let maxNotices = 6
    static let defaultWidth: CGFloat = 340
    /// The room the top-left Settings word takes from the date's row, plus a gap, so the date never runs into it.
    static let settingsReserve: CGFloat = 104

    /// The date in ink-sky at normal weight; it opens Today. A long date ("Wednesday, September 30") steps down to
    /// shorter forms until its measured width fits its row, clear of the Settings word.
    static func date(now: Date, width: CGFloat = defaultWidth) -> BoardLine {
        let forms: [Date.FormatStyle] = [
            .dateTime.weekday(.wide).month(.wide).day(),
            .dateTime.weekday(.wide).month(.abbreviated).day(),
            .dateTime.weekday(.abbreviated).month(.abbreviated).day(),
            .dateTime.month(.abbreviated).day(),
        ]
        let room = width - settingsReserve
        var text = now.formatted(forms[0])
        for form in forms {
            text = now.formatted(form)
            if CellMetrics.lineWidth([DepartureSegment(text: text, kind: .day)]) <= room {
                break
            }
        }
        return BoardLine(segments: [DepartureSegment(text: text, kind: .day, opens: true)], target: .today)
    }

    /// Core's ranked notices as board lines. A notice goes to its own `target` (never `clause.opens`, which Core marks
    /// unused); the app word opens its room, and "Sunset" is painted with the sky and goes to the weather.
    static func notices(from list: [HomeNotice], width: CGFloat = defaultWidth) -> [BoardLine] {
        // Every notice stays: it shows its longest form that fits its row (its short form drops trailing words), never
        // shrunk and never an ellipsis.
        list.prefix(maxNotices).map(line(of:)).map { cut($0, width: width) }
    }

    /// Whether the line, measured in its faces (bold keywords at 1.12x included), fits its row.
    static func fits(_ line: BoardLine, width: CGFloat = defaultWidth) -> Bool {
        CellMetrics.lineWidth(line.segments) <= width
    }

    /// Drops words from the end until the line fits (at least one word stays).
    static func cut(_ line: BoardLine, width: CGFloat = defaultWidth) -> BoardLine {
        var line = line
        while !fits(line, width: width), DepartureSteps.flat(line.segments).contains(" ") {
            var last = line.segments.removeLast()
            var words = last.text.split(separator: " ").map(String.init)
            if words.count > 1 {
                words.removeLast()
                last.text = words.joined(separator: " ")
                line.segments.append(last)
            }
        }
        return line
    }

    private static func line(of notice: HomeNotice) -> BoardLine {
        let target: BoardTarget = switch notice.target {
        case let .room(app): .room(app)
        case .today: .today
        case .weather: .weather
        }
        if notice.target == .weather, let source = notice.sourceWord, notice.text.hasPrefix(source) {
            let rest = String(notice.text.dropFirst(source.count)).trimmingCharacters(in: .whitespaces)
            var segments = [DepartureSegment(text: source, kind: .sky, opens: true)]
            for word in rest.split(separator: " ") {
                let kind: DepartureSegment.Kind = word.contains(where: \.isNumber) ? .number : .plain
                if let last = segments.last, last.kind == kind, segments.count > 1 {
                    segments[segments.count - 1].text += " " + word
                } else {
                    segments.append(DepartureSegment(text: String(word), kind: kind))
                }
            }
            return BoardLine(segments: segments, target: target)
        }
        return BoardLine(segments: DepartureLines.segments(of: notice.clause), target: target)
    }

    /// The three lines at `rotation`: the date; the notice at `rotation` and the one after it (wrapping). A moment's
    /// own
    /// clause takes both lines while it runs.
    static func lines(date: BoardLine, notices: [BoardLine], rotation: Int,
                      moment: HomeSentence.Clause?) -> [BoardLine]
    {
        if let moment {
            return [date, BoardLine(segments: DepartureLines.segments(of: moment), target: .clause(moment)), blank]
        }
        guard !notices.isEmpty else {
            return [date, BoardLine(segments: [DepartureSegment(text: HomeSentence.quietDay, kind: .plain)],
                                    target: .today), blank]
        }
        guard notices.count > 1 else { return [date, notices[0], blank] }
        let top = ((rotation % notices.count) + notices.count) % notices.count
        return [date, notices[top], notices[(top + 1) % notices.count]]
    }

    static let blank = BoardLine(segments: [DepartureSegment(text: " ", kind: .plain)], target: .today)
}
