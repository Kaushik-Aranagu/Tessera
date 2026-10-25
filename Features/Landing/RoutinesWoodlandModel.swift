import CoreGraphics
import Foundation

// The Routines woodland's facts (sheet 248): every routine is a plant; its stage comes from the days it was kept and
// its health from the recent log. Pure values, no drawing, so the thresholds are testable on their own.

/// One day (or week) of a routine's log, oldest first: kept, let slip, or not due (rest or still open today).
enum WoodlandMark: Equatable, Sendable {
    case kept, slipped, open
}

/// Health from the recent log (sheet 248, `healthMetrics`): three slips in a row, or three in the last seven, is
/// "needs care" (withering); eight in a row is "begin again" (bare). One kept day cannot undo a week of slips.
struct WoodlandHealth: Equatable, Sendable {
    let misses: Int
    let consecutive: Int

    init(marks: [WoodlandMark]) {
        misses = marks.suffix(7).filter { $0 == .slipped }.count
        var run = 0
        for mark in marks.reversed() {
            if mark == .kept {
                break
            }
            if mark == .slipped {
                run += 1
            }
        }
        consecutive = run
    }

    var isBare: Bool {
        consecutive >= 8
    }

    var isWithering: Bool {
        !isBare && (consecutive >= 3 || misses >= 3)
    }
}

/// The plant's size class (sheet 248, `growthInfo` and `habitSize`).
enum WoodlandStage: String, Equatable, Sendable {
    case sprout, smallPlant, mediumPlant, tree

    /// Sprout below day 3, small plant from 3, medium from 7, tree from 28.
    static func of(days: Int) -> WoodlandStage {
        days < 3 ? .sprout : days < 7 ? .smallPlant : days < 28 ? .mediumPlant : .tree
    }

    /// The prototype's height units before the importance ceiling.
    static func height(days: Int) -> CGFloat {
        let day = CGFloat(days)
        switch of(days: days) {
        case .sprout: return 14 + day * 2
        case .smallPlant: return 25 + (day - 3) * 2
        case .mediumPlant: return 38 + (day - 7) * 0.8
        case .tree: return 76 + min(28, day - 28)
        }
    }
}

/// The plant species: shape only; colour is chosen separately so neighbours never share a family.
enum WoodlandSpecies: Int, CaseIterable, Sendable {
    case willow, maple, birch, pine, oak, citrus, cherry
}

/// The colour families of the prototype (blue only at the outer edges).
enum WoodlandFamily: Int, CaseIterable, Sendable {
    case green, violet, rose, pearl, gold, blue
}

/// One plant in the woodland.
struct WoodlandTree: Identifiable, Equatable, Sendable {
    let id: UUID
    /// "Private routine" when walled; the plant still grows (on this phone only).
    let name: String
    let isPrivate: Bool
    /// Days kept, all time.
    let days: Int
    /// The log, oldest first, at least the last seven.
    let marks: [WoodlandMark]
    let doneToday: Bool
    let dueToday: Bool
    /// The size ceiling (32 small plant, 46 shrub, 68 small tree, 104 canopy tree).
    let cap: CGFloat
    let species: WoodlandSpecies

    var health: WoodlandHealth {
        WoodlandHealth(marks: marks)
    }

    var stage: WoodlandStage {
        WoodlandStage.of(days: days)
    }

    var height: CGFloat {
        min(WoodlandStage.height(days: days), cap)
    }

    /// Fruit starts one week after the tree stage (day 35) and comes once a week while healthy.
    var fruitCycle: Int {
        max(0, (days - 28) / 7)
    }

    var hasFruit: Bool {
        !health.isWithering && !health.isBare && fruitCycle > 0
    }

    /// A nest on trees from day 30.
    var hasNest: Bool {
        days >= 30 && height > 47
    }

    /// Small (drawn as a bush) until it is a tree and its ceiling allows one.
    var isBush: Bool {
        days < 28 || cap <= 46
    }

    /// The stage in plain words, with the importance ceiling: a steady small habit can stay a shrub.
    var stageWords: String {
        if cap <= 32, days >= 7 {
            return "small plant"
        }
        if cap <= 46, days >= 7 {
            return "shrub"
        }
        if cap <= 68, days >= 28 {
            return "small tree"
        }
        switch stage {
        case .sprout: return "sprout"
        case .smallPlant: return "small plant"
        case .mediumPlant: return "young plant"
        case .tree: return "tree"
        }
    }

    /// The soft word for its state, never "missed" or "dead" (248).
    var stateWords: String? {
        if health.isBare {
            return "begin again"
        }
        if health.isWithering {
            return "needs a little care"
        }
        if hasFruit {
            return "fruit to collect"
        }
        if doneToday {
            return "done today"
        }
        return nil
    }
}

// MARK: - Reading the log

