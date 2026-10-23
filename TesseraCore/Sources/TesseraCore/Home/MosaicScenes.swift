import Foundation

/// The scenery of the mosaic gallery (sheet 214; "scene" in the sheet, `MosaicScenery` here because `MosaicScene` is a
/// caption). New content beside the nine moods: a scene never replaces a mood, a
/// moment or a changeover; it is only what the mosaic shows when no mood stripe is chosen.
public enum MosaicScenery: String, CaseIterable, Sendable {
    case cityAtDusk, beach, mountainsAndLake, woods, desert, rainOnWindow, nightSky, fieldsAtSunrise
    case snow, harbor, autumnTrees
}

/// The kind of place, in six words. Never a city's name, never a coordinate: only one of these.
public enum PlaceKind: String, CaseIterable, Sendable {
    case coast, city, mountains, desert, woods, plains
}

/// Today's weather for picking a scene. Clear until WeatherKit is entitled: the host passes nil and the pick follows
/// the hour (and the place, when he allowed it).
public enum SceneWeather: String, Sendable {
    case clear, rain, snow
}

/// Which part of the day it is, from today's sunrise and sunset.
public enum DayPhase: String, Sendable {
    case dawn, day, golden, night
}

/// The kind of place from a coarse location, on the phone, from a small bundled table of numbers. No network lookup, no
/// geocoder, no name: the table holds a latitude, a longitude and a kind, nothing else. Rules for the host: ask for
/// When In Use permission with reduced accuracy the first time the gallery opens (never at launch), read at most once a
/// day, call `kind(latitude:longitude:)` and drop the coordinate in the same function. The coordinate and the kind are
/// never stored, logged, backed up, sent to Claude or paired with any of his data, and the kind never reaches a Claude
/// line, the op log, a widget or the Lock Screen (a test scans for the type).
public enum PlaceKinds {
    private typealias Anchor = (latitude: Double, longitude: Double, kind: PlaceKind)

    /// Coarse anchors, kinds only. The nearest one decides.
    private static let anchors: [Anchor] = [
        // coast
        (37.7, -122.6, .coast), (33.7, -118.3, .coast), (32.7, -117.2, .coast), (25.8, -80.2, .coast),
        (40.6, -73.9, .coast), (42.3, -71.0, .coast), (29.3, -94.8, .coast), (21.3, -157.9, .coast),
        (-33.9, 151.3, .coast), (-27.5, 153.0, .coast), (38.7, -9.2, .coast), (41.4, 2.2, .coast),
        (43.3, 7.3, .coast), (22.3, 114.2, .coast), (1.3, 103.8, .coast), (-22.9, -43.2, .coast),
        (-34.6, -58.4, .coast), (-33.9, 18.4, .coast), (53.4, -3.0, .coast), (59.9, 10.7, .coast),
        (36.9, -76.3, .coast), (43.7, -70.3, .coast), (47.6, -122.4, .coast), (49.3, -123.1, .coast),
        // city
        (41.9, -87.6, .city), (51.5, -0.1, .city), (48.9, 2.3, .city), (52.5, 13.4, .city), (35.7, 139.7, .city),
        (28.6, 77.2, .city), (19.1, 72.9, .city), (13.0, 77.6, .city), (31.2, 121.5, .city), (39.9, 116.4, .city),
        (37.6, 127.0, .city), (-23.5, -46.6, .city), (19.4, -99.1, .city), (30.0, 31.2, .city), (6.5, 3.4, .city),
        (41.0, 29.0, .city), (55.8, 37.6, .city), (25.2, 55.3, .city), (43.7, -79.4, .city), (38.9, -77.0, .city),
        (34.1, -118.2, .city), (37.4, -122.1, .city),
        // mountains
        (46.9, 8.0, .mountains), (39.7, -105.5, .mountains), (44.0, -110.0, .mountains), (36.5, -118.5, .mountains),
        (28.0, 86.9, .mountains), (-13.5, -72.0, .mountains), (-33.0, -70.0, .mountains), (46.5, 11.5, .mountains),
        (61.0, -149.0, .mountains), (47.0, -121.7, .mountains), (35.6, -83.4, .mountains), (40.5, -111.8, .mountains),
        (-43.6, 170.1, .mountains), (35.4, 138.7, .mountains), (30.0, 100.0, .mountains),
        // desert
        (33.5, -112.0, .desert), (36.2, -115.1, .desert), (35.0, -106.6, .desert), (25.0, 45.0, .desert),
        (30.0, 10.0, .desert), (-24.0, 133.0, .desert), (40.0, 95.0, .desert), (23.5, -110.0, .desert),
        (31.5, 74.0, .desert), (-23.0, 15.0, .desert),
        // woods
        (44.0, -123.0, .woods), (46.0, -86.0, .woods), (44.5, -70.0, .woods), (47.0, -90.0, .woods),
        (60.0, 25.0, .woods), (50.0, 10.0, .woods), (-2.0, -60.0, .woods), (64.0, 100.0, .woods),
        (35.0, -80.0, .woods), (42.5, -73.5, .woods), (57.0, -4.0, .woods), (-37.8, 145.5, .woods),
        // plains
        (41.0, -95.0, .plains), (39.0, -98.0, .plains), (35.0, -100.0, .plains), (52.0, 5.5, .plains),
        (50.0, 30.0, .plains), (-34.0, -60.0, .plains), (-30.0, 25.0, .plains), (22.0, 78.0, .plains),
        (48.0, 68.0, .plains), (30.0, 115.0, .plains), (51.0, -105.0, .plains), (-12.0, 28.0, .plains),
    ]

