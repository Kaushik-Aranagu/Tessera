import SwiftUI
import TesseraCore

/// Tess's living mark: three dabs of wet paint (vermilion, cobalt, cadmium) and three satellites, mixing by
/// multiply on light grounds and screen on dark. How they move says what Tess is doing.
///
/// Each mode is one row of `SoulParameters.table`; a change of mode blends the old row into the new over 0.4 s
/// (`SoulBlend`). One `Canvas` draws the frame and `.drawingGroup()` composites it on the GPU; slow modes (idle,
/// resting) tick at 30 fps, the rest at 60. Reduce Motion: static dabs, the mode shown by size,
/// grade and opacity only.
struct TessSoul: View {
    enum Mode: Equatable {
        /// A calm "needs you": one dab lifts at a time. Drawn small.
        case idle
        /// The bloom.
        case listening
        /// The per-dab pulse, for a thought under a second (a local parse).
        case thinking
        /// Anything he waits on (Claude, Plan my day, a link, a photo): her colour drains and she splits into twelve
        /// faint lights beside her line (§5, `SoulWork`).
        case working
        /// The lights fly home and her colour floods back (820 ms); the router follows it with Done or rest.
        case gathering
        /// One-shot (1.8 s): pour, swell, splash, relax. Plays a success haptic.
        case done
        case needsYou
        /// One dab flies to `target` (offset from the soul's centre, in points), spreads into a wash and fades.
        case handOff(target: CGPoint)
        /// Night and focus: desaturated, smaller, very slow.
        case resting

        var isOneShot: Bool {
            SoulParameters.table(self).isOneShot
        }
    }

    var mode: Mode
    /// Loops one-shot modes (for galleries); in the app they play once.
    var loopsOneShots = false
    /// How much the host scales this view (the chrome draws her at 0.72), so the working constellation keeps the
    /// lab's on-screen sizes.
    var hostScale: CGFloat = 1
    /// Two ink dots (tess-motion.md §1): a setting, off by default.
    var eyes = false
    var gaze: SoulGaze = .ahead
    /// A finger or drag near her, as a direction her eyes follow, and her reaction to touch, a line or a deed.
    var attention: CGPoint?
    var reaction: (kind: SoulLife.Reaction, start: Date)?
    /// Hearing (rev 19 F4): while he holds to talk, his voice's level (0 ... 1), and when the last word was heard.
    /// On-device
    /// speech only; no audio is kept. Off under Reduce Motion and in Low Power.
    var voice: Double = 0
    var heardAt: Date?
    /// Quiet for an hour: her eyes are closed.
    var quiet = false
    /// The one clear accent of the screen she is on (an app room's colour); nil on Home or with several: she keeps
    /// Ember.
    var pageAccents: Set<AppID> = []
    /// Who decides how she looks and changes: the burst's timing and choice and the palette. Rule-based now; Core's
    /// director takes this seat later.
    var director: any SoulDirecting = CoreSoulDirector()
    /// Her mouth (rev 19 F5): nil while she speaks or listens.
    var mouth: (kind: SoulMouth, start: Date)?
    /// When she began waking with him (idea 2, `SoulRouter.wake`).
    var wake: Date?
    /// A stroke's ripple and the blink after it (idea 3, `SoulRouter.stroke` / `strokeBlink`).
    var stroke: Date?
    var strokeBlink: Date?
    /// Sheet 387: when her eyes began their one long smile (`SoulRouter.smileOnce`).
    var smileStart: Date?
    /// Her beat (§6, `SoulRouter.beat`) and the colour she wears for his day (idea 4, `SoulRouter.wear(at:)`).
    var beat: Date?
    var wear: (Date) -> CGFloat = { _ in 0 }
    /// Told her centre on screen (global) when she's drawn at the dock, so a band pan can find her.
    var onDock: ((CGPoint) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.onWorkoutGround) private var onWorkoutGround
    @State private var layers: [SoulLayer] = []
    @State private var glider = SoulPaletteGlider()
    /// The working overlay, from its split to a second after its gather.
    @State private var work: SoulWorkTimes?
    /// Working ticks at 60 fps, then 30 after 20 s (the frame budget).
    @State private var workIsLong = false
    /// Low Power is read when a mode begins and holds until the next one (§13).
    @State private var lowPower = false
    /// The eyes fade out in 120 ms as Done begins and back in 200 ms after it ends, so Done plays as built.
    @State private var eyesShown = true

