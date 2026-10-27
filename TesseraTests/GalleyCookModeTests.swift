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
        facts.serves = 2
        facts.current = current
        facts.now = now
        facts.minutesIn = 6
        facts.minutesLeft = 19
        facts.steps = [
            .init(index: 0, short: "Char the peppers", how: "Until blistered", ingredients: ["Peppers 2"],
                  needs: [.init(name: "Peppers", amount: "2")], line: "Char the peppers", panMinutes: 4),
            .init(index: 1, short: "Brown the chicken", how: "Cumin and salt",
                  ingredients: ["Chicken thighs 1 lb", "Cumin 2 tsp"],
                  needs: [.init(name: "Chicken thighs", amount: "1 lb"), .init(name: "Cumin", amount: "2 tsp")],
                  line: "Brown the chicken in the oil", heat: "Medium high",
                  cue: "Turn it when it lets go of the pan", panMinutes: 5, timer: timer ? timerStep : nil),
            .init(index: 2, short: "Soften the onion", how: "", line: "Soften the onion"),
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
        #expect(GalleyCookWords.line("Brown the chicken in the oil for 5 minutes. Then flip it.")
            == "Brown the chicken in the oil for 5 minutes")
    }

    @Test func clocks() {
        #expect(GalleyCookWords.clock(167) == "2:47")
        #expect(GalleyCookWords.clock(3905) == "1:05:05")
        #expect(GalleyCookWords.minutes(5) == "5 min")
    }

    @Test func theWholeScreenReadsTopToBottom() {
        let screen = GalleyCookScreen(facts())
        #expect(screen.title == "Tacos for 2" && screen.topRight == "6 min in")
        #expect(screen.number == "2" && screen.heat == "Medium high")
        #expect(screen.instruction == "Brown the chicken in the oil" && screen.how == "Cumin and salt")
        #expect(screen.doneWhen == "Turn it when it lets go of the pan")
        #expect(screen.needs.map(\.name) == ["Chicken thighs", "Cumin"] && screen.needs.first?.amount == "1 lb")
        #expect(screen.timers.map(\.time) == ["2:47"] && screen.timers.first?.ready == false)
        #expect(screen.start == nil)
        #expect(screen.verb == "Next" && screen.object == "Soften the onion" && !screen.hold)
        #expect(screen.rail.map(\.label) == ["Char the peppers", "Brown the chicken", "Soften the onion"])
        #expect(screen.rail.map(\.current) == [false, true, false] && screen.rail[0].done)
    }

    @Test func aStepWithAPanTimeOffersToStartIt() {
        let screen = GalleyCookScreen(facts(timer: false))
        #expect(screen.timers.isEmpty && screen.start == "Start 5 min")
    }

    @Test func aDoneTimerReadsReadyAndTheLastStepFinishes() {
        var facts = facts(current: 2)
        facts.steps[1].timer = .init(id: "u", label: "Chicken", endsAt: now.addingTimeInterval(-5))
        let screen = GalleyCookScreen(facts)
        #expect(screen.timers.first?.time == "Ready" && screen.timers.first?.ready == true)
        #expect(screen.verb == "Finish" && screen.hold && screen.object == "Tacos")
    }

    @Test func noShownLineEndsWithAFullStop() {
        let screen = GalleyCookScreen(facts())
        for line in [screen.title, screen.topRight, screen.instruction, screen.how, screen.heat ?? "",
                     screen.doneWhen ?? "", screen.object]
        {
            #expect(!line.hasSuffix("."))
        }
    }
}

@MainActor
struct GalleyShopModeTests {
    private func facts() -> GalleyShopFacts {
        var facts = GalleyShopFacts()
        facts.aisles = [
            .init(name: "Produce", items: [.init(id: "a", name: "Onions", amount: "2", why: "For the tacos tonight"),
                                           .init(id: "b", name: "Limes", amount: nil, why: nil)]),
            .init(name: "Dairy and eggs", items: [.init(id: "c", name: "Milk", amount: "1 gal", why: "You are low"),
                                                  .init(id: "d", name: "Eggs", amount: "12", why: nil)],
                  got: [.init(id: "x", name: "Butter", amount: nil, why: nil)]),
        ]
        facts.got = 4
        facts.tonight = "Tacos"
        facts.tonightLines = ["Onions 2", "Limes"]
        facts.tonightGot = [1]
        return facts
    }

    @Test func theWholeScreenReadsTopToBottom() {
        let screen = GalleyShopScreen(facts(), aisle: 1)
        #expect(screen.aisle == "Dairy and eggs" && screen.spot == "Along the back wall")
        #expect(screen.topRight == "4 of 8 to get, tonight 1 of 2")
        #expect(screen.thing == "Milk" && screen.amount == "1 gal" && screen.why == "You are low")
        #expect(screen.tip == "The date furthest out is at the back")
        #expect(screen.inAisle.map(\.name) == ["Milk", "Eggs", "Butter"] && screen.inAisle.map(\.struck) == [
            false,
            false,
            true,
        ])
        #expect(screen.after == nil && screen.verb == "Got" && screen.object == "Milk")
        #expect(screen.rail.map(\.detail) == ["2", "2"] && screen.rail.map(\.current) == [false, true])
    }

    @Test func theFirstAisleSaysWhatIsAfterIt() {
        let screen = GalleyShopScreen(facts(), aisle: 0)
        #expect(screen.spot == "Right by the doors" && screen.after == "Dairy and eggs, along the back wall")
        #expect(screen.thing == "Onions" && screen.why == "For the tacos tonight")
    }

    @Test func anEmptyListSaysSo() {
        let screen = GalleyShopScreen(GalleyShopFacts(), aisle: 0)
        #expect(screen.empty && screen.topRight == "Nothing to get" && screen.rail.isEmpty)
    }
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

struct GalleyPenStrokeTests {
    /// Sheet 332: the stroke runs left to right at a slight angle (the right end a little higher).
    @Test func theStrokeRunsLeftToRightAtASlightAngle() {
        let ends = GalleyPenStroke.ends(in: CGRect(x: 0, y: 0, width: 200, height: 80))
        #expect(ends.start.x == 0 && ends.end.x == 200)
        #expect(ends.end.y < ends.start.y && ends.start.y - ends.end.y < 20)
        #expect(GalleyPenStroke(progress: 0.5).animatableData == 0.5)
    }
}
