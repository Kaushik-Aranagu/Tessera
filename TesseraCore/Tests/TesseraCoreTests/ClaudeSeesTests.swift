import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// His Oct 27 call: nothing sent to Claude is filtered or masked for privacy. Only the Claude key stays on the phone.
/// The old walls are still tested under `.oldWalls`.
@MainActor
struct ClaudeSeesTests {
    let key = "sk-" + "ant-" + "made-up-for-a-test"

    @Test func onlyAKeyIsBlocked() {
        #expect(ClaudeSees.everything)
        let texts = ["Paid rent $2100", "Weighed 82.4 kg", "Ate 600 calories", "Refill lexapro 10mg", "Locker PIN 4271"]
        for text in texts {
            #expect(!ClaudeSees.blocks(text, walled: true), "\(text)")
        }
        #expect(ClaudeSees.blocks("my key is \(key)", walled: false))
        ClaudeSees.$everything.withValue(false) {
            #expect(ClaudeSees.blocks("Paid rent $2100", walled: true))
        }
    }

    @Test func homeLinesGoForAnyTitleButAKeyOrSteering() {
        let ended = Date(timeIntervalSince1970: 1_793_000_000)
        func done(_ title: String) -> HomeFact {
            HomeFact(id: UUID(), kind: .workout, title: title, state: .done, sets: 12, exercisesDone: 4,
                     exercisesPlanned: 5, records: ["Bench"], sinceLastDays: nil,
                     startedAt: ended.addingTimeInterval(-3600), endedAt: ended)
        }
        func walled(_ title: String) -> Bool {
            let pack = HomeDonePack.build(done(title), dayLabel: "Thursday night", calendar: .current,
                                          lastWeightKg: 82.4)
            return pack == .failure(.walled)
        }
        #expect(!walled("Knee rehab") && !walled("Weigh in 82.4") && !walled("Pay Dr Lee"))
        #expect(walled(key))
        ClaudeSees.$everything.withValue(false) {
            #expect(walled("Knee rehab"))
        }
    }

    @Test func dayPlanTitlesGoAsTheyAre() {
        let now = Date(timeIntervalSince1970: 1_793_000_000)
        func block(_ kind: DayPlan.Kind, _ title: String) -> DayPlan.Block {
            DayPlan.Block(kind: kind, title: title, start: now, end: now.addingTimeInterval(900), object: nil,
                          ghost: kind == .task, due: nil, movedFrom: nil, running: false)
        }
        for title in ["Coffee 6.25", "Pay Sam back $40", "Refill lexapro 10mg", "Reset my PIN"] {
            #expect(PlanPack.packTitle(block(.task, title), includesEventTitles: true, lastWeightKg: nil) == title)
        }
        let event = block(.event, "Dentist, copay $35")
        #expect(PlanPack.packTitle(event, includesEventTitles: true, lastWeightKg: nil) == "Dentist, copay $35")
        #expect(PlanPack.packTitle(block(.task, key), includesEventTitles: true, lastWeightKg: nil) == "task")
    }

    @Test func aRecipePageGoesWholeButAKeyLine() {
        let page = "Today the scale said 82.4\nPaid $12 for saffron\nAdd 1 onion\nmy key \(key)"
        let sent = ClaudeRecipeReader.sendable(page, lastWeightKg: 82.4)
        #expect(sent == "Today the scale said 82.4\nPaid $12 for saffron\nAdd 1 onion")
    }

    @Test func labReadsHisProfileAndStrictDoesNot() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let profile = try #require(classes[.meProfile])
        #expect(MemoryScope(.tess, policy: .lab).reads(profile, classes: classes))
        #expect(!MemoryScope(.tess, policy: .strict).reads(profile, classes: classes))
    }
}