    var body: some View {
        let slow = SoulParameters.table(mode).isSlow || (work != nil && workIsLong)
        let size = canvasSize
        // By the look, not the colour scheme (themes.md addendum); the workout is always its own dark palette.
        let store = ThemeStore.shared
        let palette = onWorkoutGround
            ? SoulPalette.look(store.workoutLook)
            : SoulPalette.look(colorScheme == .dark ? store.pair.night : store.pair.day)
        LiveClock(minimumInterval: slow ? 1 / 30 : 1 / 60, paused: reduceMotion && work == nil) { context in
            let drawn = frame(at: context.date)
            let cloud = SoulCloud.image(cloudInput(drawn.frame, at: context.date, dark: palette.layered == false))
            Canvas(rendersAsynchronously: true) { context, canvasSize in
                SoulRenderer.draw(drawn.frame, in: &context, size: canvasSize, palette: palette, lights: drawn.lights,
                                  blurScale: 1 / hostScale, cloud: cloud)
            }
            .saturation(drawn.frame.look.saturation)
            .contrast(drawn.frame.look.contrast)
            .brightness(drawn.frame.look.brightness)
            .opacity(drawn.frame.look.opacity)
            // Flattened by Metal: without this the Canvas is rasterised by Core Graphics on the CPU every frame.
            .drawingGroup()
            // Her body follows her life: the float of her breath, a lean after her eyes, a small breath on a touch.
            .offset(bodyMotion(at: context.date).offset)
            .scaleEffect(bodyMotion(at: context.date).scale)
        }
        .frame(width: size.width, height: size.height)
        .overlay {
            if eyes {
                eyesLayer(palette: palette, slow: slow)
            }
        }
        .frame(width: 96, height: 96)
        .liveRegion(LiveFeatures.tessSoul)
        .onGeometryChange(for: CGPoint.self) { proxy in
            let frame = proxy.frame(in: .global)
            return CGPoint(x: frame.midX, y: frame.midY)
        } action: { centre in
            onDock?(centre)
        }
        .onChange(of: mode, initial: true) { old, new in
            let now = Date.now
            layers = SoulBlend.push(new, onto: layers, at: now)
            lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
            // Gone for Done and while she works (§1: the eyes are gone while she is split); back 200 ms after.
            if new == .done || new == .working || new == .gathering {
                withTesseraAnimation(.linear(duration: 0.12), reduceMotion: reduceMotion) { eyesShown = false }
            } else if old == .done || !eyesShown {
                withTesseraAnimation(.linear(duration: 0.2), reduceMotion: reduceMotion) { eyesShown = true }
            }
            if new == .working {
                // A new ask after a gather splits her again; a second ask while she works joins the running one.
                if work == nil || work?.gather != nil {
                    work = SoulWorkTimes(split: now)
                    workIsLong = false
                }
            } else if work != nil, work?.gather == nil {
                // Anything that ends the work (an answer, a failure, his touch) gathers her first.
                work?.gather = now
            }
        }
        .task(id: work) {
            guard let work else { return }
            if let gather = work.gather {
                // A second after the gather everything of the work is home: drop the overlay.
                try? await Task.sleep(for: .seconds(max(0, 1 - Date.now.timeIntervalSince(gather))))
                guard !Task.isCancelled else { return }
                self.work = nil
            } else {
                try? await Task.sleep(for: .seconds(20))
                guard !Task.isCancelled else { return }
                workIsLong = true
            }
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
        .allowsHitTesting(false)
    }

    /// What her body is made of right now: the paints for the look, her spread from the frame, slow under Reduce
    /// Motion (a still body), flat under Reduce Transparency.
    private func cloudInput(_ frame: SoulFrame, at date: Date, dark: Bool) -> SoulCloud.Input {
        let mains = frame.dabs.prefix(3)
        let home = 9.5
        let mean = mains.reduce(0) { $0 + Double(hypot($1.x, $1.y)) } / Double(max(mains.count, 1))
        let time = reduceMotion ? 0 : date.timeIntervalSinceReferenceDate
        var active = director
        if var core = director as? CoreSoulDirector {
            core.reduceMotion = reduceMotion
            core.lowPower = lowPower
            active = core
        }
        let target = active.paints(dark: dark, pageAccents: pageAccents)
        var input = SoulCloud.Input(paints: glider.paints(target: target, at: time, instant: reduceMotion || lowPower),
                                    dark: dark, time: time)
        input.spread = min(max(mean / home - 1, 0), 1)
        input.quiet = mode == .resting || quiet
        input.flat = reduceTransparency
        input.activeBurst = reduceMotion || lowPower ? nil : active.burst(at: time, quiet: input.quiet)
        input.sway = !reduceMotion && !lowPower
        if !reduceMotion, !lowPower {
            input.voice = voice
            // A heard word gathers her for 220 ms.
            if let heardAt {
                let unit = date.timeIntervalSince(heardAt) / 0.22
                input.gather = unit >= 0 && unit <= 1 ? sin(Double.pi * unit) : 0
            }
        }
        let store = ThemeStore.shared
        let look = onWorkoutGround ? store.workoutLook : (colorScheme == .dark ? store.pair.night : store.pair.day)
        // On Black the chroma is held lower so cobalt does not blow out.
        if look.isDark, look.ground == 0x000000 {
            input.chroma = 1.25
        }
        return input
    }

    /// Her float, lean and breath at `date` (none under Reduce Motion, or without her eyes).
    private func bodyMotion(at date: Date) -> (offset: CGSize, scale: CGFloat) {
        guard eyes, !reduceMotion else { return (.zero, 1) }
        let time = date.timeIntervalSinceReferenceDate
        let lean = SoulLife.lean(at: time)
        var scale: CGFloat = 1
        if let reaction, reaction.kind != .did, reaction.kind != .drink {
            scale = SoulLife.breath(reaction.kind, since: time - reaction.start.timeIntervalSinceReferenceDate)
        }
        // While he talks she leans 1.6 pt toward him (his finger, else straight down).
        var toward = CGSize.zero
        if voice > 0, !lowPower {
            let direction = attention ?? CGPoint(x: 0, y: 1)
            let length = max(hypot(direction.x, direction.y), 0.001)
            toward = CGSize(width: direction.x / length * 1.6, height: direction.y / length * 1.6)
        }
        return (
            CGSize(width: lean.width + toward.width, height: lean.height + toward.height + SoulLife.float(at: time)),
            scale
        )
    }

    /// The frame at `date`, and the twelve lights when she works (nil draws the six dabs as built).
    private func frame(at date: Date) -> (frame: SoulFrame, lights: [SoulLight]?) {
        let base = baseFrame(at: date)
        guard let work else { return (base, nil) }
        let sinceSplit = date.timeIntervalSince(work.split)
        let sinceGather = work.gather.map { date.timeIntervalSince($0) }
        if reduceMotion {
            // A 200 ms loosening in place (position only, never faded), and back.
            let into = min(max(sinceSplit / 0.2, 0), 1)
            let back = sinceGather.map { min(max($0 / 0.2, 0), 1) } ?? 0
            return (SoulWork.reduced(base, amount: CGFloat(into * (1 - back))), nil)
        }
        let graded = SoulWork.grade(base, fade: SoulWork.fade(sinceSplit: sinceSplit, sinceGather: sinceGather))
        let lights = SoulWork.lights(base, scale: base.look.scale * hostScale, sinceSplit: sinceSplit,
                                     sinceGather: sinceGather, lowPower: lowPower)
        return (graded, lights)
    }

    /// The mode's frame (blended), with the wake's stretch on it (none under Reduce Motion or Low Power).
    private func baseFrame(at date: Date) -> SoulFrame {
        let base = reduceMotion
            ? SoulFrame.sample(mode, time: 0, elapsed: 0, still: true)
            : SoulBlend.frame(layers, at: date, loops: loopsOneShots)
            ?? SoulFrame.sample(mode, time: date.timeIntervalSinceReferenceDate, elapsed: 0)
        // The day's colour is paint, not motion: it stays under Reduce Motion and Low Power (idea 4).
        let gather = reduceMotion ? 0 : beat.map { SoulBeat.gather(date.timeIntervalSince($0)) } ?? 0
        var frame = SoulBeat.beating(base, gather: gather, wear: wear(date), swells: mode != .resting)
        guard !reduceMotion else { return frame }
        if let wake, !lowPower {
            frame = SoulWake.stretched(frame, amount: SoulWake.stretch(at: date.timeIntervalSince(wake)))
        }
        if let stroke {
            // Low Power keeps the ripple (at idle's 30 fps); Reduce Motion has none.
            let scale = frame.look.scale * hostScale
            frame = SoulRipple.rippled(frame, elapsed: date.timeIntervalSince(stroke), scale: scale)
        }
        return frame
    }

    /// The eyes ride the same frame as the dabs. Their own timeline keeps the blink under Reduce Motion (30 fps),
    /// when the soul's is paused.
    private func eyesLayer(palette _: SoulPalette, slow: Bool) -> some View {
        // The workout corner stands on the workout's look (one base); everywhere else, the paint look.
        let look = onWorkoutGround ? ThemeStore.shared.workoutLook : ThemeStore.shared.paintLook
        // Light looks: ink mixed 14% toward the ground at full opacity (a solid tone, never faded).
        let dark = look.isDark ? Color(hex: look.ground) : Color(hex: SoulPalette.mixed(
            look.ink,
            toward: look.ground,
            by: 0.14
        ))
        return LiveClock(minimumInterval: reduceMotion || slow ? 1 / 30 : 1 / 60) { context in
            let frame = baseFrame(at: context.date)
            // Waking: shut, then open, then one blink (a 200 ms crossfade under Reduce Motion or Low Power).
            // A moment's own blink (the beat's landing, a stroke's leaving), else the wake's lids, else the schedule.
            let lid = beat.flatMap { SoulBlink.once(since: context.date.timeIntervalSince($0)) }
                ?? strokeBlink.flatMap { SoulBlink.once(since: context.date.timeIntervalSince($0)) }
                ?? wake.map { SoulWake.lid(at: context.date.timeIntervalSince($0), quiet: reduceMotion || lowPower) }
            SoulEyes(frame: frame, time: context.date.timeIntervalSinceReferenceDate, gaze: gaze, color: dark,
                     still: reduceMotion, lid: lid, attention: attention,
                     reaction: smileStart.map { (SoulLife.Reaction.drink, $0.timeIntervalSinceReferenceDate) }
                         ?? reaction.map { ($0.kind, $0.start.timeIntervalSinceReferenceDate) },
                     solid: !look.isDark, closed: quiet,
                     mouth: mouth.map { ($0.kind, $0.start.timeIntervalSinceReferenceDate) })
        }
        .opacity(eyesShown ? 1 : 0)
    }

    /// Room for the done ring at 2.6× and, for a hand-off, the flight to the target.
    private var canvasSize: CGSize {
        if case let .handOff(target) = mode {
            let reach = max(abs(target.x), abs(target.y)) * 2 + 200
            return CGSize(width: max(reach, 240), height: max(reach, 240))
        }
        return CGSize(width: 240, height: 240)
    }

    private var accessibilityText: String {
        switch mode {
        case .idle: "Tess"
        case .listening: "Tess is listening"
        case .thinking: "Tess is thinking"
        case .working, .gathering: "Tess is working"
        case .done: "Tess is done"
        case .needsYou: "Tess needs you"
        case .handOff: "Tess made a change"
        case .resting: "Tess is resting"
        }
    }

    /// Phase (0…1) of a looping animation with a CSS-style (negative) delay.
    static func phase(_ time: Double, period: Double, delay: Double = 0) -> Double {
        let value = (time - delay).truncatingRemainder(dividingBy: period) / period
        return value < 0 ? value + 1 : value
    }
}

// MARK: - Paint

/// The soul's colours for a ground. On dark grounds the paint glows (screen) instead of staining (multiply).
struct SoulPalette {
    var blend: GraphicsContext.BlendMode
    /// A soft radial wash per paint (vermilion, cobalt, cadmium): alpha .8 at the centre, .6 at 40%, 0 at the edge.
    var washes: [Gradient]
    var halo: Gradient
    var ring: Gradient
    /// Light looks paint the dabs into one layer in normal blend and composite it once normally, then once as multiply
    /// at 30%: the colours stay colours instead of burning to brown-black where they overlap.
    var layered = false

