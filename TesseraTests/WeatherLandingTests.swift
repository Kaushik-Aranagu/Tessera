import Foundation
@testable import Tessera
import Testing
import UIKit

/// The Weather landing (243 on the landing contract): the condition words, the state line forms and their fit, the
/// fetch rules (0.1 degree, 30 minutes), the Rain alert switch, and that no line ever names a place.
@MainActor
struct WeatherLandingTests {
    private static let calendar = Calendar(identifier: .gregorian)

    private static func snapshot(kind: WeatherKind = .partlyCloudy, wetAt: Int? = 3, sample: Bool = false)
        -> WeatherSnapshot
    {
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 25, hour: 13))!
        let hours = (1 ... 12).map { step in
            WeatherHour(date: calendar.date(byAdding: .hour, value: step, to: now)!, temperature: 60 - step / 2,
                        kind: step == wetAt ? .rain : kind)
        }
        let week = (0 ..< 7).map { offset in
            WeatherDay(date: calendar.date(byAdding: .day, value: offset, to: now)!, high: 64, low: 52,
                       kind: offset == 2 ? .snow : kind)
        }
        return WeatherSnapshot(now: now, temperature: 62, feelsLike: 60, high: 66, low: 51, fahrenheit: true,
                               kind: kind, hours: hours, week: week, air: "good", uvIndex: 3, wind: 9, isSample: sample,
                               fetchedAt: now)
    }

    @Test func everyKindHasAWordAndTheFormsShrink() {
        for kind in WeatherKind.allCases {
            for night in [false, true] {
                let forms = WeatherWords.condition(kind, night: night)
                #expect(!forms.isEmpty)
                #expect(forms == forms.sorted { $0.count > $1.count })
                #expect(forms.allSatisfy { $0.first?.isUppercase == true && !$0.contains("...") })
            }
        }
        #expect(WeatherWords.condition(.clear, night: false) == ["Sunny"])
        #expect(WeatherWords.condition(.clear, night: true) == ["Clear"])
        #expect(WeatherWords.condition(.partlyCloudy, night: false) == ["Partly cloudy", "Cloudy"])
        #expect(WeatherWords.isWet(.drizzle) && !WeatherWords.isWet(.snow))
    }

    @Test func theConditionWordFitsTheSkypiece() {
        // Figtree SemiBold 22 at the glass top right, beside the temperature: the chosen form always fits, never
        // smaller type.
        let font = UIFont(name: "Figtree-SemiBold", size: LookoutSkypiece.wordSize) ?? .boldSystemFont(ofSize: 22)
        for kind in WeatherKind.allCases {
            for night in [false, true] {
                let forms = WeatherWords.condition(kind, night: night)
                let form = LookoutSkypiece.fitted(forms)
                #expect(forms.contains(form))
                let width = (form as NSString).size(withAttributes: [.font: font]).width
                #expect(width <= LookoutSkypiece.wordWidth, "\(form) is \(width) pt")
            }
        }
        #expect(LookoutSkypiece.fitted(["Mostly clear", "Clear"]) == "Mostly clear")
    }

    @Test func stateLineIsLongestFirstAndNamesTheChange() {
        let forms = WeatherWords.stateLine(Self.snapshot(), calendar: Self.calendar)
        #expect(forms == forms.sorted { $0.count > $1.count })
        #expect(forms.first == "62°, feels like 60°, high 66°, low 51°, rain from 4 pm.")
        #expect(forms.last == "62° now.")
        #expect(forms.allSatisfy { !$0.contains(" of ") && !$0.contains("...") })
        #expect(WeatherWords.change(Self.snapshot(wetAt: nil), calendar: Self.calendar) == nil)
    }

    @Test func theShortFormsFitAtDefaultAndAX5() throws {
        let forms = WeatherWords.stateLine(Self.snapshot(), calendar: Self.calendar)
        func width(_ form: String, _ size: CGFloat) -> CGFloat {
            let font = UIFont(name: "Figtree-Regular", size: size) ?? .systemFont(ofSize: size)
            return (form as NSString).size(withAttributes: [.font: font]).width
        }
        // At the default size a form that still names the change fits; at AX5 (about 3.1x) the last form fits.
        let fitting = forms.first { width($0, 16) <= 354 }
        #expect(fitting?.contains("rain from 4 pm") == true, "\(String(describing: fitting))")
        let last = try #require(forms.last)
        #expect(width(last, 16 * 3.1) <= 354, "\(last) at AX5 is \(width(last, 16 * 3.1)) pt")
    }

    @Test func fetchRulesRoundToATenthAndKeepHalfAnHour() {
        #expect(WeatherFetchRules.rounded(37.774_93) == 37.8)
        #expect(WeatherFetchRules.rounded(-122.419_42) == -122.4)
        #expect(WeatherFetchRules.rounded(0.04) == 0)
        let now = Date()
        #expect(WeatherFetchRules.isFresh(fetchedAt: now.addingTimeInterval(-29 * 60), now: now))
        #expect(!WeatherFetchRules.isFresh(fetchedAt: now.addingTimeInterval(-30 * 60), now: now))
        #expect(!WeatherFetchRules.isFresh(fetchedAt: nil, now: now))
        #expect(WeatherFetchRules.host == "api.open-meteo.com")
    }

    @Test func noLineNamesAPlace() {
        let sample = WeatherSample.make(now: Date(), fahrenheit: true)
        let lines = WeatherWords.allLines(Self.snapshot()) + WeatherWords.allLines(sample)
        let places = ["San Francisco", "Seattle", "London", "New York", "Cupertino", "city", " in "]
        for line in lines {
            for place in places {
                #expect(!line.contains(place), "\(line)")
            }
        }
        #expect(WeatherWords.brief(sample).lead == "Sample sky")
    }

    @Test func doorsLinesStayWithinThree() {
        let snap = Self.snapshot()
        #expect(WeatherWords.hourLines(snap, calendar: Self.calendar).count == 3)
        #expect(WeatherWords.hourLines(snap, calendar: Self.calendar).first == "2 pm 60° cloudy")
        #expect(WeatherWords.weekLines(snap, calendar: Self.calendar).count <= 3)
        #expect(WeatherWords.weekLines(snap, calendar: Self.calendar).first?.hasSuffix("snow") == true)
        #expect(WeatherWords.airLines(snap) == ["Air is good", "UV 3", "Wind 9 mph"])
    }

    @Test func doorLinesFitTheFactsColumnAndTheBriefFitsAtAX5() throws {
        // The dial's facts are 150 pt wide, first line Figtree Bold 16; never an ellipsis.
        let bold = UIFont(name: "Figtree-Bold", size: 16) ?? .systemFont(ofSize: 16, weight: .bold)
        for snap in [Self.snapshot(), WeatherSample.make(now: Date(), fahrenheit: true)] {
            let lines = WeatherWords.hourLines(snap) + WeatherWords.weekLines(snap) + WeatherWords.airLines(snap)
            for line in lines {
                let width = (line as NSString).size(withAttributes: [.font: bold]).width
                #expect(width <= 150, "\(line) is \(width) pt")
            }
        }
        let last = try #require(WeatherWords.briefForms(Self.snapshot(sample: true)).last)
        let big = UIFont(name: "Figtree-Bold", size: 15 * 3.1) ?? .systemFont(ofSize: 46)
        #expect(((last.lead + last.rest) as NSString).size(withAttributes: [.font: big]).width <= 354)
    }

    @Test func rainAlertIsAPhoneOnlySwitch() throws {
        let defaults = try #require(UserDefaults(suiteName: "weather-landing-tests"))
        defaults.removePersistentDomain(forName: "weather-landing-tests")
        #expect(!WeatherRainAlert.isOn(defaults))
        WeatherRainAlert.set(true, defaults)
        #expect(WeatherRainAlert.isOn(defaults))
        #expect(WeatherRainAlert.receipt(on: true).contains("30 minutes before rain"))
        WeatherRainAlert.set(false, defaults)
        #expect(!WeatherRainAlert.isOn(defaults))
    }

    @Test func footIsVerbOverObject() {
        #expect(WeatherWords.alertObject(on: false) == "Rain")
        #expect(WeatherWords.alertObject(on: true) == "Rain, on")
        #expect(!WeatherWords.alertObject(on: false).contains("alert"))
    }

    @Test func walkLinePicksADryDaylightHourAndNamesNoPlace() {
        let snapshot = Self.snapshot(sample: true)
        let line = WeatherWords.walkLine(snapshot, calendar: Self.calendar)
        #expect(line ==
            "Best walk around \(WeatherWords.hour(snapshot.hours[0].date, calendar: Self.calendar)), 60° and dry.")
        #expect(!line.contains("..."))
        var wet = snapshot
        wet.hours = wet.hours.map { WeatherHour(date: $0.date, temperature: $0.temperature, kind: .rain) }
        #expect(WeatherWords.walkLine(wet, calendar: Self.calendar) == "No dry daylight hour for a walk soon.")
    }

    @Test func dropHandoverIsShortAndCounted() {
        #expect(LookoutDropHandover.count == 26)
        #expect(LookoutDropHandover.length <= 5)
    }

    // MARK: Lookout (283)

    @Test func skyKeepsInkReadableInEveryHourAndCondition() {
        let inkLight: UInt32 = 0x1D1B19
        let inkDark: UInt32 = 0xF1EEE9
        for kind in WeatherKind.allCases {
            for hour in [LookoutSky.Hour.dawn, .day, .dusk, .night] {
                let light = LookoutSky.stops(kind: kind, hour: hour, dark: false)
                let dark = LookoutSky.stops(kind: kind, hour: hour, dark: true)
                for stop in [light.top, light.bottom] {
                    #expect(LookoutSky.contrast(inkLight, stop) >= 7, "\(kind) \(hour) light")
                }
                for stop in [dark.top, dark.bottom] {
                    #expect(LookoutSky.contrast(inkDark, stop) >= 7, "\(kind) \(hour) dark")
                }
            }
        }
    }

    @Test func skyFollowsTheHourWhenClearAndTheWeatherWhenNot() throws {
        let night = LookoutSky.stops(kind: .clear, hour: .night, dark: true)
        let day = LookoutSky.stops(kind: .clear, hour: .day, dark: true)
        #expect(night != day)
        #expect(LookoutSky.stops(kind: .rain, hour: .night, dark: false) == LookoutSky.stops(kind: .rain, hour: .day,
                                                                                             dark: false))
        #expect(try LookoutSky.hour(
            #require(Self.calendar.date(from: DateComponents(year: 2026, month: 10, day: 25, hour: 6))),
            calendar: Self.calendar
        ) == .dawn)
    }

    @Test func switcherHasFourWordsAndEachHasTwoNeedsWithoutAPlace() {
        #expect(WeatherWords.switcher == ["Now", "Tonight", "Tomorrow", "This week"])
        let snapshot = Self.snapshot()
        for index in WeatherWords.switcher.indices {
            let needs = WeatherWords.needs(snapshot, switcher: index, calendar: Self.calendar)
            #expect(needs.count == 2)
            #expect(needs.allSatisfy { !$0.isEmpty && !$0.contains("...") && !$0.contains(" of ") })
        }
        #expect(WeatherWords.needs(snapshot, switcher: 0, calendar: Self.calendar)[1] == "Rain from 4 pm")
    }

    @Test func widgetSaysWhatIsComingTonightAndADayAndNeverStrikes() {
        let cards = WeatherWords.cards(Self.snapshot(), alertOn: true, calendar: Self.calendar)
        #expect(cards.map(\.id) == ["coming", "tonight", "day"])
        #expect(cards[0].big == "Rain" && cards[0].middle == "from 4 pm" && cards[0].wet)
        #expect(cards[1].bigIsNumber && cards[1].unit == "°")
        #expect(cards[2].opens == .week)
        let steady = WeatherWords.cards(Self.snapshot(wetAt: nil), alertOn: false, calendar: Self.calendar)
        #expect(steady[0].big == "Steady")
    }
}
