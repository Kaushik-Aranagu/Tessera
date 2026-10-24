import CoreGraphics
import Foundation
import Observation
import TesseraCore

/// How the layer should bring a new face in.
enum MosaicFaceTransition: Equatable {
    case none
    /// The finger already slid it in: settle, no changeover.
    case slid
    /// An auto turn: one of the sheet 200 changeovers (`MosaicTurnPolicy.changeovers`).
    case changeover(Int)
    /// A turn from VoiceOver or a jump: the page's wipe in the swipe's direction.
    case wipe(reverse: Bool)
    /// Reduce Motion: the engine's plain crossfade.
    case plain
}

/// The finger's part, read every frame by the layer: how far the faces have slid (in tiles, negative toward the next
/// face), which faces are beside the current one, and the glide that finishes or cancels a swipe. Not observed: a drag
/// moves it sixty times a second and only the layer's canvas reads it.
@MainActor
final class MosaicFaceDrag {
    struct Arts {
        var previous: MosaicFaceArt?
        var current: MosaicFaceArt?
        var next: MosaicFaceArt?
    }

    private(set) var travel: CGFloat = 0
    var arts = Arts()
    /// The window's width in tiles while the faces slide (the current face's).
    var width = 88
    private var glide: (from: CGFloat, to: CGFloat, start: TimeInterval, seconds: TimeInterval)?
    private var holding = false

    /// Whether the drag draws anything over the face now.
    var isActive: Bool {
        travel != 0 || glide != nil || holding
    }

    func follow(tiles: CGFloat) {
        glide = nil
        holding = true
        travel = tiles
    }

    /// Glides from where it is to `target` tiles over `seconds`; `target` 0 is a cancel.
    func glide(to target: CGFloat, seconds: TimeInterval, at uptime: TimeInterval = ProcessInfo.processInfo
        .systemUptime)
    {
        glide = (travel, target, uptime, seconds)
        holding = false
    }

    /// A peek: out `tiles` toward the next face and back over `seconds`.
    func peek(tiles: CGFloat, seconds: TimeInterval, at uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        glide = (0, -tiles, uptime, seconds)
        holding = false
        peeking = true
    }

    private var peeking = false

    /// The slide at `uptime`, advancing a glide.
    func shift(at uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) -> CGFloat {
        guard let glide else { return travel }
        let unit = min(max((uptime - glide.start) / glide.seconds, 0), 1)
        if peeking {
            // Out and back: sin over the whole run.
            let value = glide.to * CGFloat(sin(Double.pi * unit))
            if unit >= 1 {
                self.glide = nil
                peeking = false
                travel = 0
            }
            return value
        }
        let eased = CGFloat(1 - pow(1 - unit, 3))
        let value = glide.from + (glide.to - glide.from) * eased
        if unit >= 1 {
            travel = glide.to
            self.glide = nil
        }
        return value
    }

    /// The glide has run to its end.
    var isGliding: Bool {
        glide != nil
    }

    /// Back to rest, for good.
    func clear() {
        travel = 0
        glide = nil
        holding = false
        peeking = false
    }
}

/// The stack of faces and what turns it. Faces come from the page's inputs; the model keeps which one shows, when the
/// next auto turn is due, how long a touch has paused it, and the gallery's own scene turn.
@MainActor
@Observable
final class MosaicFaceModel {
    struct Environment: Equatable {
        var reduceMotion = false
        var lowPower = false
        var quiet = false
        /// Settings > Home > Mosaic > Turn by itself.
        var turnsByItself = true
        /// A moment, a doorway, a room or the background holds the faces still.
        var paused = false
    }

    private(set) var faces: [MosaicFace] = []
    private(set) var index = 0
    /// Bumps on every change of face: the layer retargets and a haptic plays for a swipe.
    private(set) var turnToken = 0
    private(set) var transition = MosaicFaceTransition.none
    /// +1 when the last turn went to the next face, -1 to the previous: the wipe's direction (`pageDirection`).
    private(set) var direction = 1
    /// Bumps when a swipe commits: the light impact.
    private(set) var impacts = 0

