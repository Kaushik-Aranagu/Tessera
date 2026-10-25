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
    static func checkForms(_ forms: [String], _ comment: Comment) {
        #expect(!forms.isEmpty, comment)
        for (lhs, rhs) in zip(forms, forms.dropFirst()) {
            #expect(lhs.count >= rhs.count, comment)
        }
        if let last = forms.last {
            #expect(width(last) <= stateWidth, comment)
            #expect(!last.contains("..."), comment)
            #expect(!last.contains("…"), comment)
        }
    }

    static func day(_ day: Int, _ hour: Int = 12) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    // MARK: Lists

    func line(_ name: String, isPrivate: Bool = false) -> ListsLandingFacts.Line {
        ListsLandingFacts.Line(id: UUID(), name: isPrivate ? "Private list" : name, isGroceries: false,
                               isPrivate: isPrivate, isRunning: false, isReusable: false, isPickOne: false,
                               left: 3, total: 5)
    }

    func due(_ list: ListsLandingFacts.Line, _ text: String, day: String, at: Int, isPrivate: Bool = false)
        -> ListsLanding.DueItem
    {
        ListsLanding.DueItem(list: list.id, listName: list.name, item: UUID(), text: isPrivate ? "Private item" : text,
                             due: Self.day(at), isPrivate: isPrivate || list.isPrivate, day: day)
    }

    @Test func listsWallLeadsWithWhatIsDueAndOpensItsList() {
        let trip = line("Packing")
        let chores = line("Chores")
        let wall = ListsWall.build(due: [due(trip, "Passports", day: "Fri", at: 30)], lists: [chores, trip])
        let texts = wall.words.sorted { $0.weight > $1.weight }.map(\.text)
        #expect(texts.prefix(2) == ["Packing", "Passports"])
        #expect(texts.contains("Chores"))
        #expect(wall.words.allSatisfy { wall.opens[$0.id] != nil })
        #expect(wall.opens.values.contains(trip.id) && wall.soonest == trip.id)
        #expect(wall.stateLine.first == "Packing is due Fri.")
    }

    @Test func listsWallNeverShowsAPrivateListOrItem() {
        let secret = line("Lexapro refills", isPrivate: true)
        let trip = line("Trip")
        let wall = ListsWall.build(due: [due(secret, "Pharmacy", day: "tomorrow", at: 26),
                                         due(trip, "Lexapro", day: "Fri", at: 30, isPrivate: true)],
                                   lists: [secret, trip])
        let shown = wall.words.map(\.text).joined(separator: " ").lowercased()
        #expect(!shown.contains("lexapro") && !shown.contains("pharmacy") && !shown.contains("private"))
        #expect(wall.hidden == 2)
        // The soonest is walled, so the dial's due door opens the shelf, and the header names only "Private list".
        #expect(wall.soonest == nil)
        #expect(wall.stateLine.allSatisfy { !$0.contains("Lexapro") && !$0.contains("Pharmacy") })
        #expect(wall.stateLine.first?.hasPrefix("Private list is due tomorrow") == true)
    }

    @Test func listsStateLineFormsAndEmptyState() {
        #expect(ListsWall.stateLine([]) == ["Nothing due this week."])
        let trip = line("Before the trip to the coast with everyone")
        let many = (0 ..< 5).map { due(trip, "Thing \($0)", day: "Wed", at: 28) }
        let forms = ListsWall.stateLine(many)
        #expect(forms.first == "Before the trip to the coast with everyone is due Wed, 5 things due this week.")
        #expect(forms.last == "5 due this week.")
        Self.checkForms(forms, "Lists state line")
        #expect(forms.allSatisfy { !$0.contains(" of ") })
    }

    // MARK: Money

    func spend(_ category: String, _ at: Int, isPrivate: Bool = false) -> MoneyWall.Spend {
        MoneyWall.Spend(category: category, at: Self.day(at), isPrivate: isPrivate)
    }

    @Test func moneyWallHoldsCategoriesAndNoAmounts() {
        let wall = MoneyWall.build(spends: [spend("lunch", 24), spend("12.40", 23), spend("$8", 22), spend("taxi", 21),
                                            spend("lunch", 20), spend("", 19)],
                                   monthCount: 6, monthName: "October",
                                   trend: "October is running a little under September.")
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
                                        trend: "September is running a little under August.")
        #expect(forms.first == "September is running a little under August, 12 spends so far.")
        #expect(forms.last == "12 spends.")
        Self.checkForms(forms, "Money state line")
        #expect(!forms.joined().contains("left"))
    }

    // MARK: Kitchen

    @Test func kitchenWallPutsLowAndCookableFirst() throws {
        let tacos = KitchenWall.Dish(id: UUID(), title: "Tacos", isPrivate: false, cookable: true)
        let dal = KitchenWall.Dish(id: UUID(), title: "Dal", isPrivate: false, cookable: false)
        let wall = KitchenWall.build(stock: [.init(name: "Eggs", state: .out, isPrivate: false),
                                             .init(name: "Milk", state: .low, isPrivate: false),
                                             .init(name: "Rice", state: .have, isPrivate: false)],
                                     dishes: [dal, tacos], tonight: nil, start: nil, cooking: nil)
        let ranked = wall.words.sorted { $0.weight > $1.weight }.map(\.text)
        #expect(Set(ranked.prefix(3)) == ["Eggs", "Milk", "Tacos"])
        #expect(ranked.last == "Rice")
        #expect(try wall.opens[#require(wall.words.first { $0.text == "Tacos" }?.id)] == .recipe(tacos.id))
        #expect(try wall.opens[#require(wall.words.first { $0.text == "Eggs" }?.id)] == .pantry)
        #expect(wall.lowLine?.first?.text == "Eggs and Milk run out first.")
        #expect(wall.stateLine.first == "Tonight? Nothing planned yet, you could make 1.")
    }

    @Test func kitchenWallNeverShowsAPrivateRecipeOrItem() {
        let secret = KitchenWall.Dish(id: UUID(), title: "Keto shake", isPrivate: true, cookable: true)
        let wall = KitchenWall.build(stock: [.init(name: "Private item", state: .low, isPrivate: true)],
                                     dishes: [secret], tonight: "Private recipe", start: "6:05", cooking: nil)
        #expect(wall.words.isEmpty)
        #expect(wall.hidden == 2 && wall.low.isEmpty && wall.cookable.isEmpty)
        #expect(wall.stateLine.first == "Private recipe tonight, start at 6:05.")
        #expect(!wall.stateLine.joined().contains("Keto"))
    }

    @Test func kitchenStateLineFormsAndEmptyState() {
        let empty = KitchenWall.stateLine(tonight: nil, start: nil, cooking: nil, cookable: 0)
        #expect(empty == ["Tonight? Nothing planned yet.", "Nothing planned yet."])
        Self.checkForms(empty, "Kitchen empty")
        let planned = KitchenWall.stateLine(tonight: "Tomato and white bean stew", start: "6:05",
                                            cooking: nil, cookable: 3)
        #expect(planned.last == "Tomato and white bean stew tonight.")
        Self.checkForms(planned, "Kitchen planned")
    }

    // MARK: Kit

    @Test func fitLineCutsOnWholeWordsNeverAnEllipsis() {
        let all = FitLine.candidates(["Tacos tonight, start at 6:05.", "Black bean tacos tonight with you."])
        #expect(all.prefix(2) == ["Tacos tonight, start at 6:05.", "Black bean tacos tonight with you."])
        #expect(all.dropFirst(2).first == "Black bean tacos tonight")
        #expect(all.last == "Black")
        #expect(all.allSatisfy { !$0.contains("...") && !$0.hasSuffix(",") })
    }
}
