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
enum HomeBoard {
    static let rotationSeconds: Double = 6
    static let maxNotices = 6

    /// "Friday, October 23" in ink at normal weight, no underline; it opens Today.
    static func date(now: Date) -> BoardLine {
        let text = now.formatted(.dateTime.weekday(.wide).month(.wide).day())
        return BoardLine(segments: [DepartureSegment(text: text, kind: .plain, opens: true)], target: .today)
    }

    /// Core's ranked notices as board lines. A notice goes to its own `target` (never `clause.opens`, which Core marks
    /// unused); the app word opens its room, and "Sunset" is painted with the sky and goes to the weather.
    static func notices(from list: [HomeNotice]) -> [BoardLine] {
        list.prefix(maxNotices).map { notice in
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
