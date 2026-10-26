import Foundation
@testable import Tessera
import Testing
import UIKit

/// The Lookout's sky plates (283, 254-256): the plate by condition and hour band, the text colour from the plate,
/// the grade that keeps text at 7:1, the files in the bundle, and the glass's stats.
@MainActor
struct LookoutPlateTests {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }()

    private static func at(_ hour: Int, minute: Int = 0) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 25, hour: hour, minute: minute)))
    }

    @Test func bandsFollowTheHour() throws {
        #expect(try LookoutPlate.band(at: Self.at(13), calendar: Self.calendar) == .day)
        #expect(try LookoutPlate.band(at: Self.at(18, minute: 10), calendar: Self.calendar) == .dusk)
        #expect(try LookoutPlate.band(at: Self.at(6, minute: 30), calendar: Self.calendar) == .dusk)
        #expect(try LookoutPlate.band(at: Self.at(22), calendar: Self.calendar) == .night)
        #expect(try LookoutPlate.band(at: Self.at(3), calendar: Self.calendar) == .night)
    }

    @Test func plateFollowsConditionAndBand() {
        #expect(LookoutPlate.set(for: .clear, band: .day) == "clear-day")
        #expect(LookoutPlate.set(for: .mainlyClear, band: .night) == "clear-night")
        #expect(LookoutPlate.set(for: .partlyCloudy, band: .dusk) == "broken-dusk")
        #expect(LookoutPlate.set(for: .overcast, band: .day) == "overcast-day")
        #expect(LookoutPlate.set(for: .rain, band: .dusk) == "overcast-dusk")
        #expect(LookoutPlate.set(for: .thunderstorm, band: .night) == "cloudy-night")
        #expect(LookoutPlate.set(for: .fog, band: .dusk) == "fog-day")
        #expect(LookoutPlate.set(for: .snow, band: .day) == "broken-day")
        // Every condition and band has a set with files.
        for kind in WeatherKind.allCases {
            for band in LookoutPlate.Band.allCases {
                #expect(LookoutPlate.sets[LookoutPlate.set(for: kind, band: band)]?.isEmpty == false)
            }
        }
    }

    @Test func darkeningFollowsTheBoard() {
        #expect(LookoutPlate.darken(for: .clear, set: "clear-day", band: .day) == 0)
        #expect(LookoutPlate.darken(for: .clear, set: "clear-night", band: .night) == 0)
        #expect(LookoutPlate.darken(for: .rain, set: "cloudy-night", band: .night) == 0.8)
        #expect(LookoutPlate.darken(for: .thunderstorm, set: "overcast-day", band: .day) == 0.5)
    }

    @Test func textColourComesFromThePlateAndReads() throws {
        // A bright day sky reads in dark ink; a night sky in light ink.
        let day = try LookoutPlate.pick(kind: .clear, at: Self.at(13), calendar: Self.calendar)
        #expect(!day.lightInk)
        let night = try LookoutPlate.pick(kind: .clear, at: Self.at(22), calendar: Self.calendar)
        #expect(night.lightInk)
        // Every condition, band and look: the ink against the graded plate's average reaches 7:1.
        for kind in WeatherKind.allCases {
            for hour in [3, 6, 13, 18, 22] {
                for dark in [false, true] {
                    let plate = try LookoutPlate.pick(
                        kind: kind,
                        at: Self.at(hour),
                        dark: dark,
                        calendar: Self.calendar
                    )
                    let ratio = LookoutPlate.contrast(plate.ink, plate.graded)
                    #expect(ratio >= LookoutPlate.target, "\(kind) at \(hour) dark \(dark): \(ratio)")
                    #expect(plate.grade.alpha <= 0.9)
                }
            }
        }
    }

    @Test func gradeIsLightWhenUnneeded() throws {
        // The fog plate is already bright: dark ink reads with little or no grade.
        let fog = try LookoutPlate.pick(kind: .fog, at: Self.at(13), calendar: Self.calendar)
        #expect(!fog.lightInk)
        #expect(fog.grade.alpha <= 0.1)
    }

    @Test func variantHoldsForTheDay() throws {
        let morning = try LookoutPlate.pick(kind: .partlyCloudy, at: Self.at(10), calendar: Self.calendar)
        let afternoon = try LookoutPlate.pick(kind: .partlyCloudy, at: Self.at(15), calendar: Self.calendar)
        #expect(morning.file == afternoon.file)
    }

    @Test func everyPlateIsInTheBundleWithItsMeasure() {
        let files = LookoutPlate.sets.values.flatMap(\.self)
        #expect(files.count == 11)
        for file in files {
            #expect(Bundle.main.path(forResource: file, ofType: "jpg") != nil, "\(file).jpg missing")
            #expect(LookoutPlate.image(file) != nil, "\(file) does not load")
            #expect(LookoutPlate.average[file] != nil, "\(file) has no measure")
        }
    }

    @Test func glassCarriesThreeStatsAndFeels() throws {
        let now = try Self.at(13)
        let wet = WeatherHour(date: now.addingTimeInterval(4 * 3600), temperature: 60, kind: .rain)
        let snapshot = WeatherSnapshot(now: now, temperature: 64, feelsLike: 62, high: 66, low: 54, fahrenheit: true,
                                       kind: .partlyCloudy, hours: [wet], week: [], air: "good", uvIndex: 3, wind: 9,
                                       isSample: true, fetchedAt: now)
        let stats = LookoutSkypiece.stats(snapshot, calendar: Self.calendar)
        #expect(stats.count == 3)
        #expect(stats[0].value == "9")
        #expect(stats[1].label == "rain from")
        #expect(stats[2].label == "uv index")
        #expect(LookoutSkypiece.feels(snapshot) == "feels like 62°, high 66°")
        var dry = snapshot
        dry.hours = []
        #expect(LookoutSkypiece.stats(dry, calendar: Self.calendar)[1].label == "low")
    }

    @Test func shadowStopsAboveTheCaption() {
        // The keystone ends at 378 and the caption starts at 388: the glass's shadow may reach only 6 pt below it.
        #expect(LookoutSkypiece.shadowFoot < 10)
    }
}
