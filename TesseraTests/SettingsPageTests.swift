import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Batch 0 and AI-9: Settings' Review marks and What Tess knows' words.
@MainActor
struct SettingsPageTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    private func choice(_ id: String) throws -> ReviewChoices.Choice {
        try #require(ReviewChoices.all.first { $0.id == id })
    }

    /// Needs Claude wins over every other mark; Later for an entitlement; Soon for a feature on its way.
    @Test func reviewRowsSayWhatTheyWaitFor() throws {
        #expect(try ReviewSwitchCopy.mark(choice("planMyDay")) == "Needs Claude")
        #expect(try ReviewSwitchCopy.mark(choice("calendar")) == "Later")
        #expect(try ReviewSwitchCopy.mark(choice("pageTurn")) == "Soon")
        var live = try choice("pageTurn")
        live.readiness = .live
        #expect(ReviewSwitchCopy.mark(live) == nil)
        #expect(ReviewSwitchCopy.hint(live, value: "Today") == "Pages change as they do now.")
        #expect(try ReviewSwitchCopy.hint(choice("calendar"), value: "Off") == "Later: this needs a build with access.")
        #expect(ReviewSwitchCopy.pageOf(2, 3) == "2 of 3")
        #expect(ReviewSwitchCopy.facetPage("Workout", 2, 5) == "Workout, 2 of 5")
    }

    /// Design on #1127: every switch sits on one facet page, six at most, and the pages are named.
    @Test func everySwitchHasOneFacetPage() {
        let pages = ReviewChoices.facetPages()
        #expect(pages.allSatisfy { $0.rows.count <= 6 && !$0.word.isEmpty })
        let ids = pages.flatMap { $0.rows.map(\.id) }
        #expect(ids.count == ReviewChoices.all.count && Set(ids).count == ids.count)
        #expect(pages.first?.word == "Looks and day")
    }

    @Test func theMemoryDoorCountsInThirdPerson() {
        #expect(TessKnowsCopy.door("Nothing yet") == "Tess remembers nothing yet.")
        #expect(TessKnowsCopy.door("12 things") == "Tess remembers 12 things.")
        #expect(TessKnowsCopy.doorCount("12 things") == "12 things")
        #expect(TessKnowsCopy.doorCount("Nothing yet") == "nothing yet")
    }

    /// A told line shows on the page in its group; forgetting it takes it off and the receipt names the thing.
    @Test func aForgottenLineLeavesThePage() throws {
        let store = TessMemoryStore(engine: model.engine, forgetLogURL: nil)
        let kept = try model.engine.perform(RememberFact(text: "You rest on Sundays", area: .training), by: .user)
        #expect(store.grouped().flatMap(\.lines).contains { $0.id == kept.output.id })
        let forgotten = try model.engine.perform(ForgetMemory(memory: kept.output.id), by: .user)
        #expect(!store.grouped().flatMap(\.lines).contains { $0.id == kept.output.id })
        let receipt = forgotten.record.receipt ?? forgotten.record.summary
        #expect(receipt.hasSuffix("forgotten."))
        #expect(store.countLine() == "Nothing kept yet.")
    }

    /// Sheet 108: VoiceOver hears "Workout, tab 2 of 5"; at accessibility sizes the next tab reads "next: Kitchen".
    @Test func peekTabsSayWhereYouAre() {
        let tabs = ReviewChoices.facetPages().map(\.word)
        #expect(tabs == ["Looks and day", "Workout", "Kitchen", "Cooking", "Connected", "Shown"])
        #expect(PeekTabsCopy.spoken(tabs, 1) == "Workout, tab 2 of 6")
        #expect(PeekTabsCopy.next(tabs, 1) == "next: Kitchen")
        #expect(PeekTabsCopy.next(tabs, 5) == nil)
        // Every row is on a named page (no "More"), six at most.
        #expect(ReviewChoices.facetPages().allSatisfy { $0.rows.count <= 6 })
        // Measured: words never overlap, whatever their widths, and the current one is centred.
        let widths: [CGFloat] = [120, 60, 50, 90, 55]
        let centers = PeekTabsLayout.centers(widths: widths, selection: 1)
        #expect(centers[1] == 0)
        for index in 0 ..< widths.count - 1 {
            let gapBetween = (centers[index + 1] - widths[index + 1] / 2) - (centers[index] + widths[index] / 2)
            #expect(abs(gapBetween - PeekTabsLayout.gap) < 0.001)
        }
    }

    /// Six tabs (Cooking joined in #1163): still one gap edge to edge, whichever tab is current.
    @Test func sixTabsNeverOverlap() {
        let widths: [CGFloat] = [126, 74, 62, 70, 96, 58]
        for selection in widths.indices {
            let centers = PeekTabsLayout.centers(widths: widths, selection: selection)
            #expect(centers[selection] == 0)
            for index in 0 ..< widths.count - 1 {
                let gapBetween = (centers[index + 1] - widths[index + 1] / 2) - (centers[index] + widths[index] / 2)
                #expect(abs(gapBetween - PeekTabsLayout.gap) < 0.001)
            }
        }
    }

    /// Product, Oct 20: Settings draws only rows whose feature ships, so no row reads Soon or Later, and a tab with
    /// nothing live is not drawn.
    @Test func onlyShippedRowsAreDrawn() {
        let drawn = ReviewChoices.drawnPages()
        #expect(!drawn.isEmpty)
        #expect(drawn.allSatisfy { !$0.rows.isEmpty && $0.rows.count <= 6 })
        #expect(drawn.flatMap(\.rows).allSatisfy { $0.readiness == .live })
        let live = ReviewChoices.all.filter { $0.readiness == .live }.map(\.id)
        #expect(Set(drawn.flatMap(\.rows).map(\.id)) == Set(live))
        // The words keep the facets' order.
        let order = ReviewChoices.facets.map(\.word)
        let words = drawn.map(\.word)
        #expect(words == order.filter { words.contains($0) })
        // A waiting row stays off the page even when the row list asks for it.
        let waiting = ReviewChoices.Choice(id: "pantryState", name: "Pantry state", values: ["Off", "On"],
                                           defaultValue: "Off", says: [:], readiness: .arrivesWith("pantry state"))
        #expect(ReviewChoices.drawnPages([waiting]).isEmpty)
    }

    /// The page turn's timings follow the motion spec, and Reduce Motion is one 150 ms crossfade for every style.
    @Test func pageTurnTimingsFollowTheSpec() {
        #expect(PageTurnStyle.allCases.map(\.rawValue) == ["Today", "Slide", "Turn", "Soften", "Rotate"])
        #expect(abs(PageTurnTiming.total(.turn, rows: 6, reduceMotion: false) - 0.82) < 0.001)
        #expect(abs(PageTurnTiming.total(.rotate, rows: 6, reduceMotion: false) - 0.46) < 0.001)
        #expect(abs(PageTurnTiming.total(.rotate, rows: 3, reduceMotion: false) - 0.388) < 0.001)
        #expect(PageTurnTiming.total(.slide, rows: 6, reduceMotion: false) == 0.52)
        #expect(PageTurnStyle.allCases.allSatisfy { PageTurnTiming.total($0, rows: 6, reduceMotion: true) == 0.15 })
        #expect(PageTurnStyle.slide.isWholePage && !PageTurnStyle.turn.isWholePage)
    }

    /// Page turn ships: it is live, drawn on Looks and day, and Today (the default) keeps the pages sliding as before.
    @Test func pageTurnIsLiveOnLooksAndDay() throws {
        let row = try #require(ReviewChoices.all.first { $0.id == "pageTurn" })
        #expect(row.readiness == .live && row.defaultValue == "Today" && !row.needsClaude)
        let looks = try #require(ReviewChoices.drawnPages().first { $0.word == "Looks and day" })
        #expect(looks.rows.contains { $0.id == "pageTurn" })
        #expect(PageTurnStyle(rawValue: row.defaultValue) == .today)
    }
}