    /// The look's live, tess and now; halo from live and context, the ring in context at 60%. Multiply on light
    /// looks, screen (and a fuller halo) on dark ones.
    static func look(_ look: Look) -> SoulPalette {
        let glow = look.isDark
        // Only on Porcelain and Celadon's pale grounds a fainter halo leaves the warm mixing he knows from Plein.
        let pale = look.field == .pigmentBloom || look.field == .glaze
        // Plein's paints inside Tess only (the Theme tokens stay as they are).
        let paints: [UInt32] = look.name == "Plein"
            ? [0xD2502F, 0x3561C8, 0xE0A21E]
            : [look.live, look.tess, look.now]
        var palette = SoulPalette(
            blend: glow ? .screen : .multiply,
            washes: paints.map { glow ? wash($0) : wash($0, core: 0.80, mid: 0.52) },
            halo: halo(Color(hex: look.live).opacity(glow ? 0.22 : pale ? 0.08 : 0.16),
                       Color(hex: look.context).opacity(glow ? 0.14 : pale ? 0.05 : 0.10)),
            ring: ring(Color(hex: look.context).opacity(0.6))
        )
        palette.layered = !glow
        return palette
    }

    /// `hex` mixed `amount` of the way toward `other`, as a hex.
    static func mixed(_ hex: UInt32, toward other: UInt32, by amount: Double) -> UInt32 {
        func channel(_ shift: UInt32) -> UInt32 {
            let first = Double((hex >> shift) & 0xFF), second = Double((other >> shift) & 0xFF)
            return UInt32((first + (second - first) * amount).rounded()) << shift
        }
        return channel(16) | channel(8) | channel(0)
    }

