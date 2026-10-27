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
        facts.eatAt = "6:35"
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
        #expect(screen.title == "Tacos for 2" && screen.topRight == "6 min in, eat about 6:35")
        #expect(screen.number == "2" && screen.of == "of 3" && screen.heat == "Medium high")
        #expect(screen.instruction == "Brown the chicken in the oil" && screen.how == "Cumin and salt")
        var dup = facts()
        dup.steps[1] = .init(index: 1, short: "Heat the oven", how: "To 425°F", line: "Heat the oven to 425°F")
        #expect(GalleyCookScreen(dup).how.isEmpty)
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
        #expect(screen.verb == "Serve" && screen.hold && screen.object == "Tacos")
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
        #expect(GalleyShopScreen(facts(), aisle: 0).amount == "\u{00D7} 2")
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
        #expect(GalleyCues.doneness("Heat the oven to 425°F.") == "Ready when the oven reaches 425°F")
        #expect(GalleyCues.heatNote("Brown the chicken in the oil.") == "a spoon of oil")
        #expect(GalleyCues.heatNote("Chop the onion.") == nil)
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

struct GalleyPrinterTests {
    /// Sheet 333: the ticket printer feeds 30 pt with a 4 pt overshoot in five steps, then settles.
    @Test func thePaperFeedsInFiveStepsWithAnOvershoot() {
        let steps = GalleyPrinter.feedSteps
        #expect(steps.count == 6 && steps[4] == 34 && steps.last == 30)
        #expect(GalleyPrinter.stepMilliseconds * 5 == 520)
        #expect(zip(steps, steps.dropFirst()).prefix(4).allSatisfy { $0.0 < $0.1 })
    }

    @Test func theReadyLineNamesTheFoodFromTheTimer() {
        #expect(GalleyCookWords.readyLine(label: "Chicken") == "Chicken ready, off the heat")
        #expect(GalleyCookWords.readyLine(label: "Brown the chicken") == "Chicken ready, off the heat")
        #expect(GalleyCookWords.readyLine(label: "") == "Timer ready, off the heat")
        #expect(!GalleyCookWords.readyLine(label: "Rice").hasSuffix("."))
    }

