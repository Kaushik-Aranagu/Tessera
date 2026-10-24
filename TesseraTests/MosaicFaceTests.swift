import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Home 236 v2.1: the faces, the stack, how they turn, the swipe's rules, the art, the sign's new build and the edge.
struct MosaicFaceTests {
    private let on: (MosaicFaceKind) -> Bool = { _ in true }

    private let palette = MosaicFacePalette(
        training: (0.1, 0.4, 0.7), kitchen: (0.65, 0.44, 0.12), lists: (0.37, 0.42, 0.12),
        routines: (0.56, 0.29, 0.47), sky: (0.79, 0.47, 0.18), rain: MosaicFacePalette.rainTriple(dark: false)
    )

    private func art(_ face: MosaicFace) -> MosaicFaceArt {
        MosaicFaceArt(face: face, columns: face.width, rows: 28, palette: palette, now: Date(timeIntervalSince1970: 0))
    }

    private var weather: MosaicWeatherReading {
        MosaicWeatherReading(temperature: 72, fahrenheit: true, condition: .clear,
                             next: .init(word: "Rain", hour: 4), week: [72, 74, 70, 68, 75, 77, 71], isSample: true)
    }

    private var workout: MosaicWorkoutReading {
        MosaicWorkoutReading(startedAt: Date(timeIntervalSince1970: 0), restEndsAt: nil, restTotal: 90)
    }

    // MARK: Faces

    @Test func eachFaceGrowsLeftFromTheRightMarginByItsOwnWidth() {
        #expect(MosaicFaceKind.now.width == 88 && MosaicFaceKind.gallery.width == 88)
        #expect(MosaicFaceKind.weather.width == 84 && MosaicFaceKind.workout.width == 72)
        #expect(MosaicFaceKind.widest == 88)
        let grid = MosaicScreenGrid(size: CGSize(width: 402, height: 874), coreTop: 480)
        let right = Set(MosaicFaceKind.allCases.map { grid.core(columns: $0.width, rows: 28).right })
        #expect(right.count == 1, "one right edge for every face")
    }

    @Test func facesComeInTheBoardsOrderAndAFaceWithNothingToShowIsAbsent() {
        let full = MosaicFaceInputs(
            scenery: .beach, announcement: .init(kind: .rain, opens: .today), weather: weather, workout: workout
        )
        #expect(MosaicFaceStack.faces(full, on: on).map(\.kind) == [.now, .gallery, .weather, .workout])
        let quiet = MosaicFaceInputs(scenery: .beach, announcement: nil, weather: weather, workout: nil)
        #expect(MosaicFaceStack.faces(quiet, on: on).map(\.kind) == [.gallery, .weather])
        #expect(MosaicFaceStack.faces(full, on: { $0 != .weather }).map(\.kind) == [.now, .gallery, .workout])
        #expect(MosaicFaceStack.faces(MosaicFaceInputs(), on: on).isEmpty)
    }

    @Test func nowPlaysTheBoardsLineAsADrawing() {
        func kind(_ target: HomeNotice.Target, _ text: String) -> MosaicNowKind? {
            MosaicNowKind.of(target: target, text: text)?.kind
        }
        #expect(kind(.weather, "Rain from 4 PM") == .rain)
        #expect(kind(.weather, "Sunset at 6:34 pm") == .sun)
        #expect(kind(.room(.kitchen), "Rice") == .bag)
        #expect(kind(.room(.training), "Bench") == .barbell)
        #expect(kind(.room(.lists), "Packing") == .suitcase)
        #expect(kind(.room(.money), "Rent") == nil, "money is never drawn")
        #expect(kind(.room(.notes), "A note") == nil)
        #expect(MosaicNowKind.of(target: .room(.kitchen), text: "Rice")?.opens == .groceries)
    }

    @Test func aFacesRoomIsWhereATapGoes() {
        #expect(MosaicFace(kind: .workout, workout: workout).room == .training)
        #expect(MosaicFace(kind: .gallery, scenery: .beach).room == .today)
        #expect(MosaicFace(kind: .now, now: .init(kind: .barbell, opens: .training)).room == .training)
    }

    @Test func theWeatherSampleSaysSoAndHasAWeek() async {
        let reading = await MainActor.run { SampleWeatherSource(fahrenheit: false).reading(now: Date()) }
        #expect(reading?.isSample == true && reading?.week.count == 7)
    }