    private static func wash(_ hex: UInt32, core: Double = 0.8, mid: Double = 0.6) -> Gradient {
        let color = Color(hex: hex)
        return Gradient(stops: [
            .init(color: color.opacity(core), location: 0),
            .init(color: color.opacity(mid), location: 0.4),
            .init(color: color.opacity(0), location: 1),
        ])
    }

    private static func halo(_ inner: Color, _ outer: Color) -> Gradient {
        Gradient(stops: [
            .init(color: inner, location: 0),
            .init(color: outer, location: 0.55),
            .init(color: outer.opacity(0), location: 1),
        ])
    }

    /// A soft band peaking at 72% of the radius (CSS `.ring`).
    private static func ring(_ color: Color) -> Gradient {
        Gradient(stops: [
            .init(color: color.opacity(0), location: 0.52),
            .init(color: color.opacity(0.5), location: 0.72),
            .init(color: color.opacity(0), location: 1),
        ])
    }
}

/// Draws a `SoulFrame`: halo and ring in normal blend, then the dabs mixing by multiply or screen, each with its
/// own live blur. The group grade (saturation, contrast) is applied by the view around the canvas.
enum SoulRenderer {
    static func draw(_ frame: SoulFrame, in context: inout GraphicsContext, size: CGSize, palette: SoulPalette,
                     lights: [SoulLight]? = nil, blurScale: CGFloat = 1, cloud: CGImage? = nil)
    {
        context.translateBy(x: size.width / 2, y: size.height / 2)
        context.scaleBy(x: frame.look.scale, y: frame.look.scale)

        if frame.halo.opacity > 0.01 {
            var halo = context
            halo.opacity = frame.halo.opacity
            halo.scaleBy(x: frame.halo.scaleX, y: frame.halo.scaleX * 70 / 75)
            halo.fill(Path(ellipseIn: CGRect(x: -75, y: -75, width: 150, height: 150)),
                      with: .radialGradient(palette.halo, center: .zero, startRadius: 0, endRadius: 75))
        }
        if frame.ring.opacity > 0.01 {
            let radius = SoulDab.ringDiameter / 2 * frame.ring.scaleX
            var ring = context
            ring.opacity = frame.ring.opacity
            ring.fill(Path(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)),
                      with: .radialGradient(palette.ring, center: .zero, startRadius: 0, endRadius: radius))
        }