enum WoodlandLog {
    /// The marks for a routine, oldest first. Daily routines and fixed-days routines are read by day (a due day with
    /// no run is a slip; today stays open until it ends); a weekly routine on a rolling plan is read by week.
    static func marks(runDays: Set<Date>, daily: Bool, weekdays: Set<Int>, today: Date, span: Int = 30,
                      calendar: Calendar = .current) -> [WoodlandMark]
    {
        let day = TesseraDayMath(calendar: calendar)
        if daily || !weekdays.isEmpty {
            return (0 ..< span).reversed().map { back in
                let date = day.adding(-back, to: today)
                if runDays.contains(date) {
                    return .kept
                }
                let due = daily || weekdays.contains(calendar.component(.weekday, from: date))
                return due && back > 0 ? .slipped : .open
            }
        }
        // Weekly: each 7-day window ending today is one mark; this week stays open until kept.
        return (0 ..< span).reversed().map { back in
            let end = day.adding(-7 * back, to: today)
            let kept = (0 ..< 7).contains { runDays.contains(day.adding(-$0, to: end)) }
            if kept {
                return .kept
            }
            return back > 0 ? .slipped : .open
        }
    }

    static func isDue(today: Date, daily: Bool, weekdays: Set<Int>, calendar: Calendar = .current) -> Bool {
        daily || weekdays.contains(calendar.component(.weekday, from: today))
    }

    /// Importance sets the ceiling: a routine with one or two steps stays a shrub, three or four a small tree.
    static func cap(steps: Int) -> CGFloat {
        steps <= 2 ? 46 : steps <= 4 ? 68 : 104
    }

    /// A stable species from the id, so a plant keeps its shape across launches.
    static func species(_ id: UUID) -> WoodlandSpecies {
        let sum = id.uuidString.utf8.reduce(0) { ($0 &* 31 &+ Int($1)) & 0xFFFF }
        return WoodlandSpecies.allCases[sum % WoodlandSpecies.allCases.count]
    }
}

/// Day arithmetic on calendar days (Tessera days are already normalized by the caller).
struct TesseraDayMath {
    let calendar: Calendar

    func adding(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
}

// MARK: - Layout

/// Where a plant stands in the 354 x 160 scene: x, the ground line, and its scale (sheet 248, `layoutGarden`). The
/// lake keeps the middle clear until the forest fills; up to 12 plants show, every one with its own tap target.
struct WoodlandPlace: Equatable, Sendable {
    let x: CGFloat
    let base: CGFloat
    let scale: CGFloat
}

enum WoodlandLayout {
    static let sceneSize = CGSize(width: 354, height: 160)
    static let capacity = 12

    /// The prototype's spots: small beds for one to four, then the two groves either side of the lake, then the far
    /// edges and the back of the clearing.
    static func places(count: Int) -> [WoodlandPlace] {
        let small: [[CGFloat]] = switch count {
        case 1: [[65, 135, 0.98]]
        case 2: [[61, 116, 0.75], [109, 126, 0.86]]
        case 3: [[61, 116, 0.75], [109, 126, 0.86], [61, 150, 0.82]]
        case 4: [[61, 116, 0.75], [109, 126, 0.86], [61, 150, 0.82], [114, 150, 0.8]]
        default: []
        }
        let wide: [[CGFloat]] = [
            [43, 112, 0.72], [77, 133, 0.83], [260, 112, 0.72], [294, 132, 0.83],
            [50, 150, 0.96], [258, 149, 0.96], [110, 149, 0.86], [318, 148, 0.85],
            [125, 104, 0.62], [232, 106, 0.62], [18, 128, 0.7], [338, 124, 0.66],
        ]
        let chosen = count <= 4 ? small : Array(wide.prefix(min(count, capacity)))
        return chosen.map { WoodlandPlace(x: $0[0], base: $0[1], scale: $0[2]) }
    }

    /// Neighbouring plants never share a colour family; blue only at the outer edges.
    static func families(for places: [WoodlandPlace]) -> [WoodlandFamily] {
        let preferred: [WoodlandFamily] = [.green, .rose, .violet, .pearl, .gold, .green, .rose, .violet, .pearl,
                                           .gold, .rose, .green]
        var chosen: [WoodlandFamily] = []
        for (index, place) in places.enumerated() {
            let near = places.prefix(index).enumerated().filter { _, other in
                abs(other.x - place.x) < 56 && abs(other.base - place.base) < 40
            }.map { chosen[$0.offset] }
            let edge = place.x < 30 || place.x > 330
            let first = edge ? WoodlandFamily.blue : preferred[index % preferred.count]
            let options = [first] + WoodlandFamily.allCases.filter { $0 != first && $0 != .blue }
            chosen.append(options.first { !near.contains($0) } ?? first)
        }
        return chosen
    }
}