    // MARK: Turning

    @Test func modesFollowReduceMotionLowPowerAndQuietHours() {
        #expect(MosaicTurnPolicy.mode(reduceMotion: false, lowPower: false, quiet: false)
            == .auto(seconds: 5 ... 10, animated: true, quiet: false))
        #expect(MosaicTurnPolicy.mode(reduceMotion: true, lowPower: false, quiet: false)
            == .auto(seconds: 10 ... 10, animated: false, quiet: false))
        #expect(MosaicTurnPolicy.mode(reduceMotion: false, lowPower: true, quiet: false) == .swipeOnly)
        #expect(MosaicTurnPolicy.mode(reduceMotion: true, lowPower: true, quiet: true) == .swipeOnly)
        #expect(MosaicTurnPolicy.mode(reduceMotion: false, lowPower: false, quiet: true)
            == .auto(seconds: 20 ... 20, animated: true, quiet: true))
        let quiet = MosaicTurnPolicy.mode(reduceMotion: false, lowPower: false, quiet: true)
        #expect(MosaicTurnPolicy.allowed(MosaicFace(kind: .gallery), in: quiet))
        #expect(MosaicTurnPolicy.allowed(MosaicFace(kind: .weather), in: quiet))
        #expect(!MosaicTurnPolicy.allowed(MosaicFace(kind: .workout, workout: workout), in: quiet))
        #expect(!MosaicTurnPolicy.allowed(MosaicFace(kind: .now, now: .init(kind: .bag, opens: .groceries)), in: quiet))
    }

    @Test func theIntervalIsFiveToTenSecondsAndTheTouchPauseIsThirty() {
        var generator = Lcg(seed: 7)
        let draws = (0 ..< 200).map { _ in MosaicTurnPolicy.seconds(MosaicTurnPolicy.normal, using: &generator) }
        #expect(draws.allSatisfy { $0 >= 5 && $0 <= 10 })
        #expect(Set(draws.map { Int($0) }).count >= 5, "it is random inside the range")
        #expect(MosaicTurnPolicy.touchPause == 30)
    }

    @Test func aTurnNeverLandsInTheSameSecondAsALineFlip() {
        let anchor = Date(timeIntervalSince1970: 1_000_000)
        let line = LineClock(anchor: anchor, period: 6)
        #expect(line.collides(anchor.addingTimeInterval(12.4)))
        #expect(!line.collides(anchor.addingTimeInterval(13.4)))
        var generator = Lcg(seed: 11)
        for _ in 0 ..< 500 {
            let start = anchor.addingTimeInterval(Double.random(in: 0 ... 120, using: &generator))
            let interval = MosaicTurnPolicy.seconds(MosaicTurnPolicy.normal, using: &generator)
            let fire = MosaicTurnPolicy.fireTime(after: start, interval: interval, line: line)
            #expect(!line.collides(fire))
            #expect(fire.timeIntervalSince(start) >= interval - 1e-6 && fire.timeIntervalSince(start) < interval + 2)
        }
    }

    @Test func aLiveFaceGetsTwoOfEveryThreeTurns() {
        let faces = [MosaicFace(kind: .now, now: .init(kind: .rain, opens: .today)),
                     MosaicFace(kind: .gallery, scenery: .beach), MosaicFace(kind: .weather, weather: weather),
                     MosaicFace(kind: .workout, workout: workout)]
        let mode = MosaicTurnPolicy.mode(reduceMotion: false, lowPower: false, quiet: false)
        var current = 1
        var live = 0
        for turn in 0 ..< 300 {
            let next = MosaicTurnPolicy.next(current: current, faces: faces, turn: turn, mode: mode)
            #expect(next != nil && next != current)
            if let next {
                if faces[next].isLive {
                    live += 1
                }
                current = next
            }
        }
        #expect(live == 200)
        #expect(MosaicTurnPolicy.next(current: 0, faces: [faces[0]], turn: 0, mode: mode) == nil)
        // With no live face every turn is a still one.
        let still = [faces[1], faces[2]]
        #expect(MosaicTurnPolicy.next(current: 0, faces: still, turn: 0, mode: mode) == 1)
    }

    @Test func twoHundredChangeoversNeverRepeat() {
        var generator = Lcg(seed: 3)
        var previous: Int?
        var seen: Set<Int> = []
        for _ in 0 ..< 200 {
            let pick = MosaicTurnPolicy.changeover(after: previous, using: &generator)
            #expect(pick != previous && MosaicTurnPolicy.changeovers.indices.contains(pick))
            seen.insert(pick)
            previous = pick
        }
        #expect(seen.count == MosaicTurnPolicy.changeovers.count)
        #expect(MosaicTurnPolicy.changeovers.contains(.flip))
    }

    // MARK: Swipe

    @Test func aSwipeCommitsPastThirtyFivePercentOrOnAFlickAndNeverSooner() {
        let width: CGFloat = 345
        #expect(!MosaicTurnPolicy.commits(travel: -0.34 * width, width: width, velocity: -100))
        #expect(MosaicTurnPolicy.commits(travel: -0.36 * width, width: width, velocity: -100))
        #expect(MosaicTurnPolicy.commits(travel: -60, width: width, velocity: -900), "a flick commits")
        #expect(!MosaicTurnPolicy.commits(travel: -0.5 * width, width: width, velocity: 600), "going back does not")
        #expect(MosaicTurnPolicy.commits(travel: 0.4 * width, width: width, velocity: 50), "to the right too")
    }

    @MainActor @Test func theFaceFollowsTheFinger1To1AndComesHomeOnACancel() {
        let model = MosaicFaceModel()
        model.update(MosaicFaceInputs(scenery: .beach, weather: weather), sequence: [.beach], on: on)
        #expect(model.faces.count == 2)
        model.dragged(travel: -40)
        #expect(model.drag.shift() == -10, "40 pt is ten tiles of 4 pt")
        model.dragged(travel: -80)
        #expect(model.drag.shift() == -20)
        model.released(travel: -80, velocity: -50)
        #expect(model.drag.isGliding)
        #expect(model.index == 0, "a short pull does not turn it")
        #expect(model.impacts == 0, "no impact for a cancel")
    }

    @MainActor @Test func aCommittedSwipeTurnsTheFaceAndPlaysOneLightImpact() async throws {
        let model = MosaicFaceModel()
        model.update(MosaicFaceInputs(scenery: .beach, weather: weather), sequence: [.beach], on: on)
        let before = model.turnToken
        model.dragged(travel: -200)
        model.released(travel: -200, velocity: -300)
        #expect(model.impacts == 1)
        try await Task.sleep(for: .milliseconds(450))
        #expect(model.current?.kind == .weather)
        #expect(model.transition == .slid && model.turnToken == before + 1)
        #expect(model.direction == 1)
    }

    @MainActor @Test func aSingleFaceCannotBeSwiped() {
        let model = MosaicFaceModel()
        model.update(MosaicFaceInputs(scenery: .beach), sequence: [.beach], on: on)
        model.dragged(travel: -200)
        model.released(travel: -200, velocity: -900)
        #expect(model.impacts == 0 && !model.drag.isActive)
    }

    @MainActor @Test func aTouchPausesTheAutoTurnForThirtySeconds() {
        let model = MosaicFaceModel()
        model.update(MosaicFaceInputs(scenery: .beach, weather: weather), sequence: [.beach], on: on)
        let start = Date(timeIntervalSince1970: 5_000_000)
        let calm = MosaicFaceModel.Environment()
        let line = LineClock(anchor: nil, period: 6)
        model.touched(now: start)
        for second in stride(from: 0.0, to: 29.9, by: 0.5) {
            model.tick(now: start.addingTimeInterval(second), environment: calm, line: line)
        }
        #expect(model.current?.kind == .gallery, "nothing turned inside the pause")
        var turned = false
        for second in stride(from: 30.0, to: 50.0, by: 0.5) {
            model.tick(now: start.addingTimeInterval(second), environment: calm, line: line)
            turned = turned || model.current?.kind == .weather
        }
        #expect(turned, "it turns by itself once the pause is over")
    }

    @MainActor @Test func swipeOnlyAndPausedStacksNeverTurnByThemselves() {
        for environment in [MosaicFaceModel.Environment(lowPower: true),
                            MosaicFaceModel.Environment(turnsByItself: false),
                            MosaicFaceModel.Environment(paused: true)]
        {
            let model = MosaicFaceModel()
            model.update(MosaicFaceInputs(scenery: .beach, weather: weather), sequence: [.beach], on: on)
            let start = Date(timeIntervalSince1970: 7_000_000)
            for second in stride(from: 0.0, to: 60.0, by: 0.5) {
                model.tick(now: start.addingTimeInterval(second), environment: environment,
                           line: LineClock(anchor: nil, period: 6))
            }
            #expect(model.current?.kind == .gallery)
        }
    }

    @MainActor @Test func aLiveFaceThatBeginsTakesTheFrontUnlessHeIsTouching() {
        let model = MosaicFaceModel()
        let start = Date(timeIntervalSince1970: 9_000_000)
        model.update(MosaicFaceInputs(scenery: .beach, weather: weather), sequence: [.beach], on: on, now: start)
        model.update(MosaicFaceInputs(scenery: .beach, weather: weather, workout: workout), sequence: [.beach],
                     on: on, now: start)
        #expect(model.current?.kind == .workout)
        let other = MosaicFaceModel()
        other.update(MosaicFaceInputs(scenery: .beach, weather: weather), sequence: [.beach], on: on, now: start)
        other.touched(now: start)
        other.update(MosaicFaceInputs(scenery: .beach, weather: weather, workout: workout), sequence: [.beach],
                     on: on, now: start.addingTimeInterval(5))
        #expect(other.current?.kind == .gallery)
    }

    @MainActor @Test func aLoneGalleryChangesSceneAboutEveryNineSeconds() {
        let model = MosaicFaceModel()
        model.update(MosaicFaceInputs(scenery: .beach), sequence: [.beach, .woods, .desert], on: on)
        let start = Date(timeIntervalSince1970: 3_000_000)
        let line = LineClock(anchor: nil, period: 6)
        var scenes: [MosaicScenery?] = []
        for second in stride(from: 0.0, to: 40.0, by: 0.5) {
            model.tick(now: start.addingTimeInterval(second), environment: .init(), line: line)
            if scenes.last != model.current?.scenery {
                scenes.append(model.current?.scenery)
            }
        }
        #expect(scenes.count >= 4, "four changes in forty seconds")
        #expect(MosaicTurnPolicy.galleryScene == 9)
    }

    // MARK: Art

    @Test func everyFacesInkFitsItsWindowWithNothingClipped() {
        let faces = [
            MosaicFace(kind: .weather, weather: weather),
            MosaicFace(kind: .workout, workout: workout),
            MosaicFace(kind: .workout, workout: MosaicWorkoutReading(
                startedAt: Date(timeIntervalSince1970: 0), restEndsAt: Date(timeIntervalSince1970: 74), restTotal: 90
            )),
        ]
        for face in faces {
            let art = art(face)
            let now = Date(timeIntervalSince1970: 0)
            let tiles = art.inkTiles(now: now)
            #expect(!tiles.isEmpty)
            #expect(tiles.allSatisfy { (0 ..< art.columns).contains($0.column) && (0 ..< art.rows).contains($0.row) })
            #expect(art.layout(now: now).ink.count == Set(tiles.map { $0.column * 1000 + $0.row }).count)
        }
    }

    @Test func theWeatherDrawsItsTemperatureInTheTwoXNumeralsAndTheWeekInBars() {
        let face = MosaicFace(kind: .weather, weather: weather)
        let tiles = Set(art(face).inkTiles(now: Date()).map { $0.column * 1000 + $0.row })
        // A 7 at 2x: its top bar is six tiles wide and two tall on rows 4 and 5.
        #expect(MosaicPixelFont.tiles("7", left: 5, top: 4, scale: 2).count == 6 * 2 + 4 * 2 * 2 + 0)
        #expect((5 ... 10).allSatisfy { tiles.contains($0 * 1000 + 4) })
        // Seven bars of three tiles on an 84 wide face, none on a narrow one.
        let narrow = MosaicFaceArt(face: face, columns: 60, rows: 28, palette: palette, now: Date())
        #expect(art(face).inkTiles(now: Date()).count > narrow.inkTiles(now: Date()).count + 7 * 3 * 3)
    }

    @Test func theRestTimerCountsDownInNumeralsAndTheBarDrains() {
        let end = Date(timeIntervalSince1970: 100)
        let reading = MosaicWorkoutReading(startedAt: Date(timeIntervalSince1970: 0), restEndsAt: end, restTotal: 100)
        let art = art(MosaicFace(kind: .workout, workout: reading))
        let early = art.inkTiles(now: Date(timeIntervalSince1970: 10)).count
        let late = art.inkTiles(now: Date(timeIntervalSince1970: 90)).count
        #expect(early > late, "the bar is shorter as the rest runs out")
        #expect(reading.restLeft(at: Date(timeIntervalSince1970: 70)) == 30)
        #expect(reading.restLeft(at: Date(timeIntervalSince1970: 101)) == nil)
    }

    @Test func theWorkoutCarriesNoSetWeightBodyOrHealthNumber() {
        let mirror = Mirror(reflecting: workout)
        #expect(Set(mirror.children.compactMap(\.label)) == ["startedAt", "restEndsAt", "restTotal"])
    }

    @Test func pixelLettersFitWithoutDotsAndAreWholeTiles() {
        let fitted = MosaicPixelFont.fitted("Sourdough starter and flour", columns: 40, scale: 1)
        #expect(MosaicPixelFont.width(of: fitted, scale: 1) <= 40 && !fitted.contains("."))
        #expect(MosaicPixelFont.width(of: "72", scale: 2) == 6 + 6 + 2)
        #expect(MosaicPixelFont.glyphs.count >= 10 + 26)
        for (character, rows) in MosaicPixelFont.glyphs {
            #expect(rows.count == 5 && rows.allSatisfy { $0.count == 3 }, "\(character)")
        }
    }

    @Test func nowDrawsAMovingPictureForEachAnnouncement() {
        let kinds: [MosaicNowKind] = [.rain, .sun, .bag, .barbell, .suitcase, .clock]
        for kind in kinds {
            let face = MosaicFace(kind: .now, now: .init(kind: kind, opens: .today))
            let art = art(face)
            func picture(_ time: Double) -> [Double] {
                (0 ..< 88).flatMap { column in
                    (0 ..< 28).map { row in
                        let colour = art.colour(column: column, row: row, animation: time, now: Date())
                        return colour.red + colour.green * 3 + colour.blue * 7
                    }
                }
            }
            #expect(picture(0) != picture(0.7), "\(kind) moves")
            #expect(picture(0) == picture(0), "\(kind) is deterministic")
        }
    }

    @Test func rainWearsTheRainTokenAndNoFaceTileSitsNearEmber() {
        #expect(MosaicFacePalette.rainTriple(dark: false) == MosaicColour.hex(0x557A93))
        #expect(MosaicFacePalette.rainTriple(dark: true) == MosaicColour.hex(0x9DBACE))
        let faces = [MosaicFace(kind: .now, now: .init(kind: .rain, opens: .today)),
                     MosaicFace(kind: .weather, weather: weather), MosaicFace(kind: .workout, workout: workout)]
        for face in faces {
            let art = art(face)
            for column in stride(from: 0, to: art.columns, by: 3) {
                for row in 0 ..< 28 {
                    let colour = MosaicSceneArt.safe(art.colour(column: column, row: row, animation: 0.3,
                                                                now: Date(timeIntervalSince1970: 0)))
                    #expect(colour.red.isFinite && colour.green.isFinite && colour.blue.isFinite)
                }
            }
        }
    }

    @Test func theGalleryRunStartsWithThePickAndAPinnedSceneIsAlone() {
        let run = MosaicGallery.sequence(backdrop: .tessPicks, pick: .harbor, phase: .day)
        #expect(run.first == .harbor && Set(run).count == run.count && run.count > 3)
        #expect(!run.contains(.nightSky), "no night sky at noon")
        #expect(MosaicGallery.sequence(backdrop: .pinned(.snow), pick: .snow, phase: .day) == [.snow])
        #expect(MosaicGallery.sequence(backdrop: .stripes, pick: nil, phase: .day).isEmpty)
    }

    // MARK: Settings

    @MainActor @Test func everyFaceHasASwitchAndTheTurnSwitchIsAmongThem() {
        for kind in MosaicFaceKind.allCases {
            let choice = ReviewChoices.all.first { $0.id == kind.switchID }
            #expect(choice?.defaultValue == "On" && choice?.readiness == .live, "\(kind)")
        }
        #expect(ReviewChoices.all.first { $0.id == HomeMosaic.faceTurnID }?.name == "Turn by itself")
    }

    // MARK: Sign

    @Test func theSignIsTwentyByTwentyAndBuildsFromTheBottomRowUpSixMillisecondsApart() {
        #expect(ThingSignArt.side == 20 && HomeOneThing.signRoom == 92)
        let cells = ThingSignArt.cells(.training, elapsed: 0)
        let tiles = MosaicSignLend.lend(cells: cells, originColumn: 70, originRow: 4,
                                        core: (left: 0, top: 0, width: 88, height: 28))
        let rows = tiles.map(\.cell.row)
        #expect(rows == rows.sorted(by: >), "the first tile to launch is on the bottom row")
        let lend = MosaicSignLend(tiles: tiles, start: 10, kind: .training, share: 0.5)
        #expect(abs(lend.launch(1) - lend.launch(0) - 0.006) < 1e-9)
        #expect(MosaicSignLend.flightSeconds == 0.42)
    }

    @Test func edgeTilesKeepAThirdOfTheirSourceColour() {
        let cells = ThingSignArt.cells(.list, elapsed: 0, share: 1)
        let keys = MosaicSignLend.keys(cells)
        let edges = cells.filter { MosaicSignLend.isEdge($0, in: keys) }
        #expect(!edges.isEmpty && edges.count < cells.count)
        #expect(MosaicSignLend.edgeKeep == 0.33)
        // A tile in the middle of the case is not an edge.
        #expect(!MosaicSignLend.isEdge(ThingSignCell(9, 12), in: keys))
        #expect(MosaicSignLend.isEdge(ThingSignCell(3, 12), in: keys))
    }

    @Test func everyNewSignIsDrawnForReal() {
        for kind in ThingSignKind.allCases {
            let cells = ThingSignArt.cells(kind, elapsed: 0.3)
            #expect(cells.count > 20 && cells.count < 330, "\(kind)")
        }
    }

    @MainActor @Test func aBuiltSignTradesATileWithTheMosaicEveryFourToSevenSeconds() {
        let size = CGSize(width: 402, height: 874)
        let engine = MosaicScreenEngine(size: size, coreTop: 480)
        engine.configure(size: size, coreTop: 480, dark: false, ground: (1, 1, 1))
        engine.setWindow(columns: 88, rows: 28)
        engine.snapWindow()
        engine.showSign(MosaicSignRequest(kind: .training, column: 70, row: 100, accent: (0.75, 0.27, 0.17)))
        engine.step(to: 0.05)
        var starts: [TimeInterval] = []
        var clock = 0.05
        while clock < 90 {
            clock += 0.05
            engine.step(to: clock)
            if let trade = engine.signTrade, starts.last != trade.start {
                starts.append(trade.start)
            }
        }
        #expect(starts.count >= 10, "a trade every few seconds")
        let gaps = zip(starts, starts.dropFirst()).map { $1 - $0 }
        #expect(gaps.allSatisfy { $0 >= 4 && $0 <= 7.5 }, "\(gaps)")
    }

    @MainActor @Test func underReduceMotionTheSignNeverTrades() {
        let size = CGSize(width: 402, height: 874)
        let engine = MosaicScreenEngine(size: size, coreTop: 480)
        engine.reduceMotion = true
        engine.configure(size: size, coreTop: 480, dark: false, ground: (1, 1, 1))
        engine.snapWindow()
        engine.showSign(MosaicSignRequest(kind: .groceries, column: 70, row: 100, accent: (0.75, 0.27, 0.17)))
        for step in 1 ... 400 {
            engine.step(to: Double(step) * 0.1)
            #expect(engine.signTrade == nil)
        }
    }

    // MARK: Edge

    @MainActor @Test func theEdgeIsTheDepartureMosaicBlendInWholeDitheredTiles() {
        let size = CGSize(width: 402, height: 874)
        let engine = MosaicScreenEngine(size: size, coreTop: 480)
        let ground: MosaicTriple = (0.05, 0.05, 0.06)
        engine.configure(size: size, coreTop: 480, dark: true, ground: ground)
        engine.setWindow(columns: 88, rows: 28)
        engine.snapWindow()
        let scene: MosaicTriple = (0.9, 0.5, 0.2)
        engine.settle { _, _ in scene }
        engine.step(to: 0.01)
        engine.reduceMotion = true
        let core = engine.liveCore
        let row = core.top + 14
        // Walking out from the window's left edge the colour climbs from the scene's toward the page's in whole tiles:
        // never an alpha ramp, always a solid colour between the two, and nothing is drawn 16 tiles out.
        var levels: [Double] = []
        for step in 0 ..< MosaicRim.reach {
            let tile = engine.tile(column: core.left - 1 - step, row: row, nowColumn: nil)
            if let colour = tile?.colour {
                let share = (ground.red - colour.red) / (ground.red - scene.red)
                levels.append(share)
                #expect(share >= -0.001 && share <= 1.001)
                #expect(tile?.scale == 1, "full-size tiles")
            }
        }
        #expect(levels.count >= 8)
        #expect(levels.first ?? 0 > levels.last ?? 1, "it climbs out of the page")
        #expect(engine.tile(column: core.left - 1 - MosaicRim.reach, row: row, nowColumn: nil) == nil)
        // The ramp is 24 steps, Bayer dithered over 4 x 4.
        #expect(MosaicRim.steps == 24 && MosaicRim.bayer.count == 4 && MosaicRim.reach == 16)
    }
}

