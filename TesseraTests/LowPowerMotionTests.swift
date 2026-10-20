import SwiftUI
@testable import Tessera
import Testing

/// Low Power behaves like Reduce Motion for decorative motion (rulings G317/G318): one flag, one 150 ms crossfade.
@MainActor
struct LowPowerMotionTests {
    @Test func reduceMotionFlagIncludesLowPower() {
        #expect(!MotionPolicy.isReduced(reduceMotion: false, lowPower: false))
        #expect(MotionPolicy.isReduced(reduceMotion: true, lowPower: false))
        #expect(MotionPolicy.isReduced(reduceMotion: false, lowPower: true))
        #expect(MotionPolicy.isReduced(reduceMotion: true, lowPower: true))
    }

    @Test func lowPowerResolvesToTheCrossfade() {
        let spring = Animation.spring(response: 0.5, dampingFraction: 0.6)
        #expect(MotionPolicy.resolve(spring, reduceMotion: false, lowPower: true) == MotionPolicy.reducedMotionFade)
        #expect(MotionPolicy.resolve(spring, reduceMotion: true) == MotionPolicy.reducedMotionFade)
        #expect(MotionPolicy.resolve(spring, reduceMotion: false) == spring)
    }

    @Test func theGhostKeepsItsThreeSecondsInLowPowerAndVoiceOverNeverShortens() {
        #expect(BottomChromeDry.seconds(reduceMotion: false, voiceOver: false) == 3)
        #expect(BottomChromeDry.seconds(reduceMotion: true, voiceOver: false) == 0.8)
        #expect(BottomChromeDry.seconds(reduceMotion: true, voiceOver: true) == 10)
        #expect(BottomChromeDry.lowPowerSteps == 4)
    }
}
