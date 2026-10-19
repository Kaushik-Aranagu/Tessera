import Foundation
@testable import Tessera
import Testing

/// K84's ruled cook-mode words and target sizes.
@MainActor
struct CookModeCopyTests {
    @Test func timerLines() {
        #expect(CookModeCopy.timerDone("Simmer") == "Simmer is done.")
        #expect(CookModeCopy.timerDoneLine("Simmer") == "Simmer, done.")
        #expect(CookModeCopy.timerStopped("Simmer") == "Simmer stopped.")
        #expect(CookModeCopy.timerBack("Simmer") == "Simmer, back.")
        #expect(CookModeCopy.timeLeft("Simmer", seconds: 8 * 60) == "Simmer, 8 minutes left.")
    }

    @Test func durationsInWords() {
        #expect(CookModeCopy.duration(60) == "1 minute")
        #expect(CookModeCopy.duration(7 * 60 + 10) == "8 minutes")
        #expect(CookModeCopy.duration(65 * 60) == "1 hour 5 minutes")
        #expect(CookModeCopy.duration(2 * 3600) == "2 hours")
        #expect(CookModeCopy.duration(20) == "under a minute")
    }

    @Test func theBarAndItsHints() {
        #expect(CookModeCopy.next == "Next" && CookModeCopy.nextHint == "Next step")
        #expect(CookModeCopy.done == "Done" && CookModeCopy.finishHint == "Hold to finish")
        #expect(CookModeCopy.finishAction == "Finish")
        #expect(CookModeCopy.step(1, of: 6) == "Step 2 of 6")
    }

    @Test func headingNeverNamesAPrivateRecipe() {
        #expect(CookModeCopy.heading(recipe: "Weeknight dal", lastWeightKg: nil) == "Weeknight dal, cooking")
        #expect(CookModeCopy.heading(recipe: "Wifi code lasagna", lastWeightKg: nil) == "Private recipe, cooking")
    }

    @Test func targets() {
        #expect(CookModeCopy.minTarget(accessibilitySize: false) == 64)
        #expect(CookModeCopy.minTarget(accessibilitySize: true) == 88)
    }

    /// G233: at zero the timer reads its done line; the last minute is "under a minute".
    @Test func aTimerAtZeroIsDone() {
        #expect(CookModeCopy.timeLeft("Simmer", seconds: 0) == "Simmer, done.")
        #expect(CookModeCopy.timeLeft("Simmer", seconds: 40) == "Simmer, under a minute left.")
        #expect(CookModeCopy.timeLeft("Simmer", seconds: 480) == "Simmer, 8 minutes left.")
    }

    /// G234, G226: Home's bar speaks minutes, and steps every 5 s, once a minute when calm.
    @Test func theDrainBarSpeaksMinutes() {
        let now = Date(timeIntervalSince1970: 10000)
        #expect(DrainBar.spoken(end: now.addingTimeInterval(360), now: now) == "6 minutes left")
        #expect(DrainBar.spoken(end: now.addingTimeInterval(30), now: now) == "under a minute left")
        #expect(DrainBar.spoken(end: now, now: now) == "done")
        #expect(DrainBar.step(calm: false) == 5 && DrainBar.step(calm: true) == 60)
    }
}
