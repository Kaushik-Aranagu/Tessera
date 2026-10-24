import Foundation
@testable import Tessera
import Testing

/// Home 236 v2.4 and v2.5: one effect per weather case, the word's colour follows its cloud, clouds behind the word,
/// the fog's floor, the bolt's period, the wind warning's sway.
struct WeatherWordTests {
    @Test func everyCaseHasItsOneEffect() {
        func plan(_ kind: WeatherKind, night: Bool = false) -> WeatherPlan {
            WeatherPlan.of(kind, night: night)
        }
        // Clear: shine by day only, star glints at night, no clouds.
        #expect(plan(.clear).shine && !plan(.clear).stars && plan(.clear).clouds.isEmpty)
        #expect(plan(.clear, night: true).stars && !plan(.clear, night: true).shine)
        #expect(plan(.mainlyClear).clouds.count == 1 && plan(.mainlyClear).clouds[0].tone == .white)
        let partly = plan(.partlyCloudy).clouds
        #expect(partly.count == 2 && partly.allSatisfy { $0.alpha >= 0.7 && $0.alpha <= 0.78 })
        #expect(plan(.overcast).clouds.count == 3 && plan(.overcast).clouds.allSatisfy { $0.tone == .grey })
        #expect(plan(.fog).mist && plan(.fog).clouds.isEmpty)
        // Rain: a rain cloud and strokes from finer to heavier; heavy slants and splashes.
        let wet = [WeatherKind.drizzle, .rain, .heavyRain].map { plan($0) }
        let noClouds = wet.allSatisfy { $0.clouds.isEmpty }
        #expect(noClouds, "rain has no cloud (v2.8)")
        let counts = wet.map(\.strokes), lengths = wet.map(\.strokeLength)
        #expect(counts[0] < counts[1] && counts[1] < counts[2])
        #expect(lengths[0] < lengths[1] && lengths[1] < lengths[2])
        #expect(wet[2].slant > 0 && wet[2].splashes && !wet[1].splashes)
        // Freezing: the same in ice, plus a glaze line.
        for (freezing, plain) in [(WeatherKind.freezingDrizzle, WeatherKind.drizzle), (.freezingRain, .rain)] {
            #expect(plan(freezing).glaze && plan(freezing).icy && plan(freezing).strokes == plan(plain).strokes)
        }
        #expect(plan(.snow).flakes > 0 && !plan(.snow).snowCap)
        #expect(plan(.heavySnow).flakes > plan(.snow).flakes && plan(.heavySnow).snowCap)
        #expect(plan(.snowGrains).grains > 0 && plan(.snowGrains).flakes == 0)
        #expect(plan(.thunderstorm).bolt && plan(.thunderstorm).clouds.isEmpty)
        #expect(plan(.thunderstormHail).hail && plan(.thunderstormHail).bolt && !plan(.thunderstorm).hail)
    }

    @Test func theWordFollowsItsCloud() {
        #expect(WeatherKind.clear.token(night: true) == .moon && WeatherKind.clear.token(night: false) == .pcloud)
        #expect(WeatherKind.partlyCloudy.token(night: false) == .pcloud)
        #expect(WeatherKind.overcast.token(night: false) == .fog && WeatherKind.fog.token(night: false) == .fog)
        #expect(WeatherKind.heavyRain.token(night: false) == .rain)
        for kind in [WeatherKind.freezingRain, .freezingDrizzle, .snow, .heavySnow, .snowGrains] {
            #expect(kind.token(night: false) == .ice)
        }
        #expect(WeatherKind.thunderstormHail.token(night: false) == .storm)
    }

    @Test func casesAreInferredFromTheNoticesWords() {
        #expect(WeatherKind.infer(from: "Rain from 4 PM") == .rain)
        #expect(WeatherKind.infer(from: "Heavy rain tonight") == .heavyRain)
        #expect(WeatherKind.infer(from: "Thunderstorms with hail") == .thunderstormHail)
        #expect(WeatherKind.infer(from: "Freezing rain at 6") == .freezingRain)
        #expect(WeatherKind.infer(from: "Fog until 9") == .fog)
        #expect(WeatherKind.infer(from: "Sunset at 6:34 pm") == nil)
    }