/// A small seeded generator, so the random rules test the same way every run.
struct Lcg: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        state = seed &* 0x9E37_79B9_7F4A_7C15 | 1
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        var value = state
        value ^= value >> 33
        value = value &* 0xFF51_AFD7_ED55_8CCD
        value ^= value >> 33
        return value
    }
}

struct MosaicGradeTests {
    private func mean(_ colour: MosaicTriple) -> Double {
        (colour.red + colour.green + colour.blue) / 3
    }

    @Test func onALightPageEachTileGetsSaturationOneFiftyFiveThenBrightnessAndALift() {
        let scene: MosaicTriple = (0.5, 0.4, 0.3)
        let graded = MosaicColour.graded(scene)
        // Saturation around the mean: the spread from the mean grows 1.55x before brightness and lift (both affine).
        func expected(_ value: Double) -> Double {
            let saturated = 0.4 + (value - 0.4) * 1.55
            let bright = saturated * 1.08
            return bright + (1 - bright) * 0.05
        }
        #expect(abs(graded.red - expected(0.5)) < 1e-9 && abs(graded.blue - expected(0.3)) < 1e-9)
        #expect(graded.red - graded.blue > (scene.red - scene.blue) * 1.55)
        let light: MosaicTriple = (0.98, 0.98, 0.97)
        #expect(MosaicColour.lightGrade(scene, ground: light) == graded)
        // A grey stays grey, and nothing leaves the unit range.
        let grey = MosaicColour.graded((0.5, 0.5, 0.5))
        #expect(abs(grey.red - grey.blue) < 1e-9)
        let loud = MosaicColour.graded((1, 0, 0))
        #expect((0 ... 1).contains(loud.red) && (0 ... 1).contains(loud.green))
    }

