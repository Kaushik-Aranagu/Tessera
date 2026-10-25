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

    @Test func theConditionWordFitsTheKeystone() {
        // Figtree Bold 64 in the 354 pt slot, the shortest form stepping down to 0.75x at most.
        let font = UIFont(name: "Figtree-Bold", size: 64) ?? .systemFont(ofSize: 64, weight: .bold)
        for kind in WeatherKind.allCases {
            let form = WeatherWords.condition(kind, night: false).last ?? ""
            let width = (form as NSString).size(withAttributes: [.font: font]).width
            #expect(width * 0.75 <= 354, "\(form) is \(width) pt")
        }
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
        #expect(WeatherWords.hourLines(snap, calendar: Self.calendar).first == "2 pm 60° partly cloudy")
        #expect(WeatherWords.weekLines(snap, calendar: Self.calendar).count <= 3)
        #expect(WeatherWords.weekLines(snap, calendar: Self.calendar).first?.hasSuffix("snow") == true)
        #expect(WeatherWords.airLines(snap) == ["Air is good", "UV 3", "Wind 9 mph"])
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
}
