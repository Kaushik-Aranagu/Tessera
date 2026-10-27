import Foundation
@testable import Tessera
import Testing

/// A sample feed, as Builder B's cook will give it: chicken just ended, onions 5:58 away.
struct SampleCookReadyFeed: CookReadyFeed {
    var isPrivate = false
    let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func ready(at _: Date) -> CookReadyInput? {
        CookReadyInput(food: "Chicken", endedAt: now, next: ("onions to go", now.addingTimeInterval(358)),
                       cookID: "C1", isPrivate: isPrivate)
    }
}

@Suite("Cooking activity: ready")
struct CookReadyActivityTests {
    @Test("The ready words and the lock screen line")
    func words() {
        #expect(CookFace.readyWord(food: "Chicken") == "Chicken ready")
        #expect(CookFace.readyLine == "READY, OFF THE HEAT")
    }

    @Test("The ready colour is wine 9A2541 mixed 45% toward white")
    func wine() {
        let wine = CookFace.readyWine
        #expect(wine.red == 199 && wine.green == 135 && wine.blue == 150)
        let none = CookFace.mix(red: 10, green: 20, blue: 30, towardWhite: 0)
        #expect(none.red == 10 && none.green == 20 && none.blue == 30)
        let all = CookFace.mix(red: 10, green: 20, blue: 30, towardWhite: 1)
        #expect(all.red == 255 && all.blue == 255)
    }

    @Test("It swells once, 1.08 by 1.14 over 520 ms, and not under Reduce Motion")
    func swell() {
        #expect(CookFace.swell.x == 1.08 && CookFace.swell.y == 1.14 && CookFace.swell.duration == 0.52)
        #expect(CookFace.swells(reduceMotion: false))
        #expect(!CookFace.swells(reduceMotion: true))
    }

    @Test("A sample feed becomes a ready state with the next timer and the ticket link")
    func sample() throws {
        let feed = SampleCookReadyFeed()
        let state = try #require(CookReadyFace.state(from: feed, at: feed.now))
        #expect(state.isReady)
        #expect(state.readyFood == "Chicken")
        #expect(state.nextLabel == "onions to go")
        #expect(state.nextEndsAt == feed.now.addingTimeInterval(358))
        #expect(state.link?.absoluteString == "tessera://cook?cook=C1&alert=Chicken")
    }

    @Test("Nothing ended: no ready state")
    func none() {
        struct Empty: CookReadyFeed {
            func ready(at _: Date) -> CookReadyInput? {
                nil
            }
        }
        #expect(CookReadyFace.state(from: Empty(), at: .now) == nil)
    }

    @Test("A private cook's payload carries Timer and no food, label or name")
    func privateCook() throws {
        var feed = SampleCookReadyFeed()
        feed.isPrivate = true
        let state = try #require(CookReadyFace.state(from: feed, at: feed.now))
        #expect(state.readyFood == "Timer")
        #expect(state.nextLabel == nil)
        let json = try String(decoding: JSONEncoder().encode(state), as: UTF8.self)
        for banned in ["Chicken", "chicken", "onions"] {
            #expect(!json.contains(banned), "payload leaked \(banned)")
        }
    }

    @Test("A ready state in the old decoder's shape still decodes: the new fields are optional")
    func oldStatesDecode() throws {
        let old = CookActivityAttributes.ContentState(timerLabel: "Sear", endsAt: .now, total: 60, others: 0,
                                                      nextStep: nil)
        let data = try JSONEncoder().encode(old)
        let back = try JSONDecoder().decode(CookActivityAttributes.ContentState.self, from: data)
        #expect(!back.isReady && back.link == nil)
    }
}
