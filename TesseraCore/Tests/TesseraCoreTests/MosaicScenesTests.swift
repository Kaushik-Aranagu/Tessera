import Foundation
@testable import TesseraCore
import Testing

/// Sheet 214: the scene picker and the place kind. On the phone; a place is a word, never a coordinate or a city.
@MainActor
struct MosaicScenesTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func facts(_ hour: Int, _ minute: Int = 0, month: Int = 7, day: Int = 22) -> MosaicFacts {
        let now = calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
        return MosaicFacts.make(engine: engine, now: now, calendar: calendar, place: (37.8, -122.4))
    }

    // MARK: Place kind

    @Test func aCoarseCoordinateBecomesOneOfSixWords() {
        #expect(PlaceKinds.kind(latitude: 37.7, longitude: -122.6) == .coast)
        #expect(PlaceKinds.kind(latitude: 41.9, longitude: -87.6) == .city)
        #expect(PlaceKinds.kind(latitude: 46.9, longitude: 8.0) == .mountains)
        #expect(PlaceKinds.kind(latitude: 33.5, longitude: -112.0) == .desert)
        #expect(PlaceKinds.kind(latitude: 44.0, longitude: -123.0) == .woods)
        #expect(PlaceKinds.kind(latitude: 39.0, longitude: -98.0) == .plains)
        // Anything finer than a degree makes no difference.
        #expect(PlaceKinds.kind(latitude: 39.04, longitude: -98.2) == PlaceKinds.kind(latitude: 39.0, longitude: -98.0))
        #expect(Set(PlaceKind.allCases.map(\.rawValue)) == ["coast", "city", "mountains", "desert", "woods", "plains"])
    }

    @Test func theTableHoldsNoNamesAndNoLookupCodeIsUsed() throws {
        let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appending(path: "Sources/TesseraCore/Home/MosaicScenes.swift")
        let text = try String(contentsOf: file, encoding: .utf8)
        for banned in ["CLGeocoder", "URLSession", "CoreLocation", "San Francisco", "London", "Paris", "Tokyo",
                       "New York", "Chicago", "Seattle", "Sydney", "Berlin", "Delhi", "Mumbai"]
        {
            #expect(!text.contains(banned), "\(banned) in the place table")
        }
        // Each table row is a latitude, a longitude and a kind, nothing else; every kind has several rows.
        let rowPattern = /\(-?\d+\.\d, -?\d+\.\d, \.(coast|city|mountains|desert|woods|plains)\)/
        var perKind: [String: Int] = [:]
        for line in text.split(separator: "\n") {
            for part in line.split(separator: ")") {
                if let match = (String(part) + ")")
                    .firstMatch(of: rowPattern)
                {
                    perKind[String(match.1), default: 0] += 1
                }
            }
        }
        #expect(Set(perKind.keys) == ["coast", "city", "mountains", "desert", "woods", "plains"])
        #expect(perKind.values.allSatisfy { $0 >= 10 } && perKind.values.reduce(0, +) >= 90, "\(perKind)")
    }

    @Test func thePlaceIsReadAtMostOncePerDay() throws {
        let morning = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 22, hour: 9)))
        let evening = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 22, hour: 20)))
        let nextDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 9)))
        #expect(PlaceKinds.isDue(lastRead: nil, now: morning, calendar: calendar))
        #expect(!PlaceKinds.isDue(lastRead: morning, now: evening, calendar: calendar))
        #expect(PlaceKinds.isDue(lastRead: morning, now: nextDay, calendar: calendar))
    }

    // MARK: The pick

    @Test func withNoPlaceOrWeatherItFollowsTheHour() {
        // Local sunrise about 5:50 am and sunset about 8:30 pm in July at 37.8 N.
        #expect(MosaicScenePicker.pick(.tessPicks, facts: facts(6, 15), calendar: calendar) == .fieldsAtSunrise)
        #expect(MosaicScenePicker.pick(.tessPicks, facts: facts(20, 0), calendar: calendar) == .cityAtDusk)
        #expect(MosaicScenePicker.pick(.tessPicks, facts: facts(23, 0), calendar: calendar) == .nightSky)
        #expect(MosaicScenePicker.pick(.tessPicks, facts: facts(2, 0), calendar: calendar) == .nightSky)
        let byDay = Set((1 ... 6).map {
            MosaicScenePicker.pick(.tessPicks, facts: facts(13, day: $0), calendar: calendar)
        })
        #expect(byDay == [.beach, .mountainsAndLake])
    }

    @Test func weatherBeatsTheHourExceptAtNightWhereTheNightSkyHoldsOnlyWhenClear() {
        #expect(MosaicScenePicker.pick(.tessPicks, facts: facts(13), weather: .snow, calendar: calendar) == .snow)
        #expect(MosaicScenePicker.pick(.tessPicks, facts: facts(13), weather: .rain, calendar: calendar)
            == .rainOnWindow)
        #expect(MosaicScenePicker.pick(.tessPicks, facts: facts(13), weather: .clear, calendar: calendar) != .snow)
        #expect(MosaicScenePicker.pick(.tessPicks, facts: facts(23), weather: .clear, calendar: calendar) == .nightSky)
    }

    @Test func thePlaceChoosesTheScene() {
        func pick(_ place: PlaceKind, _ hour: Int, month: Int = 7) -> MosaicScenery? {
            MosaicScenePicker.pick(.tessPicks, facts: facts(hour, month: month), place: place, calendar: calendar)
        }
        #expect(pick(.coast, 20) == .harbor)
        #expect([.beach, .harbor].contains(pick(.coast, 13)))
        #expect(pick(.city, 20) == .cityAtDusk && pick(.city, 6, month: 7) == .fieldsAtSunrise)
        #expect(pick(.mountains, 13) == .mountainsAndLake && pick(.desert, 13) == .desert)
        #expect(pick(.woods, 13, month: 7) == .woods)
        #expect(pick(.woods, 13, month: 10) == .autumnTrees && pick(.woods, 13, month: 9) == .autumnTrees)
        #expect(pick(.woods, 13, month: 11) == .autumnTrees && pick(.woods, 13, month: 12) == .woods)
        #expect(pick(.plains, 6) == .fieldsAtSunrise)
        // Night is the night sky in any place.
        for place in PlaceKind.allCases {
            #expect(pick(place, 23) == .nightSky)
        }
    }

    @Test func aPinnedSceneStaysAndStripesAreOneChoice() {
        for scene in MosaicScenery.allCases {
            #expect(MosaicScenePicker.pick(.pinned(scene), facts: facts(13), calendar: calendar) == scene)
        }
        #expect(MosaicScenePicker.pick(.pinned(.beach), facts: facts(23), weather: .snow, calendar: calendar) == .beach)
        #expect(MosaicScenePicker.pick(.stripes, facts: facts(13), place: .coast, calendar: calendar) == nil)
        #expect(MosaicScenery.allCases.count == 11)
    }

    @Test func theChoiceIsAPlainSettingAndTessPicksByDefault() throws {
        #expect(TesseraSettings().backdrop == .tessPicks)
        for backdrop in [MosaicBackdrop.tessPicks, .stripes, .pinned(.snow), .pinned(.cityAtDusk)] {
            #expect(MosaicBackdrop(encoded: backdrop.encoded) == backdrop)
        }
        #expect(MosaicBackdrop(encoded: "not a scene") == .tessPicks && MosaicBackdrop.tessPicks.encoded == nil)
        let settings = SettingsStore(engine: engine)
        try settings.update { $0.mosaicBackdrop = MosaicBackdrop.pinned(.harbor).encoded }
        #expect(settings.read().backdrop == .pinned(.harbor))
        try settings.update { $0.mosaicBackdrop = nil }
        #expect(settings.read().backdrop == .tessPicks)
    }

    @Test func theKindOfPlaceNeverReachesAnyWriter() throws {
        let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
        var checked = 0
        // Also the engine itself: backups, the op log and every Claude prompt live in TesseraCore/Sources, and only the
        // picker's own file may name the place kind.
        for (path, allowed) in [("../Widgets", ""), ("../Watch", ""), ("../Shared", ""), ("Sources/TesseraIntents", ""),
                                ("Sources/TesseraTess", ""), ("../App", ""), ("../DesignSystem", ""),
                                ("Sources/TesseraCore", "/Home/MosaicScenes.swift"), ("../Features", "/Features/Home/")]
        {
            var inThisFolder = 0
            guard let walker = FileManager.default.enumerator(at: package.appending(path: path),
                                                              includingPropertiesForKeys: nil) else { continue }
            for case let url as URL in walker where url.pathExtension == "swift"
                && (allowed.isEmpty || !url.path.contains(allowed))
            {
                guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
                inThisFolder += 1
                checked += 1
                for word in ["PlaceKind", "PlaceKinds", "MosaicScenePicker"] {
                    let pattern = try Regex("\\b\(word)\\b")
                    #expect(text.firstMatch(of: pattern) == nil, "\(word) in \(url.path)")
                }
            }
            #expect(inThisFolder > 0, "no Swift files found in \(path)")
        }
        #expect(checked > 100)
    }

    @Test func theDailyRotationDoesNotRepeatAcrossNewYear() {
        func scene(_ year: Int, _ month: Int, _ day: Int) -> MosaicScenery? {
            let now = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 13))!
            let facts = MosaicFacts.make(engine: engine, now: now, calendar: calendar, place: (37.8, -122.4))
            return MosaicScenePicker.pick(.tessPicks, facts: facts, calendar: calendar)
        }
        // Dec 31 and Jan 1 are neighbours: they must differ, as every other pair of neighbours does.
        #expect(scene(2026, 12, 31) != scene(2027, 1, 1))
        #expect(scene(2026, 6, 14) != scene(2026, 6, 15) && scene(2026, 6, 15) != scene(2026, 6, 16))
    }

    @Test func aStrayBackdropTextIsNormalisedOnWriteAndTheResetClearsIt() throws {
        let settings = SettingsStore(engine: engine)
        try settings.update { $0.mosaicBackdrop = "nonsense" }
        #expect(settings.read().mosaicBackdrop == nil)
        try settings.update { $0.mosaicBackdrop = MosaicBackdrop.pinned(.snow).encoded }
        #expect(settings.read().backdrop == .pinned(.snow))
        try settings.resetMosaic()
        #expect(settings.read().mosaicBackdrop == nil && settings.read().backdrop == .tessPicks)
    }
}
