import Foundation
@testable import TesseraCore
import Testing

/// The Lookout's facts: humidity and pressure from the same Open-Meteo call, the moon from the date alone, and the
/// words the level pages show.
struct LookoutFactsTests {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    @Test func theForecastCarriesHumidityAndPressureNowAndByTheHour() throws {
        let report = try OpenMeteoSource.parse(forecast: Data(WeatherTests.forecastJSON.utf8),
                                               fetchedAt: Date(timeIntervalSince1970: 1_792_000_000))
        #expect(report.now.humidity == 82 && report.now.pressureHpa == 1004.3)
        #expect(report.hourly[0].humidity == 82 && report.hourly[1].pressureHpa == 1002.8)
        #expect(report.hourly[2].humidity == nil && report.hourly[2].pressureHpa == nil, "a missing hour stays empty")
        #expect(abs(WeatherUnits.inchesOfMercury(1013.25) - 29.92) < 0.01)
    }

    @Test func theMoonPhaseIsWorkedOutOnThePhone() {
        // New moon Jan 11 2024 11:57 UTC, full Jan 25 17:54 UTC, first quarter Jan 18 03:53 UTC.
        let newMoon = MoonPhase(on: Date(timeIntervalSince1970: 1_704_974_220))
        #expect(newMoon.name == "New" && newMoon.illumination < 0.02)
        let full = MoonPhase(on: Date(timeIntervalSince1970: 1_706_205_240))
        #expect(full.name == "Full" && full.illumination > 0.98 && full.value == "Full")
        let quarter = MoonPhase(on: Date(timeIntervalSince1970: 1_705_549_980))
        #expect(quarter.name == "First quarter" && quarter.isWaxing && quarter.line == "Waxing, half")
        #expect(quarter.value == "Half" && abs(quarter.illumination - 0.5) < 0.1)
        let waning = MoonPhase(on: Date(timeIntervalSince1970: 1_706_205_240 + 4 * 86400))
        #expect(!waning.isWaxing && waning.line == "Waning, gibbous" && waning.value == "Gibbous")
    }

    @Test func theSampleReadsEveryLookoutFact() {
        let now = Date(timeIntervalSince1970: 1_792_670_400)
        let report = SampleWeather.forecast(now: now, calendar: calendar)
        let facts = report.lookoutFacts(at: now, calendar: calendar)
        #expect(facts.humidity == 58 && facts.pressureHpa == 1015 && facts.windFrom == "west")
        #expect(facts.pressureTrend == .falling && facts.pressureIsSlow && facts.pressureWords == "Falling slowly")
        #expect(facts.isGusting && facts.windWords == "From the west, gusting")
        #expect(facts.aqi == 42 && facts.aqiWord == "Good")
        #expect(facts.sunrise != nil && facts.sunset != nil && facts.daylightMinutes == 720)
        #expect(facts.daylightChangeMinutes == 0 && facts.daylightWords == "Same as today")
        #expect(facts.moon == MoonPhase(on: now))
        #expect(facts.rainChance >= 10)
    }

    @Test func humidityRisingTowardRainAndTheWordsForDaylight() {
        let now = Date(timeIntervalSince1970: 1_792_670_400)
        var report = SampleWeather.forecast(now: now, calendar: calendar)
        // Humidity climbs 10 points over six hours with rain ahead.
        report.hourly = report.hourly.enumerated().map { index, hour in
            var hour = hour
            hour.humidity = 50 + index * 2
            hour.condition = index == 4 ? .rain : .clear
            return hour
        }
        report.now.humidity = 50
        let facts = report.lookoutFacts(at: report.hourly[0].time, calendar: calendar)
        #expect(facts.humidityTrend == .rising && facts.humidityWords == "Rising toward rain")
        // Tomorrow's daylight two minutes shorter.
        report.daily[1].sunset = report.daily[1].sunset?.addingTimeInterval(-120)
        let shorter = report.lookoutFacts(at: now, calendar: calendar)
        #expect(shorter.daylightChangeMinutes == -2 && shorter.daylightWords == "Two minutes less")
        report.now.windKph = 1
        #expect(report.lookoutFacts(at: now, calendar: calendar).windWords == "Calm")
    }
}
