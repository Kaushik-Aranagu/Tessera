import Foundation

/// One notice for Home's departure board (sheet 212): a complete sentence ending with a period, with the app word
/// marked
/// so it can be highlighted ("Push day at 6:30 pm.", "Groceries, 4 to get.", "Sunset at 6:34 pm.", "Packing, 6 of 14
/// done."). The clause is the day sentence's own type: its key word is the app word, and a private or masked item is
/// plain text with no key word. No money amount, health, body, calorie or calendar title ever appears.
public struct HomeNotice: Equatable, Sendable {
    /// Where tapping the notice goes. A static map for now (an app's room, Today, or the weather page); later Tess
    /// picks
    /// the targets on the phone.
    public enum Target: Equatable, Sendable {
        case room(AppID)
        case today
        case weather
    }

    /// The sentence. `clause.opens` is unused for notices: a tap goes to `target`, which is the one link.
    public let clause: HomeSentence.Clause
    /// When it happens today, nil for a notice with no time.
    public let time: Date?
    public let target: Target

    /// The word to highlight, the source of the notice: the app word, nil for a plain or private one.
    public var sourceWord: String? {
        clause.keyWord.flatMap { range in
            String(decoding: Array(clause.text.utf16.dropFirst(range.lowerBound).prefix(range.count)), as: UTF16.self)
        }
    }

    public var text: String {
        clause.text
    }
}

@MainActor
public enum HomeNotices {
    public static let limit = 6

    /// Soonest first, then what has no time in a fixed order of importance, then what is already behind him; at most
    /// six.
    public static func ranked(engine: ActionEngine, facts: MosaicFacts, plan: ObjectRecord?,
                              moneyDue: HomeSentence.MoneyDue? = nil, routines: HomeSentence.RoutinesPart? = nil,
                              calendar: Calendar = .current, limit: Int = HomeNotices.limit) -> [HomeNotice]
    {
        let now = facts.now
        var notices: [(notice: HomeNotice, order: Int)] = []
        // Importance of what has no time, lower first.
        let importance: [AppSummaryApp: Int] = [.kitchen: 0, .lists: 1, .tasks: 2, .routines: 3, .training: 4,
                                                .money: 5, .notes: 6]
        for line in AppSummaryLines.lines(engine: engine, plan: plan, moneyDue: moneyDue, routines: routines,
                                          now: now, calendar: calendar)
        {
            guard let text = sentence(for: line, engine: engine) else { continue }
            notices.append((notice(text, line: line), importance[line.app] ?? 9))
        }
        // The next thing he has on (a task, training or a routine), unless it is already a notice.
        // "Already a notice" is by time and app, not by words: a masked title would match nothing or the wrong thing.
        if let next = facts.pageNext, !notices.contains(where: { entry in
            // The same minute AND the same app: two different things in one minute both stay.
            let sameTime = entry.notice.time.map { abs($0.timeIntervalSince(next.start)) < 60 } ?? false
            return (sameTime && entry.notice.clause.app == next.app) || entry.notice.text.hasPrefix(next.title)
        }) {
            let text = "\(next.title) at \(HouseTime.clock(next.start, calendar: calendar))."
            let clause = HomeSentence.Clause(
                app: next.app, sentence: LandingSentence(text: text, key: next.app == nil ? nil : next.title),
                opens: .app(next.app ?? .notes), time: next.start
            )
            notices.append((HomeNotice(clause: clause, time: next.start,
                                       target: next.app.map { .room($0) } ?? .today), 3))
        }
        // The next turn of the sun.
        if let sun = nextSun(facts) {
            let text = "\(sun.name) at \(HouseTime.clock(sun.time, calendar: calendar))."
            notices.append((HomeNotice(clause: HomeSentence.Clause(
                app: nil, sentence: LandingSentence(text: text, key: nil), opens: .app(.notes), time: sun.time
            ), time: sun.time, target: .weather), 8))
        }
        let ahead = notices.filter { ($0.notice.time ?? now) >= now }
        let timed = ahead.filter { $0.notice.time != nil }.sorted { ($0.notice.time ?? now) < ($1.notice.time ?? now) }
        let untimed = ahead.filter { $0.notice.time == nil }.sorted { $0.order < $1.order }
        let behind = notices.filter { ($0.notice.time ?? now) < now }.sorted { $0.order < $1.order }
        // Several private things all read "Private.": one is enough, the rest say nothing new.
        var seenPrivate = false
        let ordered = (timed + untimed + behind).map(\.notice).filter { notice in
            guard notice.text == "Private." else { return true }
            defer { seenPrivate = true }
            return !seenPrivate
        }
        return Array(ordered.prefix(max(0, limit)))
    }

    private static func nextSun(_ facts: MosaicFacts) -> (name: String, time: Date)? {
        if facts.now < facts.sunrise {
            return ("Sunrise", facts.sunrise)
        }
        if facts.now < facts.sunset {
            return ("Sunset", facts.sunset)
        }
        return nil
    }

    /// The line as a complete sentence, or nil for an empty state that is not worth a notice.
    private static func sentence(for line: AppSummaryLine, engine _: ActionEngine) -> String? {
        let text = line.text
        if text.hasPrefix("Nothing") || text.hasPrefix("No ") || text == "Rest day" {
            return nil
        }
        // Groceries with no dish: "4 to get" reads "Groceries, 4 to get."
        if line.app == .kitchen, text.hasSuffix(" to get"), text.first?.isNumber == true {
            return "Groceries, \(text)."
        }
        return text + "."
    }

    private static func notice(_ text: String, line: AppSummaryLine) -> HomeNotice {
        // The app word is the name before the first delimiter. A private item, a task count and a bare number have
        // none.
        var key: String?
        if !line.isPrivate, line.app != .tasks {
            let cuts = [" at ", ", ", " is due", " tonight", " today"].compactMap { text.range(of: $0)?.lowerBound }
            let end = cuts.min() ?? text.index(before: text.endIndex)
            let name = String(text[..<end])
            if !name.isEmpty, !(name.first?.isNumber ?? true) {
                key = name
            }
        }
        let app: AppID? = switch line.app {
        case .training: .training
        case .kitchen: .kitchen
        case .routines: .routines
        case .notes: .notes
        case .lists: .lists
        case .money: .money
        case .tasks: nil
        }
        let clause = HomeSentence.Clause(app: app, sentence: LandingSentence(text: text, key: key), opens: line.opens,
                                         time: line.time)
        // A task count goes to Today; everything else to its app's room.
        return HomeNotice(clause: clause, time: line.time, target: app.map { .room($0) } ?? .today)
    }
}