    @ObservationIgnored let drag = MosaicFaceDrag()
    @ObservationIgnored private var inputs = MosaicFaceInputs()
    @ObservationIgnored private var sequence: [MosaicScenery] = []
    @ObservationIgnored private var galleryStep = 0
    @ObservationIgnored private var autoTurns = 0
    @ObservationIgnored private var lastChangeover: Int?
    @ObservationIgnored private var fireAt: Date?
    @ObservationIgnored private var galleryAt: Date?
    @ObservationIgnored private var touchedUntil: Date = .distantPast
    @ObservationIgnored private var generator = SystemRandomNumberGenerator()
    @ObservationIgnored private var glideTask: Task<Void, Never>?
    /// The next face has peeked once this launch.
    @MainActor private static var peeked = false

    var current: MosaicFace? {
        faces.indices.contains(index) ? faces[index] : nil
    }

    var next: MosaicFace? {
        faces.count > 1 ? faces[(index + 1) % faces.count] : nil
    }

    var previous: MosaicFace? {
        faces.count > 1 ? faces[(index - 1 + faces.count) % faces.count] : nil
    }

    // MARK: Inputs

    /// Takes what the page read this minute. A face that was there stays where it is; a live face that has just begun
    /// takes the front (unless he has touched in the last 30 s).
    func update(_ new: MosaicFaceInputs, sequence: [MosaicScenery], on: (MosaicFaceKind) -> Bool,
                now: Date = AppClock.now)
    {
        let before = current
        let wasLive = Set(faces.filter(\.isLive).map(\.kind))
        inputs = new
        self.sequence = sequence
        rebuild(on: on)
        let paused = now < touchedUntil
        if let fresh = faces.firstIndex(where: { $0.isLive && !wasLive.contains($0.kind) }), !paused,
           faces[fresh].kind != before?.kind
        {
            go(to: fresh, forward: true, transition: .wipe(reverse: false))
            return
        }
        // Keep the face he was on, if it is still there.
        if let before, let kept = faces.firstIndex(where: { $0.kind == before.kind }) {
            let changed = faces[kept] != before
            index = kept
            if changed {
                // The same face with new numbers or a new scene retargets quietly.
                bump(.none)
            }
        } else {
            index = min(index, max(faces.count - 1, 0))
            if before != nil {
                bump(.wipe(reverse: false))
            }
        }
    }

    private func rebuild(on: (MosaicFaceKind) -> Bool) {
        var withScene = inputs
        if !sequence.isEmpty {
            withScene.scenery = sequence[galleryStep % sequence.count]
        }
        faces = MosaicFaceStack.faces(withScene, on: on)
        if !faces.isEmpty, current == nil {
            index = 0
        }
    }

    // MARK: Turning

    private func bump(_ next: MosaicFaceTransition) {
        transition = next
        turnToken += 1
    }

    private func go(to target: Int, forward: Bool, transition next: MosaicFaceTransition) {
        guard faces.indices.contains(target) else { return }
        direction = forward ? 1 : -1
        index = target
        if faces[target].kind == .gallery, !sequence.isEmpty {
            // Each turn into the gallery is a new scene.
            galleryStep += 1
            inputs.scenery = sequence[galleryStep % sequence.count]
            faces[target].scenery = inputs.scenery
        }
        bump(next)
    }

    /// A turn from outside the finger (VoiceOver's adjustable action): the page's wipe in the turn's direction.
    func turn(forward: Bool) {
        guard faces.count > 1 else { return }
        touched()
        go(to: (index + (forward ? 1 : faces.count - 1)) % faces.count, forward: forward,
           transition: .wipe(reverse: !forward))
    }

    // MARK: Finger

    /// Any touch on the mosaic pauses the auto turn for 30 s.
    func touched(now: Date = AppClock.now) {
        touchedUntil = now.addingTimeInterval(MosaicTurnPolicy.touchPause)
        fireAt = nil
    }

