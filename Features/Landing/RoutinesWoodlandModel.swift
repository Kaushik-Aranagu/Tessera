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
    /// 268 v4: tall poplar and the flat purple jacaranda (drawn as broadleaf variants).
    case poplar, jacaranda
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
    /// Its steps, drawn as buds (268): N buds on an N-step routine.
    var steps = 0
    /// A planned rest today (a fixed-days routine off today): a lamp hangs in the tree and it keeps its leaves.
    var restToday = false

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

    /// Three rows (268): back 0.5, mid 0.72, front about 1.0, with the lake keeping the middle clear. Small counts
    /// stand in the near groves; nothing stands in the outer fade, so the dissolving edge never ghosts a routine.
    static func places(count: Int) -> [WoodlandPlace] {
        let small: [[CGFloat]] = switch count {
        case 1: [[84, 146, 0.98]]
        case 2: [[78, 131, 0.72], [116, 150, 0.94]]
        case 3: [[78, 131, 0.72], [116, 150, 0.94], [262, 140, 0.86]]
        case 4: [[78, 131, 0.72], [116, 150, 0.94], [262, 131, 0.72], [244, 150, 0.94]]
        default: []
        }
        let wide: [[CGFloat]] = [
            [86, 131, 0.72], [268, 131, 0.72], [62, 150, 1], [298, 149, 1],
            [46, 129, 0.72], [312, 128, 0.72], [116, 151, 0.94], [246, 150, 0.94],
            [70, 109, 0.5], [126, 105, 0.5], [234, 106, 0.5], [290, 110, 0.5],
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

// MARK: - Light from the real hour (268)

// swiftlint:disable identifier_name -- short drawing names, as in the painter

/// The one light of the scene, keyframed by the hour: the sky's three stops, how dim the land is, how warm the light
/// is, and where the sun or the moon stands (scene points, 354 x 160).
struct WoodlandLight: Equatable, Sendable {
    let sky: [UInt32]
    let dim: Double
    let warmth: Double
    let sun: CGPoint?
    let moon: CGPoint?

    var isNight: Bool {
        dim >= 0.45
    }

    /// The side the light comes from: 1 from the right, -1 from the left.
    var side: CGFloat {
        guard let from = sun ?? moon else { return 1 }
        return from.x >= 177 ? 1 : -1
    }

    private static let night: [UInt32] = [0x1B2638, 0x2E3B4A, 0x3E4636]
    private static let dawn: [UInt32] = [0xC9CFE0, 0xF2CDB0, 0xE0C9A0]
    private static let day: [UInt32] = [0xD6E6EC, 0xEDEAD2, 0xD9D6AB]
    private static let golden: [UInt32] = [0xE7D9C0, 0xF3C994, 0xD8B98A]
    private static let dusk: [UInt32] = [0x6E6A8A, 0xD49A86, 0x8D7F6A]

    private static let keys: [(hour: Double, sky: [UInt32], dim: Double, warmth: Double)] = [
        (0, night, 0.6, 0), (5, night, 0.6, 0), (6.5, dawn, 0.15, 0.4), (8, day, 0, 0.05), (16, day, 0, 0.1),
        (18, golden, 0.05, 0.6), (19.5, dusk, 0.3, 0.4), (21, night, 0.6, 0), (24, night, 0.6, 0),
    ]

    /// The light at an hour of the day (0 to 24, fractional).
    static func at(hour raw: Double) -> WoodlandLight {
        let hour = (raw.truncatingRemainder(dividingBy: 24) + 24).truncatingRemainder(dividingBy: 24)
        let upper = keys.firstIndex { $0.hour > hour } ?? keys.count - 1
        let a = keys[max(0, upper - 1)], b = keys[upper]
        let u = b.hour > a.hour ? (hour - a.hour) / (b.hour - a.hour) : 0
        let sky = zip(a.sky, b.sky).map { mix($0, $1, u) }
        var sun: CGPoint?
        if hour >= 6, hour <= 20 {
            let v = (hour - 6) / 14
            sun = CGPoint(x: 20 + v * 314, y: 62 - sin(.pi * v) * 46)
        }
        var moon: CGPoint?
        if hour >= 19.5 || hour <= 6.5 {
            let v = ((hour - 19.5 + 24).truncatingRemainder(dividingBy: 24)) / 11
            moon = CGPoint(x: 20 + v * 314, y: 60 - sin(.pi * v) * 40)
        }
        return WoodlandLight(sky: sky, dim: a.dim + (b.dim - a.dim) * u, warmth: a.warmth + (b.warmth - a.warmth) * u,
                             sun: sun, moon: moon)
    }

    private static func mix(_ x: UInt32, _ y: UInt32, _ u: Double) -> UInt32 {
        var out: UInt32 = 0
        for shift in [16, 8, 0] as [UInt32] {
            let p = Double((x >> shift) & 0xFF), q = Double((y >> shift) & 0xFF)
            out |= UInt32((p + (q - p) * u).rounded()) << shift
        }
        return out
    }
}
