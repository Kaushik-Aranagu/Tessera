import SwiftUI
import TesseraCore

/// Where a tapped word on the board goes (sheet 212): the date opens Today, a notice's app word opens its room, and
/// "Sunset" goes to the mosaic's weather page (or Today until weather exists).
enum BoardTarget: Equatable {
    case today
    case clause(HomeSentence.Clause)
    case sky
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

    /// The stand-in notices: each day clause, then "Sunset at 6:34 pm." while the sun has yet to set.
    static func notices(clauses: [HomeSentence.Clause], sunset: Date?, now: Date) -> [BoardLine] {
        var out = clauses.map { BoardLine(segments: DepartureLines.segments(of: $0), target: .clause($0)) }
        if let sunset, sunset > now {
            out.append(BoardLine(segments: [
                DepartureSegment(text: "Sunset", kind: .sky, opens: true),
                DepartureSegment(text: "at", kind: .plain),
                DepartureSegment(text: Format.clock(sunset).replacingOccurrences(of: " pm", with: ""), kind: .number),
                DepartureSegment(text: Format.clock(sunset).hasSuffix("pm") ? "pm." : "am.", kind: .plain),
            ], target: .sky))
        }
        return Array(out.prefix(maxNotices))
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
