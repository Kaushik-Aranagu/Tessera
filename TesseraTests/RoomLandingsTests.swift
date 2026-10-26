import Foundation
@testable import Tessera
import TesseraCore
import Testing
import UIKit

/// The Lists, Money and Kitchen landings on the shared kit (landing contract §2, §7, §12): their wall words, state
/// line forms (longest first, the last always fits), and the walls' privacy and no-amount rules.
@MainActor
struct RoomLandingsTests {
    /// The header slot: 402 pt frame less two 24 pt gutters, Figtree 16.
    static let stateWidth: CGFloat = 354

    static func width(_ text: String, size: CGFloat = 16) -> CGFloat {
        let descriptor = UIFontDescriptor(fontAttributes: [.family: "Figtree"])
        let font = UIFont(descriptor: descriptor, size: size)
        return (text as NSString).size(withAttributes: [.font: font]).width
    }

    /// Longest first, and the last form fits the slot at default size (FitLine may step it to 0.8x past that).
    static func checkForms(_ forms: [String], _ comment: Comment, size: CGFloat = 16) {
        #expect(!forms.isEmpty, comment)
        for (lhs, rhs) in zip(forms, forms.dropFirst()) {
            #expect(lhs.count >= rhs.count, comment)
        }
        if let last = forms.last {
            // The written forms or their whole-word cuts (FitLine) always reach one that fits.
            #expect(
                (forms + FitLine.cuts(forms[forms.count - 1])).contains { width($0, size: size) <= stateWidth },
                comment
            )
            #expect(!last.contains("..."), comment)
            #expect(!last.contains("…"), comment)
        }
    }

    static func day(_ day: Int, _ hour: Int = 12) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    // MARK: Money

    func spend(_ category: String, _ at: Int, isPrivate: Bool = false) -> MoneyWall.Spend {
        MoneyWall.Spend(category: category, at: Self.day(at), isPrivate: isPrivate)
    }

    @Test func moneyWallHoldsCategoriesAndNoAmounts() {
        let wall = MoneyWall.build(spends: [spend("lunch", 24), spend("12.40", 23), spend("$8", 22), spend("taxi", 21),
                                            spend("lunch", 20), spend("", 19)],
                                   monthCount: 6, monthName: "October",
                                   trend: "October is running a little under September")
        #expect(wall.words.map(\.text) == ["Lunch", "Taxi"])
        let everything = (wall.words.map(\.text) + wall.stateLine + wall.top).joined(separator: " ")
        #expect(!everything.contains("$") && !everything.contains("12.40") && !everything.contains("€"))
        // Digits only ever appear as a count of spends, never next to a currency.
        #expect(wall.words.allSatisfy { !$0.text.contains { $0.isNumber } })
        #expect(wall.lastCategory == "lunch")
    }

    @Test func moneyWallKeepsPrivateCategoriesOff() {
        let wall = MoneyWall.build(spends: [spend("therapy", 24, isPrivate: true), spend("coffee", 23)],
                                   monthCount: 2, monthName: "October", trend: nil)
        #expect(wall.words.map(\.text) == ["Coffee"])
        #expect(wall.hidden == 1 && wall.lastIsPrivate && wall.lastCategory == nil)
        #expect(!wall.stateLine.joined().lowercased().contains("therapy"))
    }

    @Test func moneyStateLineFormsAndEmptyState() {
        #expect(MoneyWall.stateLine(monthCount: 0, monthName: "October", trend: nil) == ["Nothing yet"])
        let forms = MoneyWall.stateLine(monthCount: 12, monthName: "September",
                                        trend: "September is running a little under August")
        #expect(forms.first == "September is running a little under August, 12 spends so far")
        #expect(forms.last == "12 spends")
        Self.checkForms(forms, "Money state line")
        #expect(!forms.joined().contains("left"))
    }

    // MARK: Purse

    @Test func purseMonthLineForecastAndRange() {
        // In 100 on the 1st, out 10 a day after: still yours falls, the forecast carries the pace to the 30th.
        let daily = [100.0] + Array(repeating: -10.0, count: 9)
        let series = PurseSeries.build(name: "Month", shape: .balance, daily: daily, today: 10, daysInMonth: 30,
                                       priorDaily: Array(repeating: -5.0, count: 30))
        #expect(series.solid.count == 10 && series.solid.first == 100 && series.solid.last == 10)
        #expect(series.forecast.count == 21 && series.forecast.first == 10 && series.forecast.last! > 10)
        #expect(series.prior.count == 30 && series.prior.last == -150)
        #expect(series.range.contains(0) && series.range.contains(100) && series.range.contains(-150))
        #expect(series.floor == nil && !series.isEmpty)
    }

    @Test func purseEmptyMonthHasNoForecast() {
        let series = PurseSeries.build(
            name: "Spend",
            shape: .flow,
            daily: [],
            today: 5,
            daysInMonth: 31,
            priorDaily: []
        )
        #expect(series.isEmpty && series.forecast.isEmpty)
        #expect(series.range.contains(0))
    }

    // MARK: Galley

    func dinner(_ title: String = "Tacos", isPrivate: Bool = false, lines: Int = 8) -> GalleyPass.Dinner {
        GalleyPass.Dinner(recipe: UUID(), title: isPrivate ? "Private recipe" : title, isPrivate: isPrivate,
                          start: "6:05 pm", ingredients: (1 ... lines).map { "Thing \($0)" })
    }

    @Test func galleyPassHangsDinnerToGetAndRunsOut() {
        let pass = GalleyPass.build(dinner: dinner(), toGet: ["Limes", "Feta"],
                                    stock: [.init(name: "Eggs", state: .out, isPrivate: false),
                                            .init(name: "Milk", state: .low, isPrivate: false),
                                            .init(name: "Rice", state: .have, isPrivate: false)],
                                    cookable: ["Dal"], cooking: nil)
        #expect(pass.tickets.map(\.title) == ["Tacos", "To get", "Runs out"])
        #expect(pass.tickets[0].big && pass.tickets[0].share == 2.4 && !pass.tickets[1].big)
        #expect(pass.tickets[0].pages.count == 2 && pass.tickets[0].pages[1] == ["Thing 7", "Thing 8"])
        #expect(pass.tickets[2].lines == ["Eggs", "Milk"])
        #expect(pass.tickets[0].opens != .recipes && pass.tickets[1].opens == .groceries && pass.tickets[2]
            .opens == .pantry)
        #expect(pass.lowLine?.first?.text == "Eggs and Milk run out first")
        #expect(pass.stateLine.first == "Tacos tonight, start at 6:05 pm")
        #expect(pass.tickets.count <= GalleyPass.maxTickets)
    }

    @Test func galleyPassNeverShowsAPrivateRecipeOrItem() {
        let pass = GalleyPass.build(dinner: dinner("Keto shake", isPrivate: true), toGet: ["Private item"],
                                    stock: [.init(name: "Private item", state: .low, isPrivate: true)],
                                    cookable: [], cooking: nil)
        #expect(pass.tickets.map(\.title) == ["Private recipe"])
        #expect(pass.tickets[0].lines.isEmpty && pass.hidden == 2)
        let all = (pass.tickets.flatMap { [$0.title] + $0.lines } + pass.stateLine).joined(separator: " ")
        #expect(!all.contains("Keto") && !all.contains("Thing"))
    }

    @Test func galleyEmptyStateAndForms() {
        let empty = GalleyPass.build(dinner: nil, toGet: [], stock: [], cookable: [], cooking: nil)
        #expect(empty.tickets.map(\.title) == ["Tonight?"] && empty.tickets[0].sub == "nothing planned yet")
        #expect(empty.stateLine == ["Tonight? Nothing planned yet"])
        let ask = GalleyPass.build(dinner: nil, toGet: [], stock: [], cookable: ["Dal", "Pasta"], cooking: nil)
        #expect(ask.tickets[0].lines == ["you could make", "Dal", "Pasta"])
        Self.checkForms(ask.stateLine, "Galley empty", size: 26)
        let planned = GalleyPass.stateLine(dinner: dinner("Tomato and white bean stew"), cooking: nil, cookable: 0)
        Self.checkForms(planned, "Galley planned", size: 26)
    }
}