        context.blendMode = palette.blend
        if let lights {
            // Working: the twelve lights instead of the six dabs (the drip and ring never show while she works).
            for light in lights {
                self.light(light, in: &context, palette: palette)
            }
            return
        }
        if let cloud {
            // Her body: one cloud, in its own compositing group (the canvas), normal blend; nothing leaks onto the
            // page.
            let side = 140 * SoulCloud.span
            context.draw(
                Image(decorative: cloud, scale: 1),
                in: CGRect(x: -side / 2, y: -side / 2, width: side, height: side)
            )
            dab(frame.drip, SoulDab.drip, opacity: 1, in: &context, palette: palette, blurScale: blurScale)
            return
        }
        for (index, pose) in frame.dabs.enumerated() {
            let opacity = index < 3 ? 1 : frame.look.satellites
            dab(pose, SoulDab.all[index], opacity: opacity, in: &context, palette: palette, blurScale: blurScale)
        }
        dab(frame.drip, SoulDab.drip, opacity: 1, in: &context, palette: palette, blurScale: blurScale)
    }

    /// `blurScale` makes up for a host that draws her smaller than built (the dock scales her to 0.72 after the
    /// blur is drawn, which would shrink the soft edge with it): the edge is drawn wider by the inverse, so the
    /// edge on the phone is the one in the approved clips. The core's strength is unchanged.
    private static func dab(_ pose: SoulPose, _ dab: SoulDab, opacity: CGFloat, in context: inout GraphicsContext,
                            palette: SoulPalette, blurScale: CGFloat)
    {
        let alpha = pose.opacity * opacity
        guard alpha > 0.01, pose.scaleX > 0.01, pose.scaleY > 0.01 else { return }
        context.drawLayer { layer in
            layer.opacity = alpha
            layer.addFilter(.blur(radius: pose.blur * blurScale))
            layer.translateBy(x: pose.x, y: pose.y)
            layer.scaleBy(x: dab.size.width / 2 * pose.scaleX, y: dab.size.height / 2 * pose.scaleY)
            layer.fill(shapes[dab.paint], with: .radialGradient(
                palette.washes[dab.paint], center: .zero, startRadius: 0, endRadius: 1
            ))
        }
    }

