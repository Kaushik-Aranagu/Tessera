import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Memory spec M5: the night pass merges duplicates, closes a changed usual time, confirms a noticed one, writes the
/// day (and Sunday's week) summary, prunes notebooks, refreshes moved packs, reflects per active room, and plans
/// nothing on a second run the same night.
struct NightPassTests {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        calendar.firstWeekday = 2
        return calendar
    }

    func at(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))
            ?? .distantPast
    }

    /// Saturday Oct 24, 4:05 am: Friday Oct 23 just closed.
    var pass: NightPass {
        NightPass(calendar: calendar, now: at(10, 24, 4, 5))
    }

    static let workout = UUID()

    func belief(_ key: TessBelief.Key = .usualTime, value: String = "{\"hour\":6}",
                source: TessBelief.Source = .noticed, from: Date, kept: Bool = false, confirmations: Int = 0,
                subject: TessBelief.Subject = .classDef(NightPassTests.workout), id: UUID = UUID()) -> TessBelief
    {
        TessBelief(id: id, subject: subject, key: key, value: value, confidence: 1, source: source, evidence: [UUID()],
                   evidenceOps: [], validFrom: from, validUntil: nil, supersedes: nil, uses: [],
                   confirmations: confirmations, kept: kept, words: "You usually train around 6 am.", isPrivate: false)
    }

    func revises(_ steps: [NightPass.Step]) -> Bool {
        steps.contains { step in
            if case .revise = step { return true }
            return false
        }
    }

    func trained(_ dates: [Date]) -> [NightPass.Event] {
        dates.map { NightPass.Event(id: UUID(), at: $0, classID: Self.workout, verb: "train") }
    }

    // MARK: The night

    @Test func theClosingDayFollowsTheFourAmEdge() {
        #expect(pass.night == "2026-10-23")
        #expect(NightPass(calendar: calendar, now: at(10, 24, 3, 55)).night == "2026-10-22")
    }

    @Test func aSecondRunTheSameNightPlansNothing() {
        let day = [NightPass.DayItem(kind: "workout", name: "Push Day", at: at(10, 23, 18, 30), room: "training")]
        #expect(!pass.plan(beliefs: [], series: [], day: day).isEmpty)
        #expect(pass.plan(beliefs: [], series: [], day: day, lastNight: pass.night).isEmpty)
    }

    // MARK: Usual times

    @Test func threeOffPatternOfTheLastFourRevisesTheUsualTime() {
        let six = belief(from: at(1, 5, 6))
        let events = trained([at(10, 14, 6), at(10, 16, 18, 30), at(10, 20, 18, 30), at(10, 23, 18)])
        let steps = pass.plan(beliefs: [six], series: events, day: [])
        let revise = steps.compactMap { step -> (UUID, String, String, [UUID])? in
            if case let .revise(belief, words, value, evidence) = step { return (belief, words, value, evidence) }
            return nil
        }
        #expect(revise.count == 1)
        #expect(revise.first?.0 == six.id)
        #expect(revise.first?.1 == "You usually train around 6:30 pm.")
        #expect(revise.first?.2 == "{\"hour\":18.5}")
        #expect(revise.first?.3 == Array(events.dropFirst().map(\.id)))
    }

    @Test func twoOffIsNotAChange() {
        let six = belief(from: at(1, 5, 6))
        let events = trained([at(10, 14, 6), at(10, 16, 18, 30), at(10, 20, 6, 15), at(10, 23, 18)])
        #expect(!revises(pass.plan(beliefs: [six], series: events, day: [])))
    }

    @Test func whatHeToldOrKeptIsNeverRevised() {
        let events = trained([at(10, 14, 18), at(10, 16, 18, 30), at(10, 20, 18, 30), at(10, 23, 18)])
        let told = belief(source: .told, from: at(1, 5, 6))
        let kept = belief(from: at(1, 5, 6), kept: true)
        #expect(!revises(pass.plan(beliefs: [told], series: events, day: [])))
        #expect(!revises(pass.plan(beliefs: [kept], series: events, day: [])))
    }

    @Test func aNoticedTimeOnPatternIsConfirmedOnlyWithNewEvidence() {
        let six = belief(from: at(1, 5, 6))
        let today = trained([at(10, 14, 6), at(10, 16, 6, 30), at(10, 20, 5, 45), at(10, 23, 6, 10)])
        #expect(pass.plan(beliefs: [six], series: today, day: []).contains(.confirm(belief: six.id)))
        // Nothing new on the closing day: last night already counted these.
        let old = trained([at(10, 14, 6), at(10, 16, 6, 30), at(10, 20, 5, 45), at(10, 21, 6, 10)])
        #expect(!pass.plan(beliefs: [six], series: old, day: []).contains(.confirm(belief: six.id)))
        // A fact needs no more confirming.
        let fact = belief(from: at(1, 5, 6), confirmations: 2)
        #expect(!pass.plan(beliefs: [fact], series: today, day: []).contains(.confirm(belief: fact.id)))
    }

    @Test func aUsualTimeAboutNoClassIsLeftAlone() {
        let you = belief(from: at(1, 5, 6), subject: .you)
        let events = trained([at(10, 14, 18), at(10, 16, 18, 30), at(10, 20, 18, 30), at(10, 23, 18)])
        let steps = pass.plan(beliefs: [you], series: events, day: [])
        #expect(!revises(steps) && !steps.contains(.confirm(belief: you.id)))
    }

    @Test func eventsBeforeTheBeliefDontCount() {
        let six = belief(from: at(10, 15, 0))
        let events = trained([at(10, 1, 18), at(10, 2, 18), at(10, 16, 6), at(10, 23, 6)])
        // Only two events since it began: too few to change or confirm it.
        let steps = pass.plan(beliefs: [six], series: events, day: [])
        #expect(!revises(steps) && !steps.contains(.confirm(belief: six.id)))
    }

    // MARK: Merge

    @Test func duplicatesMergeIntoTheKeptThenTheMostConfirmed() {
        let first = belief(.prefers, value: "{\"text\":\"rice\"}", from: at(3, 1, 9), confirmations: 1)
        let second = belief(.prefers, value: "{\"text\": \"rice\"}", from: at(4, 1, 9), confirmations: 3)
        let kept = belief(.prefers, value: "{\"text\":\"rice\"}", from: at(5, 1, 9), kept: true)
        let beans = belief(.prefers, value: "{\"text\":\"beans\"}", from: at(5, 1, 9))
        let steps = pass.plan(beliefs: [first, second, kept, beans], series: [], day: [])
        #expect(steps.contains(.merge(keep: kept.id, close: first.id)))
        #expect(steps.contains(.merge(keep: kept.id, close: second.id)))
        // He can prefer two things: beans stays open.
        #expect(!steps.contains { if case let .merge(_, close) = $0 { close == beans.id } else { false } })
    }

    @Test func twoUsualTimesThatDisagreeKeepTheNewestUnlessHeToldOne() {
        let old = belief(from: at(3, 1, 9))
        let new = belief(value: "{\"hour\":18}", from: at(9, 1, 9))
        #expect(pass.plan(beliefs: [old, new], series: [], day: []).contains(.merge(keep: new.id, close: old.id)))
        let told = belief(source: .told, from: at(3, 1, 9))
        #expect(pass.plan(beliefs: [told, new], series: [], day: []).contains(.merge(keep: told.id, close: new.id)))
    }

    // MARK: Summaries

    @Test func theDaySummaryCountsByKindWithShownNames() {
        let day = [
            NightPass.DayItem(kind: "task done", name: "Pay rent", at: at(10, 23, 9), room: "today"),
            NightPass.DayItem(kind: "workout", name: "Push Day", at: at(10, 23, 7), room: "training"),
            NightPass.DayItem(kind: "workout", name: "Private workout", at: at(10, 23, 18), room: "training"),
        ]
        let steps = pass.plan(beliefs: [], series: [], day: day)
        #expect(steps.contains(.summary(path: "/summaries/day/2026-10-23",
                                        text: "2 workouts: Push Day, Private workout\n1 task done: Pay rent")))
        // Friday closed, so no week summary.
        #expect(!steps.contains { if case let .summary(path, _) = $0 { path.contains("week") } else { false } })
        #expect(NightPass.lines([], empty: "A quiet day.") == "A quiet day.")
        let notes = [NightPass.DayItem(kind: "note", name: "", at: at(10, 23, 9), room: "notes"),
                     NightPass.DayItem(kind: "note", name: "", at: at(10, 23, 10), room: "notes")]
        #expect(NightPass.lines(notes, empty: "") == "2 notes")
    }

    @Test func sundayNightAddsTheWeek() {
        let monday = NightPass(calendar: calendar, now: at(10, 26, 4, 5))
        #expect(monday.night == "2026-10-25")
        let week = [NightPass.DayItem(kind: "cook", name: "Turkey Chili", at: at(10, 20, 19), room: "kitchen")]
        let steps = monday.plan(beliefs: [], series: [], day: [], week: week)
        #expect(steps.contains(.summary(path: "/summaries/week/2026-W43", text: "1 cook: Turkey Chili")))
        #expect(steps.contains(.summary(path: "/summaries/day/2026-10-25", text: "A quiet day.")))
    }

    @Test func clockWordsReadPlainly() {
        #expect(NightPass.clock(18) == "6 pm")
        #expect(NightPass.clock(6.5) == "6:30 am")
        #expect(NightPass.clock(12) == "noon")
        #expect(NightPass.clock(0) == "12 am")
        #expect(NightPass.plural("task done") == "tasks done")
    }

    // MARK: Notebooks, packs and reflection

    @Test func notebooksOverTheLimitLoseTheirOldestUnusedFiles() {
        let files = [
            NightPass.NotebookFile(path: "/memories/training/old.md", bytes: 20000, lastUsed: at(6, 1, 9)),
            NightPass.NotebookFile(path: "/memories/training/new.md", bytes: 20000, lastUsed: at(10, 20, 9)),
            NightPass.NotebookFile(path: "/memories/kitchen/a.md", bytes: 30000, lastUsed: at(1, 1, 9)),
        ]
        let steps = pass.plan(beliefs: [], series: [], day: [], notebooks: files)
        #expect(steps.contains(.prune(path: "/memories/training/old.md")))
        #expect(!steps.contains(.prune(path: "/memories/training/new.md")))
        #expect(!steps.contains(.prune(path: "/memories/kitchen/a.md")))
    }

    @MainActor
    @Test func movedPacksRefreshAndActiveRoomsReflect() {
        let day = [NightPass.DayItem(kind: "cook", name: "Turkey Chili", at: at(10, 23, 19), room: "kitchen")]
        let steps = pass.plan(beliefs: [], series: [], day: day,
                              packs: [.training: (now: "a", built: "a"), .kitchen: (now: "b", built: "c")],
                              agents: AgentSpec.available(under: .strict))
        #expect(steps.contains(.refresh(.kitchen)) && !steps.contains(.refresh(.training)))
        #expect(steps.contains(.reflect(agent: "Kitchen")) && steps.contains(.reflect(agent: "Tess")))
        #expect(!steps.contains(.reflect(agent: "Training")))
        // A quiet day asks nobody.
        let quiet = pass.plan(beliefs: [], series: [], day: [], agents: AgentSpec.shipped)
        #expect(!quiet.contains { if case .reflect = $0 { true } else { false } })
    }
}
