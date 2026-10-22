import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Batch 2 (docs/design/motion/tess-rest-end-alert-and-closing-face.md): one local notification for the rest end,
/// fixed words, and the closing face line.
@MainActor
struct RestAlertTests {
    private let now = Date(timeIntervalSince1970: 1_792_000_000)

    @Test func theNotificationFiresAtTheRestEndOnTheRealClock() {
        let end = now.addingTimeInterval(90)
        // App time runs 100 s behind the real clock (-demoTime): the real fire time shifts with it.
        let fire = RestAlertPlan.fireAt(
            restEndsAt: end,
            appNow: now,
            realNow: now.addingTimeInterval(100),
            enabled: true
        )
        #expect(fire == end.addingTimeInterval(100))
    }

    @Test func nothingIsPendingWithoutARestOrWithTheSwitchOff() {
        #expect(RestAlertPlan.fireAt(restEndsAt: nil, appNow: now, realNow: now, enabled: true) == nil)
        #expect(RestAlertPlan
            .fireAt(restEndsAt: now.addingTimeInterval(-5), appNow: now, realNow: now, enabled: true) == nil)
        #expect(RestAlertPlan
            .fireAt(restEndsAt: now.addingTimeInterval(60), appNow: now, realNow: now, enabled: false) == nil)
    }

    @Test func theWordsAreFixedAndNeverNameTheExercise() {
        #expect(RestAlertPlan.title == "Timer" && RestAlertPlan.body == "Rest is up")
    }

    @Test func aRestExtendedByFifteenMovesTheNotificationAndSkipCancelsIt() async {
        let scheduler = RecordingScheduler()
        let alerts = RestAlerts(scheduler: scheduler)
        alerts.sync(fireAt: now.addingTimeInterval(90))
        alerts.sync(fireAt: now.addingTimeInterval(90))
        alerts.sync(fireAt: now.addingTimeInterval(105))
        alerts.sync(fireAt: nil)
        await alerts.settled()
        #expect(scheduler.log == ["schedule 90", "schedule 105", "cancel"], "\(scheduler.log)")
    }

    @Test func theClosingFaceEndsWithASystemDismissalSixtySecondsOut() {
        #expect(RestActivityController.closingDismissal(from: now) == now.addingTimeInterval(60))
    }

    @Test func theClosingFaceReadsTheMaskedTitle() {
        #expect(RestActivityController.closingLine(title: "Push A") == "Push A, ready to finish")
        #expect(RestActivityController.closingLine(title: "Private workout") == "Private workout, ready to finish")
    }

    @Test func theRestTimerSwitchDefaultsOnAndReadsItsKey() throws {
        let suite = try #require(UserDefaults(suiteName: "RestAlertTests"))
        suite.removePersistentDomain(forName: "RestAlertTests")
        #expect(Choice.restTimerIsOn(defaults: suite))
        suite.set("Off", forKey: "review.restTimer")
        #expect(!Choice.restTimerIsOn(defaults: suite))
        suite.removePersistentDomain(forName: "RestAlertTests")
    }
}

@MainActor
private final class RecordingScheduler: RestAlertScheduler {
    var log: [String] = []
    private let base = Date(timeIntervalSince1970: 1_792_000_000)

    func requestPermissionIfNeeded() async {}

    func schedule(at date: Date) async {
        log.append("schedule \(Int(date.timeIntervalSince(base)))")
    }

    func cancel() async {
        log.append("cancel")
    }
}

/// A sample workout never drives the Live Activity or a notification; a real one does.
@MainActor
struct RestActivityGuardTests {
    @Test func aSampleSessionDrivesNothingAndARealOneDoes() throws {
        for isSample in [true, false] {
            let container = TesseraSchema.makeContainer(inMemory: true)
            let model = AppModel(context: container.mainContext, launchDefaults: .testSuite(), isSample: isSample)
            DemoData.prepare(model)
            let workout = try #require(model.tonightWorkout())
            model.startWorkout(workout)
            let session = try #require(model.session)
            #expect(RestActivityController.shouldDrive(session) == !isSample)
            model.endWorkout()
        }
    }
}