    /// The printed colour stays clear of Tess's Ember (FF5A26 and FF6B3D): ΔE76 of 25 or more, as the colour roles say.
    @Test func thePrintedColourStaysClearOfEmber() {
        func lab(_ hex: UInt32) -> (Double, Double, Double) {
            func linear(_ value: UInt32) -> Double {
                let c = Double(value) / 255
                return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
            }
            let r = linear((hex >> 16) & 255), g = linear((hex >> 8) & 255), b = linear(hex & 255)
            func f(_ t: Double) -> Double {
                t > 0.008856 ? cbrt(t) : 7.787 * t + 16.0 / 116
            }
            let x = f((0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047)
            let y = f(0.2126 * r + 0.7152 * g + 0.0722 * b)
            let z = f((0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883)
            return (116 * y - 16, 500 * (x - y), 200 * (y - z))
        }
        let printed = lab(0x8C2F39)
        for ember: UInt32 in [0xFF5A26, 0xFF6B3D] {
            let other = lab(ember)
            let distance =
                ((printed.0 - other.0) * (printed.0 - other.0) + (printed.1 - other.1) * (printed.1 - other.1)
                        + (printed.2 - other.2) * (printed.2 - other.2)).squareRoot()
            #expect(distance >= 25)
        }
    }
}

struct GalleyTearOffTests {
    /// Sheet 334: six even steps from 40 pt up to a 4 pt overshoot, then the settle at home.
    @Test func thePaidTicketPrintsInInSixStepsWithAnOvershoot() {
        let steps = GalleyTearOff.steps
        #expect(steps.count == 7 && steps[5] == 4 && steps.last == 0)
        #expect(zip(steps, steps.dropFirst()).prefix(5).allSatisfy { $0.0 < $0.1 })
        #expect(steps[0] > GalleyTearOff.from)
        #expect(GalleyTearOff.liftX == -18 && GalleyTearOff.liftY == -70 && GalleyTearOff.angle == -5)
        #expect(GalleyTearOff.delay < GalleyTearOff.fade)
    }
}

struct GalleySpikeTests {
    /// Sheet 337: eight even steps to the whole summary; the ticket narrows to .18 x .06 and rises 24 pt.
    @Test func theSummaryPrintsDownInEightSteps() {
        #expect(GalleySpike.reveal.count == 8 && GalleySpike.reveal.last == 1 && GalleySpike.reveal.first == 0.125)
        #expect(GalleySpike.scaleX == 0.18 && GalleySpike.scaleY == 0.06 && GalleySpike.rise == 24)
        #expect(GalleySpike.printDelay < GalleySpike.fade)
    }

    @Test func theEatSummarySaysWhatWasCooked() {
        var facts = GalleyCookFacts()
        facts.recipe = "Tacos"
        facts.serves = 2
        facts.minutesIn = 38
        facts.steps = [.init(index: 0, short: "Char", how: ""), .init(index: 1, short: "Serve", how: "")]
        let eat = GalleyCookEat(facts)
        #expect(eat.title == "Eat" && eat.dish == "Tacos for 2" && eat.detail == "Cooked in 38 min, 2 steps")
        #expect(!eat.detail.hasSuffix("."))
    }
}

struct CookAlertContentTests {
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func timer(_ label: String, _ seconds: TimeInterval) -> CookTimerInput {
        CookTimerInput(label: label, endsAt: now.addingTimeInterval(seconds), startedAt: now.addingTimeInterval(-600))
    }

    /// Sheet 344: when a pan timer ends the activity names the food and says READY, OFF THE HEAT; the next timer that
    /// still runs reads as "onions to go" beside its countdown; the link opens the ticket with the alert printed.
    @Test func aTimerThatEndedNamesTheFoodAndTheNextOneIsToGo() throws {
        let state = try #require(CookFace.state(timers: [timer("Brown the chicken", -3), timer("Onions", 358)],
                                                nextStep: nil, isPrivate: false, appNow: now, realNow: now))
        #expect(state.readyFood == "Chicken" && CookFace.readyLine == "READY, OFF THE HEAT")
        #expect(state.timerLabel == "Onions" && state.nextLabel == nil)
        let two = try #require(CookFace.state(
            timers: [timer("Rice", 60), timer("Onions", 358), timer("Brown the chicken", -3)],
            nextStep: nil,
            isPrivate: false,
            appNow: now,
            realNow: now
        ))
        #expect(two.nextLabel == "onions to go" && two.nextEndsAt != nil && two.readyFood == "Chicken")
    }

    @Test func theLastTimerEndingKeepsTheActivityToSayReady() throws {
        let state = try #require(CookFace.state(timers: [timer("Rice", -2)], nextStep: nil, isPrivate: false,
                                                appNow: now, realNow: now))
        #expect(state.readyFood == "Rice" && state.others == 0)
        #expect(CookFace.state(timers: [], nextStep: nil, isPrivate: false, appNow: now, realNow: now) == nil)
    }

    @Test func aPrivateCookNamesNoFood() throws {
        let state = try #require(CookFace.state(timers: [timer("Secret stew", -1), timer("Hidden", 90)], nextStep: "x",
                                                isPrivate: true, appNow: now, realNow: now))
        #expect(state.readyFood == "Timer" && state.timerLabel == "Timer" && state.nextStep == nil)
        #expect(state.nextLabel == nil || state.nextLabel == "timer to go")
    }

    @Test func theLinkNamesTheCookAndTheAlert() throws {
        let cook = UUID()
        let url = try #require(CookFace.alertLink(cook: cook, food: "Chicken"))
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(url.scheme == "tessera" && url.host() == "cook")
        #expect(items.first { $0.name == "cook" }?.value == cook.uuidString)
        #expect(items.first { $0.name == "alert" }?.value == "Chicken")
    }
}

struct GalleyNotHereTests {
    private func line(_ id: String, struck: Bool = false) -> GalleyShopScreen.Line {
        .init(id: id, name: id, amount: nil, struck: struck)
    }

    /// Sheet 339: the other rows slide up without the moving one; it lands after the open rows and before the struck.
    @Test func theSkippedRowSettlesInLastWithoutCrossingAnyOther() {
        let rows = [line("a"), line("b"), line("c"), line("x", struck: true)]
        let plan = GalleyNotHere.plan(rows: rows, moving: "a")
        #expect(plan.without.map(\.id) == ["b", "c", "x"])
        #expect(plan.final.map(\.id) == ["b", "c", "a", "x"])
        #expect(GalleyNotHere.slide == 0.34 && GalleyNotHere.settle == 0.44)
        // A thing that is not there changes nothing.
        #expect(GalleyNotHere.plan(rows: rows, moving: "z").final.map(\.id) == ["a", "b", "c", "x"])
    }
}

struct GalleyCoveredTests {
    /// Sheet 342: covered only when a planned dish has things on the list and every one is in the basket.
    @Test func tonightIsCoveredWhenEverythingIsGot() {
        var facts = GalleyShopFacts()
        #expect(!facts.tonightCovered && facts.coveredLine == nil)
        facts.tonight = "Tacos"
        #expect(!facts.tonightCovered)
        facts.tonightLines = ["Onions", "Limes"]
        facts.tonightGot = [0]
        #expect(!facts.tonightCovered)
        facts.tonightGot = [0, 1]
        #expect(facts.tonightCovered && facts.coveredLine == "Everything for the tacos")
        #expect(!(facts.coveredLine ?? "").hasSuffix("."))
    }
}