    @Test func onlyThreeCasesHaveCloudsAndTheirWispsAreTheSpecifiedAlpha() {
        for kind in WeatherKind.allCases {
            let hasClouds = !WeatherPlan.of(kind, night: false).clouds.isEmpty
            #expect(hasClouds == [.mainlyClear, .partlyCloudy, .overcast].contains(kind), "\(kind)")
        }
        #expect(WeatherPlan.of(.mainlyClear, night: false).wisps == 0.30)
        #expect(WeatherPlan.of(.partlyCloudy, night: false).wisps == 0.34)
        #expect(WeatherPlan.of(.overcast, night: false).wisps == 0.40)
        #expect(WeatherPlan.of(.rain, night: false).wisps == 0 && WeatherPlan.of(.fog, night: false).wisps == 0)
    }

    @Test func cloudsAreLevelWithTheWordBehindItNeverWiderThanHalfAndPrecipitationStartsAtTheTop() {
        let placement = WeatherCloudPlacement.standard
        #expect(placement.centre == 0.5 && placement.height == 1.1 && placement.veil == 0.08)
        #expect(WeatherCloudPlacement.widest == 0.5)
        let white = WeatherCloud(tone: .white, across: 0.5, size: 0.5, alpha: 0.8, drift: 1)
        let grey = WeatherCloud(tone: .grey, across: 0.5, size: 0.5, alpha: 0.8, drift: 1)
        #expect(abs(WeatherCloudPlacement.alpha(white) - 0.72) < 1e-9)
        #expect(abs(WeatherCloudPlacement.alpha(grey) - 0.496) < 1e-9)
        #expect(WeatherCloudPlacement.fallStart == 0 && WeatherCloudPlacement.fallEnd > 1)
    }

    @Test func theFogNeverTakesTheWordBelowThirtyPercentAndMovesAcrossTime() {
        var low = 1.0
        var differs = false
        for row in stride(from: 0.0, through: 1.0, by: 0.05) {
            for time in stride(from: 0.0, to: 20.0, by: 0.25) {
                let opacity = WeatherMotion.fogOpacity(row: row, time: time)
                low = min(low, opacity)
                differs = differs || opacity != WeatherMotion.fogOpacity(row: row, time: 0)
                #expect(opacity <= 1)
            }
        }
        #expect(low >= 0.30 - 1e-9 && low < 0.5, "thick mist gets near the floor and never past it")
        #expect(differs)
    }

    @Test func aBoltStrikesEveryFivePointTwoSecondsAndTheWordFlashes() {
        #expect(WeatherPlan.boltPeriod == 5.2)
        #expect(WeatherMotion.boltPhase(at: 0.05) != nil && WeatherMotion.boltPhase(at: 1) == nil)
        #expect(WeatherMotion.boltPhase(at: 5.2 + 0.05) != nil && WeatherMotion.boltPhase(at: 5.2 - 0.05) == nil)
        #expect(WeatherMotion.flash(at: 0) == 1 && WeatherMotion.flash(at: 2) == 0)
    }

    @Test func theWindWarningSwaysAThirtyFivePercentMoreThanTheWindAndOnlyThoseSway() {
        #expect(WeatherOverlay.windWarning.sway == 1.35 * WeatherOverlay.windy.sway)
        #expect(WeatherOverlay.heatWarning.sway == 0 && WeatherOverlay.coldWarning.sway == 0)
        #expect(WeatherOverlay.windWarning.token == .warn && WeatherOverlay.heatWarning.token == .warn)
        #expect(WeatherOverlay.coldWarning.token == .ice && WeatherOverlay.windy.token == nil)
        #expect(abs(WeatherMotion.sway(.windWarning, at: 0.7)) > abs(WeatherMotion.sway(.windy, at: 0.7)))
    }

    @Test func strokesFallDownTheWordAndStayInsideTheirRange() {
        for index in 0 ..< 50 {
            for time in stride(from: 0.0, to: 10.0, by: 0.3) {
                let place = WeatherMotion.fall(index: index, time: time, speed: 1)
                #expect(place >= 0 && place < 1)
            }
        }
    }
}