    /// 1:1 following: `travel` is the finger's horizontal travel in points.
    func dragged(travel points: CGFloat, step: CGFloat = MosaicScreenGrid.step) {
        guard faces.count > 1 else { return }
        glideTask?.cancel()
        drag.width = current?.width ?? 88
        drag.follow(tiles: points / step)
    }

    /// Let go: past 35% of the width or on a flick it commits and finishes the slide, else it slides back.
    func released(travel points: CGFloat, velocity: CGFloat, step: CGFloat = MosaicScreenGrid.step) {
        touched()
        guard faces.count > 1, let width = current?.width else {
            drag.clear()
            return
        }
        let span = CGFloat(width) * step
        guard MosaicTurnPolicy.commits(travel: points, width: span, velocity: velocity) else {
            drag.glide(to: 0, seconds: MosaicTurnPolicy.slideSeconds)
            return
        }
        let forward = points < 0
        impacts += 1
        drag.glide(to: forward ? -CGFloat(width) : CGFloat(width), seconds: MosaicTurnPolicy.slideSeconds)
        glideTask?.cancel()
        glideTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(MosaicTurnPolicy.slideSeconds + 0.02))
            guard !Task.isCancelled, let self else { return }
            let count = faces.count
            go(to: (index + (forward ? 1 : count - 1)) % count, forward: forward, transition: .slid)
        }
    }

    /// The next face leans in once per launch, so he finds the swipe, and goes back.
    func peekOnce() {
        guard !Self.peeked, faces.count > 1 else { return }
        Self.peeked = true
        drag.width = current?.width ?? 88
        drag.peek(tiles: 8, seconds: 1.1)
    }

    // MARK: By itself

    /// Called a few times a second while Home is on screen. Does the auto turn when it is due.
    func tick(now: Date, environment: Environment, line: LineClock = MosaicLineClock.shared) {
        let mode = environment.turnsByItself
            ? MosaicTurnPolicy.mode(reduceMotion: environment.reduceMotion, lowPower: environment.lowPower,
                                    quiet: environment.quiet)
            : .swipeOnly
        // A lone gallery changes its own scene about every 9 s, on the same clock.
        if faces.count == 1, faces.first?.kind == .gallery, !environment.paused, mode != .swipeOnly,
           !sequence.isEmpty
        {
            let due = galleryAt ?? line.clear(now.addingTimeInterval(MosaicTurnPolicy.galleryScene))
            galleryAt = due
            if now >= due, !line.collides(now) {
                galleryAt = nil
                galleryStep += 1
                inputs.scenery = sequence[galleryStep % sequence.count]
                faces[0].scenery = inputs.scenery
                bump(environment.reduceMotion ? .plain : .changeover(pickChangeover()))
            }
            return
        }
        galleryAt = nil
        guard case let .auto(range, animated, _) = mode, !environment.paused, faces.count > 1,
              now >= touchedUntil else
        {
            fireAt = nil
            return
        }
        if fireAt == nil {
            fireAt = MosaicTurnPolicy.fireTime(after: now, interval: MosaicTurnPolicy.seconds(range, using: &generator),
                                               line: line)
        }
        guard let due = fireAt, now >= due else { return }
        // Never in a line flip's second: wait one more.
        if line.collides(now) {
            fireAt = now.addingTimeInterval(1)
            return
        }
        fireAt = nil
        guard let target = MosaicTurnPolicy.next(current: index, faces: faces, turn: autoTurns, mode: mode) else {
            return
        }
        autoTurns += 1
        go(to: target, forward: true, transition: animated ? .changeover(pickChangeover()) : .plain)
    }

    private func pickChangeover() -> Int {
        let pick = MosaicTurnPolicy.changeover(after: lastChangeover, using: &generator)
        lastChangeover = pick
        return pick
    }

    /// The layer has applied a slid face: the finger's slide is done for good.
    func slideApplied() {
        drag.clear()
    }
}

/// The clock for one frame: every tile of a frame shares one reading of the app clock, not one per tile.
final class FaceFrame {
    private var stamp = -1.0
    private var cached = Date()

    func now(at time: TimeInterval) -> Date {
        if time != stamp {
            stamp = time
            cached = AppClock.now
        }
        return cached
    }
}
