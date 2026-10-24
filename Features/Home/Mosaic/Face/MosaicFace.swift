import Foundation
import TesseraCore

// Home 236 v2.1: the mosaic as a stack of faces. Each face is a picture the mosaic window shows, and each grows to the
// left from the right margin by its own width in tiles. Faces, in order: Now (the board's latest announcement played as
// pixels), Gallery (pixel scenes by time, weather and place type), Weather, Workout. More apps come later.
// Privacy: no money, health, body or calories ever reach a face; a private item is its masked label; none of a face's
// numbers or words is stored, logged or backed up (a face is a value in memory, rebuilt each minute).

enum MosaicFaceKind: String, CaseIterable, Equatable, Sendable {
    case now, gallery, weather, workout

    /// Width in tiles; the face grows left from the right margin.
    var width: Int {
        switch self {
        case .now, .gallery: 88
        case .weather: 84
        case .workout: 72
        }
    }

    /// The switch in Settings > Home > Mosaic. Every face defaults to On.
    var switchID: String {
        "homeFace.\(rawValue)"
    }

    var name: String {
        switch self {
        case .now: "Now"
        case .gallery: "Gallery"
        case .weather: "Weather"
        case .workout: "Workout"
        }
    }

    /// The room a tap opens, when the face has no more particular one (Now opens its announcement's room).
    var room: HomeLink {
        switch self {
        case .now, .gallery, .weather: .today
        case .workout: .training
        }
    }

    /// The widest any face is, in tiles.
    static let widest = MosaicFaceKind.allCases.map(\.width).max() ?? 88
}

/// What Now plays: the board's latest announcement as a drawing. Rain falls for "Rain from 4 PM", a bag for Rice, a
/// barbell for Bench, a case for Packing.
enum MosaicNowKind: String, Equatable, Sendable {
    case rain, sun, bag, barbell, suitcase, clock

    /// The drawing for a board notice, and the room a tap on it opens. Money is never drawn; a notice with no
    /// drawing (Notes) shows no Now face.
    static func of(_ notice: HomeNotice) -> (kind: MosaicNowKind, opens: HomeLink)? {
        switch notice.target {
        case .weather:
            let text = notice.text.lowercased()
            let wet = ["rain", "snow", "shower", "storm", "drizzle"].contains { text.contains($0) }
            return (wet ? .rain : .sun, .today)
        case .today:
            return (.clock, .today)
        case let .room(app):
            switch app {
            case .kitchen: return (.bag, .groceries)
            case .training: return (.barbell, .training)
            case .lists: return (.suitcase, .lists)
            case .routines: return (.clock, .today)
            case .money, .notes: return nil
            }
        }
    }
}

struct MosaicNowReading: Equatable {
    var kind: MosaicNowKind
    var opens: HomeLink
}

/// Weather as the face reads it: a sample on the device until Core's source lands and he approves it.
struct MosaicWeatherReading: Equatable {
    struct Change: Equatable {
        var word: String
        var hour: Int
    }

    /// Whole degrees in `unit`.
    var temperature: Int
    var fahrenheit: Bool
    var condition: SceneWeather
    var next: Change?
    /// The week's seven daily highs, today first.
    var week: [Int]
    var isSample: Bool
}

@MainActor
protocol MosaicWeatherSource {
    func reading(now: Date) -> MosaicWeatherReading?
}

/// The numbers on the device until a real source is approved: they follow the hour and the day, deterministic, and say
/// so (`isSample`). Core's need: a WeatherKit-backed source (entitlement) behind `MosaicWeatherSource`.
struct SampleWeatherSource: MosaicWeatherSource {
    var fahrenheit = Locale.current.measurementSystem == .us

    func reading(now: Date) -> MosaicWeatherReading? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let day = calendar.ordinality(of: .day, in: .era, for: now) ?? 0
        // 11 to 24 C by day with a gentle afternoon peak.
        let base = 11 + (day * 5) % 9
        let swing = Int((6 * sin((Double(hour) - 9) / 24 * 2 * Double.pi)).rounded())
        let celsius = base + 4 + swing
        let condition: SceneWeather = day % 7 == 3 ? .rain : (day % 11 == 5 ? .snow : .clear)
        let convert: (Int) -> Int = { fahrenheit ? Int((Double($0) * 9 / 5 + 32).rounded()) : $0 }
        let change: MosaicWeatherReading.Change? = switch condition {
        case .clear: day % 2 == 0 ? .init(word: "Rain", hour: (hour + 4) % 12 == 0 ? 12 : (hour + 4) % 12) : nil
        case .rain: .init(word: "Dry", hour: (hour + 3) % 12 == 0 ? 12 : (hour + 3) % 12)
        case .snow: .init(word: "Clear", hour: (hour + 5) % 12 == 0 ? 12 : (hour + 5) % 12)
        }
        let week = (0 ..< 7).map { convert(base + 6 + (($0 * 3 + day) % 5) - 2) }
        return MosaicWeatherReading(temperature: convert(celsius), fahrenheit: fahrenheit, condition: condition,
                                    next: change, week: week, isSample: true)
    }
}