    private static func light(_ light: SoulLight, in context: inout GraphicsContext, palette: SoulPalette) {
        guard light.alpha > 0.01, light.radiusX > 0.2, light.radiusY > 0.2 else { return }
        context.drawLayer { layer in
            layer.opacity = min(light.alpha, 1)
            layer.addFilter(.blur(radius: light.blur))
            layer.translateBy(x: light.x, y: light.y)
            layer.scaleBy(x: light.radiusX, y: light.radiusY)
            layer.fill(shapes[light.paint], with: .radialGradient(
                palette.washes[light.paint], center: .zero, startRadius: 0, endRadius: 1
            ))
        }
    }

    /// Each paint's irregular corners (CSS border-radius, horizontal / vertical, TL TR BR BL), in a 2×2 box.
    static let shapes: [Path] = [
        shape(horizontal: [52, 48, 60, 40], vertical: [55, 45, 55, 45]),
        shape(horizontal: [45, 55, 40, 60], vertical: [50, 60, 40, 50]),
        shape(horizontal: [60, 40, 55, 45], vertical: [45, 55, 45, 55]),
    ]

    static func shape(horizontal: [CGFloat], vertical: [CGFloat]) -> Path {
        // Radii as fractions of the 2-unit box; each corner is a quarter ellipse.
        let radiiX = horizontal.map { $0 / 50 }, radiiY = vertical.map { $0 / 50 }
        let kappa: CGFloat = 0.5523
        var path = Path()
        path.move(to: CGPoint(x: -1 + radiiX[0], y: -1))
        path.addLine(to: CGPoint(x: 1 - radiiX[1], y: -1))
        path.addCurve(to: CGPoint(x: 1, y: -1 + radiiY[1]),
                      control1: CGPoint(x: 1 - radiiX[1] * (1 - kappa), y: -1),
                      control2: CGPoint(x: 1, y: -1 + radiiY[1] * (1 - kappa)))
        path.addLine(to: CGPoint(x: 1, y: 1 - radiiY[2]))
        path.addCurve(to: CGPoint(x: 1 - radiiX[2], y: 1),
                      control1: CGPoint(x: 1, y: 1 - radiiY[2] * (1 - kappa)),
                      control2: CGPoint(x: 1 - radiiX[2] * (1 - kappa), y: 1))
        path.addLine(to: CGPoint(x: -1 + radiiX[3], y: 1))
        path.addCurve(to: CGPoint(x: -1, y: 1 - radiiY[3]),
                      control1: CGPoint(x: -1 + radiiX[3] * (1 - kappa), y: 1),
                      control2: CGPoint(x: -1, y: 1 - radiiY[3] * (1 - kappa)))
        path.addLine(to: CGPoint(x: -1, y: -1 + radiiY[0]))
        path.addCurve(to: CGPoint(x: -1 + radiiX[0], y: -1),
                      control1: CGPoint(x: -1, y: -1 + radiiY[0] * (1 - kappa)),
                      control2: CGPoint(x: -1 + radiiX[0] * (1 - kappa), y: -1))
        path.closeSubpath()
        return path
    }
}

// MARK: - Travel

/// Moves the soul to a point with different easings on x and y, so the path arcs (~0.76 s).
struct SoulTravel: ViewModifier {
    let position: CGPoint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .offset(x: position.x)
            .animation(
                reduceMotion ? .easeOut(duration: 0.2) : .timingCurve(0.55, 0, 0.15, 1, duration: 0.76),
                value: position.x
            )
            .offset(y: position.y)
            .animation(
                reduceMotion ? .easeOut(duration: 0.2) : .timingCurve(0.3, 0, 0.25, 1, duration: 0.76),
                value: position.y
            )
    }
}
