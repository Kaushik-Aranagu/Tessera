import Foundation
import SwiftUI
@testable import Tessera
import TesseraCore
import Testing
import UIKit

/// Design 142, surfaces v2: the clause line, the "+2" rule, the masks and the wall, all pure.
struct SurfacesV2Tests {
    private func clause(_ app: String, _ text: String, key: String? = nil, at: Date? = nil) -> SurfaceClause {
        let range = key.flatMap { text.range(of: $0) }.map {
            text.utf16.distance(from: text.startIndex, to: $0.lowerBound) ..< text.utf16.distance(
                from: text.startIndex, to: $0.upperBound
            )
        }
        return SurfaceClause(app: app, text: text, keyFrom: range?.lowerBound, keyTo: range?.upperBound, at: at)
    }

    private let noon = Date(timeIntervalSinceReferenceDate: 800_000_000)

    // MARK: the switch

    @Test func theSwitchIsOffUnlessOn() {
        #expect(!SurfacesV2.isOn(value: nil))
        #expect(!SurfacesV2.isOn(value: "Off"))
        #expect(SurfacesV2.isOn(value: "On"))
        let choice = ReviewChoices.all.first { $0.id == SurfacesV2.choiceID }
        #expect(choice?.defaultValue == "Off")
    }

    @Test func offClearsTheSnapshotAndTheFlag() throws {
        let defaults = try #require(UserDefaults(suiteName: "SurfacesV2Tests.\(UUID().uuidString)"))
        SurfacesSnapshot.store([clause("training", "Push A today", key: "Push A")], on: true, now: noon, in: defaults)
        #expect(SurfacesSnapshot.read(from: defaults)?.clauses.count == 1)
        SurfacesSnapshot.store([clause("training", "Push A today")], on: false, now: noon, in: defaults)
        #expect(SurfacesSnapshot.read(from: defaults) == nil)
        #expect(defaults.data(forKey: SurfacesV2.snapshotKey) == nil)
    }

    @Test func aSnapshotWithoutTheFlagIsNotRead() throws {
        let defaults = try #require(UserDefaults(suiteName: "SurfacesV2Tests.\(UUID().uuidString)"))
        defaults.set(SurfacesSnapshot(written: noon, clauses: [clause("notes", "A new loose note")]).encoded(),
                     forKey: SurfacesV2.snapshotKey)
        #expect(SurfacesSnapshot.read(from: defaults) == nil)
    }

    // MARK: the clause line

