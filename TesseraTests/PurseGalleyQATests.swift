import Foundation
@testable import Tessera
import Testing

/// Visual QA round (Oct 25): Purse loses its category tab row for the ticker header, the line's name and a day axis;
/// Galley's dial focus wears the door's own ochre.
@MainActor
struct PurseGalleyQATests {
    private let october = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 25, hour: 12))!

    private func month(rising: Bool) -> PurseSeries {
        PurseSeries.build(name: "Month", shape: .balance, daily: [100] + Array(repeating: rising ? 5 : -10, count: 24),
                          today: 25, daysInMonth: 31, priorDaily: Array(repeating: -3, count: 30))
    }

    @Test func monthTickerIsYouAndTheMonth() {
        let ticker = PurseIndexView.ticker(series: month(rising: true), category: "This month", now: october)
        #expect(ticker == PurseIndexView.Ticker(symbol: "YOU", clock: "OCT"))
        #expect(!ticker.symbol.contains("·") && !ticker.clock.contains("·"))
    }

    @Test func kindTickerIsItsName() {
        let lunch = PurseSeries.build(name: "Lunch", shape: .flow, daily: [12, 0, 9], today: 3, daysInMonth: 31,
                                      priorDaily: [10, 10, 10])
        #expect(PurseIndexView.ticker(series: lunch, category: "Kinds", now: october).symbol == "LUNCH")
        #expect(PurseIndexView.lineName(series: lunch).first?.rest == ", calmer than last month")
    }

    @Test func stillYoursLineHasFormsAndNoFigures() {
        let forms = PurseIndexView.lineName(series: month(rising: false))
        #expect(forms.first == PurseIndexView.LineName(name: "Still yours", rest: ", heading down at this pace"))
        #expect(forms.last == PurseIndexView.LineName(name: "Still yours", rest: ""))
        #expect(forms.allSatisfy { !($0.name + $0.rest).contains { $0.isNumber } })
        #expect(PurseIndexView.lineName(series: month(rising: true)).first?.rest.contains("up") == true)
    }

    @Test func axisMarksTheBoardDays() {
        let ticks = PurseIndexView.axisLabels(days: 31, now: october)
        #expect(ticks.map(\.day) == [1, 8, 15, 22, 29])
        #expect(ticks.first?.text == "1 Oct")
        #expect(PurseIndexView.axisLabels(days: 28, now: october).map(\.day) == [1, 8, 15, 22])
    }

    @Test func noTabRowInThePurseSource() throws {
        // The keystone no longer draws the six category names across its top: the doors dial is the category choice.
        let source = try String(
            contentsOfFile: #filePath.replacingOccurrences(of: "TesseraTests/PurseGalleyQATests.swift",
                                                           with: "Features/Money/PurseChart.swift"),
            encoding: .utf8
        )
        #expect(!source.contains("categoryRow"))
        #expect(source.contains("axisRow"))
    }

    @Test func galleyTonightIsOchre() {
        #expect(KitchenLandingPage.tone(door: "tonight", lowEmpty: true) == .ochre)
        #expect(KitchenLandingPage.tone(door: "recipes", lowEmpty: true) == .ochre)
        #expect(KitchenLandingPage.tone(door: "pantry", lowEmpty: false) == .wine)
        #expect(KitchenLandingPage.tone(door: "pantry", lowEmpty: true) == .ink)
        #expect(KitchenLandingPage.tone(door: "groceries", lowEmpty: true) == .olive)
    }
}
