import SwiftUI
@testable import Tessera
import Testing

@MainActor
struct GalleyCookModeTests {
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func facts(current: Int = 1, timer: Bool = true) -> GalleyCookFacts {
        let timerStep = GalleyCookFacts.Timer(id: "t", label: "Brown", endsAt: now.addingTimeInterval(167))
        var facts = GalleyCookFacts()
        facts.recipe = "Tacos"
        facts.current = current
        facts.now = now
        facts.minutesIn = 6
        facts.minutesLeft = 19
        facts.steps = [
            .init(
                index: 0,
                short: "Char the peppers",
                how: "Until blistered",
                ingredients: ["Peppers 2"],
                panMinutes: 4
            ),
            .init(
                index: 1,
                short: "Brown the chicken",
                how: "Cumin and salt",
                ingredients: ["Chicken thighs 1 lb", "Cumin 2 tsp"],
                panMinutes: 5,
                timer: timer ? timerStep : nil
            ),
            .init(index: 2, short: "Soften the onion", how: "", ingredients: []),
        ]
        return facts
    }

    @Test func stepsAreSaidInAFewWords() {
        #expect(GalleyCookWords.short("Brown the chicken in the oil for 5 minutes, then flip.") == "Brown the chicken")
        #expect(GalleyCookWords.short("Soften the onion until golden.") == "Soften the onion")
        #expect(GalleyCookWords.short("Stir.") == "Stir")
        #expect(GalleyCookWords.how("Brown the chicken in the oil for 5 minutes.", short: "Brown the chicken")
            == "In the oil for 5 minutes")
        #expect(!GalleyCookWords.short("Serve it warm.").hasSuffix("."))
    }

    @Test func clocksAndBands() {
        #expect(GalleyCookWords.clock(167) == "2:47")
        #expect(GalleyCookWords.clock(3905) == "1:05:05")
        let facts = facts()
        #expect(GalleyCookWords.band(facts) == ["6 min in", "3 steps, about 19 min to eat"])
        #expect(GalleyCookWords.header(facts) == "Step 2 of 3, 2:47 left")
        #expect(GalleyCookWords.header(self.facts(timer: false)) == "Step 2 of 3")
        #expect(GalleyCookWords.after(facts) == "Next, soften the onion")
    }

    @Test func eachPlaceHasItsJob() throws {
        let content = GalleyCookContent(facts: facts())
        let screen = content.screen(for: .landing(GalleyCookContent.room), state: RoomState(dialFocus: 1))
        #expect(screen.layout == .landing)
        guard case let .title(title, _)? = screen[.title]?.payload else { throw Failure.none }
        #expect(title == "Tacos")
        guard case let .widget(items)? = screen[.widget]?.payload else { throw Failure.none }
        #expect(items.first?.big == "Brown the chicken")
        #expect(items.first?.header == "Step 2 of 3, 2:47 left")
        guard case let .dial(doors)? = screen[.dial]?.payload else { throw Failure.none }
        #expect(doors.map(\.name) == ["Char the peppers", "Brown the chicken", "Soften the onion"])
        #expect(doors[1].count == "2:47" && doors[0].count == nil)
        guard case let .summary(door)? = screen[.doorSummary]?.payload else { throw Failure.none }
        #expect(door.lines == ["Chicken thighs 1 lb", "Cumin 2 tsp", "Pan time 5 min"])
        guard case let .action(steps, _)? = screen[.actionWord]?.payload else { throw Failure.none }
        #expect(steps.map(\.verb) == ["Next", "Timer", "Read", "Finish"])
        #expect(steps.last?.hold == true && steps.first?.hold == false)
    }

    @Test func theLastStepFinishesAndNoShownLineHasAStop() throws {
        let last = GalleyCookContent(facts: facts(current: 2))
        let screen = last.screen(for: .landing(GalleyCookContent.room), state: RoomState(dialFocus: 2))
        guard case let .action(steps, _)? = screen[.actionWord]?.payload else { throw Failure.none }
        #expect(steps.first?.verb == "Finish" && steps.first?.hold == true)
        for place in [Place.title, .needs, .caption] {
            if case let .lines(lines)? = screen[place]?.payload {
                #expect(lines.allSatisfy { !$0.hasSuffix(".") })
            }
        }
    }

    @Test func theRailHoldsTheStepAndEachPanTimer() {
        var facts = facts()
        facts.steps[0].timer = .init(id: "u", label: "Peppers", endsAt: now.addingTimeInterval(-5))
        let tickets = GalleyCookContent.tickets(facts)
        #expect(tickets.map(\.id) == ["cook.step", "cook.timer.0"])
        #expect(tickets[0].big && tickets[0].sub == "2:47 left")
        #expect(tickets[1].sub == "Ready" && tickets[1].ink == .runsOut)
    }

    private enum Failure: Error { case none }
}