    @Test func keyWordIsItsOwnRun() {
        let runs = SurfaceLine.runs(clause("training", "Push A today, about 45 min", key: "Push A"))
        #expect(runs == [.init(text: "Push A", isKey: true), .init(text: " today, about 45 min", isKey: false)])
        let mid = SurfaceLine.runs(clause("kitchen", "Tacos tonight", key: "tonight"))
        #expect(mid.map(\.text) == ["Tacos ", "tonight"])
        #expect(mid[1].isKey)
        #expect(SurfaceLine.runs(clause("notes", "A new loose note")) == [.init(
            text: "A new loose note",
            isKey: false
        )])
    }

    @Test func aBadKeyRangeFallsBackToPlain() {
        var bad = clause("lists", "Short")
        bad.keyFrom = 3
        bad.keyTo = 99
        #expect(SurfaceLine.runs(bad) == [.init(text: "Short", isKey: false)])
    }

    @Test func keyRangesCountUTF16() {
        let line = clause("kitchen", "Crème brûlée tonight", key: "tonight")
        #expect(SurfaceLine.runs(line).first(where: \.isKey)?.text == "tonight")
    }

    @Test func nextIsTheEarliestTimedClauseAhead() {
        let soon = clause("training", "Push A today", at: noon.addingTimeInterval(3600))
        let later = clause("kitchen", "Tacos tonight", at: noon.addingTimeInterval(7200))
        let untimed = clause("notes", "A new loose note")
        let day = [untimed, later, soon]
        #expect(SurfaceLine.next(day, now: noon)?.text == "Push A today")
        #expect(SurfaceLine.next(day, now: noon.addingTimeInterval(5000))?.text == "Tacos tonight")
        // Past every time: the untimed one.
        #expect(SurfaceLine.next(day, now: noon.addingTimeInterval(9000))?.text == "A new loose note")
        #expect(SurfaceLine.next([], now: noon) == nil)
        // A clause stays next for a few minutes after its time.
        #expect(SurfaceLine.next([soon], now: noon.addingTimeInterval(3600 + 300))?.text == "Push A today")
    }

    @Test func theInlineLineIsTheTimeAndTheKeyWord() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let six = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 10,
            day: 22,
            hour: 18,
            minute: 10
        )))
        #expect(SurfaceLine.inline(clause("training", "Push A today", key: "Push A", at: six), calendar: calendar)
            == "6:10 pm Push A")
        #expect(SurfaceLine.inline(clause("notes", "A new loose note"), calendar: calendar) == "A new loose note")
    }

    @Test func faceChangesAtEachLaterClauseTime() {
        let day = [
            clause("a", "x", at: noon.addingTimeInterval(-60)),
            clause("b", "y", at: noon.addingTimeInterval(60)),
            clause("c", "z", at: noon.addingTimeInterval(60)),
            clause("d", "w"),
        ]
        #expect(SurfaceLine.changeDates(day, now: noon) == [noon, noon.addingTimeInterval(60)])
    }

    @Test func mapsACoreClause() {
        let sentence = LandingSentences.money(nothingLate: false, due: ("Rent", "Friday"), trend: nil)
        let core = HomeSentence.Clause(app: .money, sentence: sentence, opens: .app(.money), time: noon)
        let mapped = SurfacesWriter.map(core)
        #expect(mapped.app == "money")
        #expect(mapped.text == sentence.text)
        #expect(mapped.at == noon)
        #expect(!SurfacesSnapshot.isWalled(mapped))
        if let from = mapped.keyFrom, let to = mapped.keyTo {
            #expect(SurfaceLine.runs(mapped).first(where: \.isKey)?.text.utf16.count == to - from)
        }
    }

    // MARK: the walls

    @Test func moneyIsDueWordsOnly() {
        #expect(!SurfacesSnapshot.isWalled(clause("money", "Rent is due Friday", key: "Friday")))
        #expect(SurfacesSnapshot.isWalled(clause("money", "Rent of $1,800 is due Friday")))
        #expect(SurfacesSnapshot.isWalled(clause("money", "Rent is due on the 3rd")))
    }

    @Test func bodyHealthAndCaloriesNeverLeave() {
        #expect(SurfacesSnapshot.isWalled(clause("training", "Body weight is down")))
        #expect(SurfacesSnapshot.isWalled(clause("kitchen", "Dinner is 640 kcal")))
        #expect(SurfacesSnapshot.isWalled(clause("notes", "Resting heart rate note")))
        #expect(!SurfacesSnapshot.isWalled(clause("training", "Push A today. Bench opens at 82.5")))
        let kept = SurfacesSnapshot.scrubbed([
            clause("kitchen", "Dinner is 640 kcal"),
            clause("kitchen", "Tacos tonight"),
        ])
        #expect(kept.map(\.text) == ["Tacos tonight"])
    }

    @Test func aPrivateNameIsMasked() {
        #expect(SurfaceMask.shown("Lexapro day", privateLabel: "Private workout") == "Private workout")
        #expect(SurfaceMask.shown("Push A", privateLabel: nil) == "Push A")
        #expect(SurfaceMask.shown("Push A", privateLabel: "") == "Push A")
    }

    // MARK: Live Activities

    @Test func plusWordIsTheCountOfOtherTimers() {
        #expect(CookFace.plusWord(others: 0) == nil)
        #expect(CookFace.plusWord(others: 1) == "+1")
        #expect(CookFace.plusWord(others: 2) == "+2")
    }

    @Test func cookShowsTheSoonestTimerAndCountsTheRest() throws {
        let timers = [
            CookTimerInput(label: "Rice", endsAt: noon.addingTimeInterval(900), startedAt: noon),
            CookTimerInput(label: "Beans", endsAt: noon.addingTimeInterval(300), startedAt: noon),
            CookTimerInput(label: "Salsa", endsAt: noon.addingTimeInterval(600), startedAt: noon),
            CookTimerInput(
                label: "Done",
                endsAt: noon.addingTimeInterval(-10),
                startedAt: noon.addingTimeInterval(-90)
            ),
        ]
        let state = try #require(CookFace.state(timers: timers, nextStep: "Fold in the cheese", isPrivate: false,
                                                appNow: noon, realNow: noon))
        #expect(state.timerLabel == "Beans")
        #expect(state.others == 2)
        #expect(state.plusWord == "+2")
        #expect(state.nextStep == "Fold in the cheese")
        #expect(CookFace.state(timers: [], nextStep: nil, isPrivate: false, appNow: noon, realNow: noon) == nil)
    }

    @Test func aPrivateCookCarriesNoNamesAndNoStep() throws {
        let timers = [CookTimerInput(label: "Lexapro soup", endsAt: noon.addingTimeInterval(60), startedAt: noon)]
        let state = try #require(CookFace.state(timers: timers, nextStep: "Add the secret", isPrivate: true,
                                                appNow: noon, realNow: noon))
        #expect(state.timerLabel == "Timer")
        #expect(state.nextStep == nil)
        #expect(RoutineFace.state(step: "Call the clinic", position: 2, count: 5, startedAt: noon, isPrivate: true)
            .step == "Private step")
    }

    @Test func theCountdownMovesOntoTheRealClock() throws {
        let timers = [CookTimerInput(label: "Rice", endsAt: noon.addingTimeInterval(100), startedAt: noon)]
        let real = noon.addingTimeInterval(5000)
        let state = try #require(CookFace.state(timers: timers, nextStep: nil, isPrivate: false, appNow: noon,
                                                realNow: real))
        #expect(state.endsAt.timeIntervalSince(real) == 100)
    }

    @Test func nextStepIsOneShortLineWithoutEllipsis() {
        #expect(CookFace.shortStep("Fold in the cheese. Then rest it") == "Fold in the cheese")
        let long = "Stir the onions slowly over a low heat until they are soft and golden brown, then add the garlic and the spices"
        let short = CookFace.shortStep(long)
        #expect(short.count <= 80)
        #expect(long.hasPrefix(short))
        #expect(!short.contains("…") && !short.hasSuffix("..."))
    }

    @Test func setMarksFillDoneAndRingTheNext() {
        #expect(SurfaceMarks.marks(done: 1, total: 3) == [.done, .current, .todo])
        #expect(SurfaceMarks.marks(done: 3, total: 3) == [.done, .done, .done])
        #expect(SurfaceMarks.marks(done: 9, total: 3).count == 3)
        #expect(SurfaceMarks.marks(done: 0, total: 40).count == SurfaceMarks.most)
        #expect(SurfaceMarks.marks(done: -1, total: 0).isEmpty)
    }

    @Test func restStateShowsMarksOnlyWhenSet() {
        var state = RestActivityAttributes.ContentState(
            exercise: "Bench", setNumber: 2, weight: 80, reps: 8, restEndsAt: noon, restTotal: 90, phase: .resting
        )
        #expect(!state.showsMarks)
        state.setsDone = 1
        state.setsTotal = 3
        #expect(state.showsMarks)
    }

    // MARK: colours

    @Test func widgetAccentsMatchTheApp() {
        let pairs: [(String, Color)] = [
            ("training", Theme.Colors.Accent.training), ("kitchen", Theme.Colors.Accent.kitchen),
            ("money", Theme.Colors.Accent.money), ("notes", Theme.Colors.Accent.notes),
            ("lists", Theme.Colors.Accent.lists), ("routines", Theme.Colors.Accent.routines),
        ]
        for (app, color) in pairs {
            for dark in [false, true] {
                let traits = UITraitCollection(userInterfaceStyle: dark ? .dark : .light)
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                UIColor(color).resolvedColor(with: traits).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                let hex = UInt32(red * 255 + 0.5) << 16 | UInt32(green * 255 + 0.5) << 8 | UInt32(blue * 255 + 0.5)
                #expect(hex == SurfaceAccent.hex(app: app, dark: dark), "\(app) \(dark ? "dark" : "light")")
            }
        }
    }
}