    @Test func aDarkPageIsNotGraded() {
        let scene: MosaicTriple = (0.5, 0.4, 0.3)
        #expect(MosaicColour.lightGrade(scene, ground: (0.05, 0.05, 0.06)) == scene)
    }

    @Test func lightTilesGrowToThreePointSixAndDarkOnesStayAtThreePointTwo() {
        let grid = MosaicScreenGrid(size: CGSize(width: 402, height: 874), coreTop: 480)
        #expect(abs(grid.rect(column: 3, row: 5, side: MosaicScreenGrid.lightSide).width - 3.6) < 1e-9)
        #expect(abs(grid.rect(column: 3, row: 5, side: MosaicScreenGrid.lightSide).minX - (3 * 4 + 0.2)) < 1e-9)
        #expect(abs(grid.rect(column: 3, row: 5).width - 3.2) < 1e-9)
    }

    @MainActor @Test func theEngineSizesTilesByThePage() {
        let size = CGSize(width: 402, height: 874)
        func side(dark: Bool) -> CGFloat {
            let engine = MosaicScreenEngine(size: size, coreTop: 480)
            engine.configure(
                size: size,
                coreTop: 480,
                dark: dark,
                ground: dark ? (0.05, 0.05, 0.06) : (0.98, 0.98, 0.97)
            )
            return engine.tileSide
        }
        #expect(side(dark: false) == 3.6 && side(dark: true) == 3.2)
    }
}