@MainActor
struct GalleyShopModeTests {
    private func facts() -> GalleyShopFacts {
        var facts = GalleyShopFacts()
        facts.aisles = [
            .init(name: "Produce", items: [.init(id: "a", name: "Onions", amount: "2", why: "For the tacos tonight"),
                                           .init(id: "b", name: "Limes", amount: nil, why: nil)]),
            .init(name: "Dairy", items: [.init(id: "c", name: "Milk", amount: "1 gal", why: "You are low"),
                                         .init(id: "d", name: "Eggs", amount: "12", why: nil),
                                         .init(id: "e", name: "Butter", amount: nil, why: nil)]),
        ]
        facts.got = 4
        facts.tonight = "Tacos"
        return facts
    }

    @Test func wordsAndBand() {
        let facts = facts()
        #expect(GalleyShopWords.band(facts) == ["5 of 9 to get", "2 aisles to go"])
        #expect(GalleyShopWords.header(facts, aisle: 1) == "Dairy, 2 of 2")
        #expect(GalleyShopWords.after(facts.aisles[1]) == "After it, eggs, butter")
        #expect(GalleyShopWords.after(.init(name: "Last", items: [facts.aisles[0].items[0]])) == "Last in this aisle")
    }

    @Test func notHereMovesAThingToTheEnd() {
        let moved = GalleyShopWords.notHere(facts().aisles[1], item: "c")
        #expect(moved.items.map(\.name) == ["Eggs", "Butter", "Milk"])
    }

    @Test func eachPlaceHasItsJob() throws {
        let screen = GalleyShopContent(facts: facts()).screen(for: .landing(GalleyShopContent.room),
                                                              state: RoomState(dialFocus: 1))
        guard case let .widget(items)? = screen[.widget]?.payload else { throw Failure.none }
        #expect(items.first?.big == "Milk" && items.first?.middle == "1 gal" && items.first?.small == "You are low")
        #expect(items.first?.header == "Dairy, 2 of 2")
        guard case let .dial(doors)? = screen[.dial]?.payload else { throw Failure.none }
        #expect(doors.map(\.name) == ["Produce", "Dairy"] && doors.map(\.count) == ["2", "3"])
        guard case let .summary(door)? = screen[.doorSummary]?.payload else { throw Failure.none }
        #expect(door.lines == ["Milk 1 gal", "Eggs 12", "Butter"])
        guard case let .action(steps, _)? = screen[.actionWord]?.payload else { throw Failure.none }
        #expect(steps.map(\.verb) == ["Got", "Not here", "Pay"] && steps.last?.hold == true)
        let rail = GalleyShopContent.tickets(facts(), aisle: 1)
        #expect(rail.map(\.id) == ["shop.aisle", "shop.tonight"] && rail[0].lines == [
            "Milk 1 gal",
            "Eggs 12",
            "Butter",
        ])
    }

    private enum Failure: Error { case none }
}

struct GalleyCuesTests {
    @Test func heatAndDoneness() {
        #expect(GalleyCues.heat("Brown the chicken over medium-high heat for 5 minutes.") == "Medium high")
        #expect(GalleyCues.heat("Simmer until thick.") == "Low")
        #expect(GalleyCues.heat("Chop the onion.") == nil)
        #expect(GalleyCues.doneness("Brown the chicken.") == "Turn it when it lets go of the pan")
        #expect(GalleyCues.doneness("Chop the onion.") == nil)
    }

    @Test func aislesAndPicks() {
        #expect(GalleyCues.aisleSpot("Produce") == "Right by the doors")
        #expect(GalleyCues.aisleSpot("Dairy and eggs") == "Along the back wall")
        #expect(GalleyCues.aisleSpot("Mystery") == nil)
        #expect(GalleyCues.pick("Avocados") == "Pick ones that give a little")
        #expect(GalleyCues.pick("Whole milk") == "The date furthest out is at the back")
        #expect(GalleyCues.pick("Foil") == nil)
    }
}