/// A live workout as the face reads it. No set, weight, heart or body number: only whether it is going, how long, and
/// the rest countdown.
struct MosaicWorkoutReading: Equatable {
    var startedAt: Date
    var restEndsAt: Date?
    var restTotal: TimeInterval

    /// Seconds of rest left at `now`, nil when not resting.
    func restLeft(at now: Date) -> Int? {
        guard let restEndsAt, restEndsAt > now else { return nil }
        return Int(restEndsAt.timeIntervalSince(now).rounded(.up))
    }

    func minutes(at now: Date) -> Int {
        max(Int(now.timeIntervalSince(startedAt) / 60), 0)
    }
}

/// One face, with what it draws. Equatable so the layer retargets only when a face really changed; a value in memory,
/// never Codable.
struct MosaicFace: Equatable {
    var kind: MosaicFaceKind
    var scenery: MosaicScenery?
    var now: MosaicNowReading?
    var weather: MosaicWeatherReading?
    var workout: MosaicWorkoutReading?

    /// The tile width of the window for this face.
    var width: Int {
        kind.width
    }

    /// Whether the face is showing something live (a workout going, an announcement playing).
    var isLive: Bool {
        switch kind {
        case .workout: workout != nil
        case .now: now != nil
        case .gallery, .weather: false
        }
    }

    /// The room a tap opens.
    var room: HomeLink {
        kind == .now ? now?.opens ?? kind.room : kind.room
    }

    /// What VoiceOver says for the face: words only, no numbers it should not have.
    var spoken: String {
        switch kind {
        case .now: "Now. The latest on the board, drawn."
        case .gallery: "Gallery. A picture of the hour."
        case .weather: weather.map { "Weather. \($0.temperature) degrees." } ?? "Weather."
        case .workout: "Workout, going."
        }
    }
}

/// What a page hands the stack when it refreshes.
struct MosaicFaceInputs {
    var scenery: MosaicScenery?
    var announcement: MosaicNowReading?
    var weather: MosaicWeatherReading?
    var workout: MosaicWorkoutReading?
}

enum MosaicFaceStack {
    /// Whether a face's switch is On.
    @MainActor static func isOn(_ kind: MosaicFaceKind) -> Bool {
        ReviewChoices.shared.value(of: kind.switchID) != "Off"
    }

    /// Faces in order, each only while its switch is On and it has what it draws. Weather waits for a reading, Workout
    /// for a workout, Now for an announcement (graceful absence: a face with nothing to show is not in the stack).
    static func faces(_ inputs: MosaicFaceInputs, on: (MosaicFaceKind) -> Bool) -> [MosaicFace] {
        MosaicFaceKind.allCases.compactMap { kind in
            guard on(kind) else { return nil }
            switch kind {
            case .now:
                return inputs.announcement.map { MosaicFace(kind: kind, now: $0) }
            case .gallery:
                return inputs.scenery.map { MosaicFace(kind: kind, scenery: $0) }
            case .weather:
                return inputs.weather.map { MosaicFace(kind: kind, weather: $0) }
            case .workout:
                return inputs.workout.map { MosaicFace(kind: kind, workout: $0) }
            }
        }
    }
}

/// The gallery's run of scenes for the hour (Home 236: a new one about every 9 s). The picker's own choice leads; a
/// pinned scene is the only one; the mood stripes mean no gallery at all.
enum MosaicGallery {
    static func sequence(backdrop: MosaicBackdrop, pick: MosaicScenery?, phase: DayPhase) -> [MosaicScenery] {
        guard let pick else { return [] }
        if case .pinned = backdrop {
            return [pick]
        }
        let hour: [MosaicScenery] = switch phase {
        case .night: [.nightSky, .cityAtDusk, .harbor, .rainOnWindow, .snow]
        case .dawn: [.fieldsAtSunrise, .mountainsAndLake, .beach, .woods]
        case .golden: [.cityAtDusk, .harbor, .desert, .autumnTrees, .beach]
        case .day: [.beach, .mountainsAndLake, .woods, .harbor, .desert, .autumnTrees]
        }
        return [pick] + hour.filter { $0 != pick }
    }
}