    /// The kind of place nearest the coordinate. The coordinate goes in and nothing of it comes out.
    public static func kind(latitude: Double, longitude: Double) -> PlaceKind {
        // Rounded to a degree before use: nothing finer is ever looked at.
        let lat = latitude.rounded(), lon = longitude.rounded()
        func distance(_ anchor: Anchor) -> Double {
            // The haversine form, in radians, is plenty for "nearest".
            let radians = Double.pi / 180
            let dLat = (anchor.latitude - lat) * radians, dLon = (anchor.longitude - lon) * radians
            let a = sin(dLat / 2) * sin(dLat / 2)
                + cos(lat * radians) * cos(anchor.latitude * radians) * sin(dLon / 2) * sin(dLon / 2)
            return 2 * asin(min(1, sqrt(a)))
        }
        return anchors.min { distance($0) < distance($1) }?.kind ?? .plains
    }

    /// Whether it is time to read the place again: at most once a day (his day, the 4 am edge).
    public static func isDue(lastRead: Date?, now: Date, calendar: Calendar = .current) -> Bool {
        guard let lastRead else { return true }
        return !TesseraDay(calendar: calendar).isSameDay(lastRead, now)
    }
}

/// How the mosaic's content is chosen: Tess picks (the default), one scene pinned, or the mood stripes.
public enum MosaicBackdrop: Equatable, Sendable {
    case tessPicks
    case pinned(MosaicScenery)
    case stripes

    /// The plain setting text: nil is Tess picks.
    public var encoded: String? {
        switch self {
        case .tessPicks: nil
        case .stripes: "stripes"
        case let .pinned(scene): scene.rawValue
        }
    }

    public init(encoded: String?) {
        switch encoded {
        case "stripes": self = .stripes
        case let text?: self = MosaicScenery(rawValue: text).map { .pinned($0) } ?? .tessPicks
        default: self = .tessPicks
        }
    }
}

public enum MosaicScenePicker {
    /// The part of the day for `facts`: dawn from half an hour before sunrise to an hour and a half after, golden hour
    /// from an hour before sunset to twenty minutes after, night between, day otherwise.
    public static func phase(_ facts: MosaicFacts) -> DayPhase {
        let now = facts.now
        let sinceRise = now.timeIntervalSince(facts.sunrise), untilSet = facts.sunset.timeIntervalSince(now)
        if sinceRise >= -30 * 60, sinceRise < 90 * 60 {
            return .dawn
        }
        if untilSet <= 60 * 60, untilSet > -20 * 60 {
            return .golden
        }
        if sinceRise < -30 * 60 || untilSet <= -20 * 60 {
            return .night
        }
        return .day
    }

    /// The scene for now, or nil for the mood stripes. Only the hour, the weather, the kind of place and the month go
    /// in: no coordinate and no city. Without a place or a weather it follows the hour, rotating by day.
    public static func pick(_ backdrop: MosaicBackdrop, facts: MosaicFacts, place: PlaceKind? = nil,
                            weather: SceneWeather? = nil, calendar: Calendar = .current) -> MosaicScenery?
    {
        switch backdrop {
        case .stripes: return nil
        case let .pinned(scene): return scene
        case .tessPicks: break
        }
        let phase = phase(facts)
        // Weather first, then the hour at night.
        if weather == .snow {
            return .snow
        }
        if weather == .rain {
            return .rainOnWindow
        }
        if phase == .night {
            return .nightSky
        }
        // A day count that runs on across New Year, so the daily rotation never repeats a day at the turn of the year.
        let dayOfYear = calendar.dateComponents(
            [.day], from: Date(timeIntervalSinceReferenceDate: 0),
            to: TesseraDay(calendar: calendar).day(of: facts.now)
        ).day ?? 1
        let month = calendar.component(.month, from: facts.now)
        let autumn = (9 ... 11).contains(month)
        guard let place else {
            // The hour only: dusk city at golden hour, fields at dawn, beach or mountains by day, rotating daily.
            switch phase {
            case .dawn: return .fieldsAtSunrise
            case .golden: return .cityAtDusk
            default: return dayOfYear.isMultiple(of: 2) ? .beach : .mountainsAndLake
            }
        }
        switch (place, phase) {
        case (.coast, .golden): return .harbor
        case (.coast, _): return dayOfYear.isMultiple(of: 2) ? .beach : .harbor
        case (.city, .golden): return .cityAtDusk
        case (.city, .dawn): return .fieldsAtSunrise
        case (.city, _): return dayOfYear.isMultiple(of: 2) ? .beach : .mountainsAndLake
        case (.mountains, _): return .mountainsAndLake
        case (.desert, _): return .desert
        case (.woods, _): return autumn ? .autumnTrees : .woods
        case (.plains, .dawn): return .fieldsAtSunrise
        case (.plains, .golden): return .fieldsAtSunrise
        case (.plains, _): return dayOfYear.isMultiple(of: 2) ? .fieldsAtSunrise : .mountainsAndLake
        }
    }
}
