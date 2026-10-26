// swiftlint:disable identifier_name
import SwiftUI

/// Settings > Layout mode (Design 283 v8): a read-only debug surface that draws every landing screen as panes of raised
/// glass, one per place, at their exact frames, so the shared layout can be judged. Across (swipe or arrow) walks the
/// seven rooms, depth (up or down) merges the panes into the door page and back, a tap opens a pane's card.
struct LayoutModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var room = LayoutRoom.bridge
    @State private var level = LayoutLevel.landing
    @State private var places = LayoutPlaces.places(.bridge, .landing)
    @State private var leaving: [LayoutPlace] = []
    @State private var leavingFade = 1.0
    @State private var hidden: Set<String> = []
    @State private var selection: String?
    @State private var busy = false
    @State private var direction = 1.0
    @State private var flipTokens: [String: Int] = [:]
    @State private var sheenToken = 0
    @State private var liquid: LayoutChange?
    @State private var clock = 0.0
    @State private var liquidOpacity = 0.0
    @State private var entered = false
    @FocusState private var focused: Bool

    private var look: LayoutGlassLook {
        LayoutGlassLook(isDark: ThemeStore.shared.paintLook.isDark)
    }

    private var tint: Color {
        guard let hex = room.hex else { return Theme.Colors.ink }
        return Color(light: hex.light, dark: hex.dark)
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / LayoutPlaces.phone.width, proxy.size.height / LayoutPlaces.phone.height)
            ZStack {
                Theme.Colors.paper
                canvas
                    .frame(width: LayoutPlaces.phone.width, height: LayoutPlaces.phone.height)
                    .scaleEffect(scale)
                    .frame(width: LayoutPlaces.phone.width * scale, height: LayoutPlaces.phone.height * scale)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        // The canvas keeps the top safe area: Settings may be shown in Home's cover, whose "Close" word sits in an
        // inset row there, and the canvas (scaled to what is left, frames unchanged) starts below it.
        .ignoresSafeArea(edges: [.bottom, .horizontal])
        .background { Theme.Colors.paper.ignoresSafeArea() }
        .background { EdgeSwipeBack() }
        .navigationBarBackButtonHidden()
        .toolbarVisibility(.hidden, for: .navigationBar)
        .statusBarHidden()
        // Swipe down is the depth gesture here; it must not close the cover Settings may be shown in.
        .interactiveDismissDisabled()
        .simultaneousGesture(swipe)
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onKeyPress(.rightArrow) { move(1); return .handled }
        .onKeyPress(.leftArrow) { move(-1); return .handled }
        .onKeyPress(.upArrow) { go(.door); return .handled }
        .onKeyPress(.downArrow) { go(.landing); return .handled }
        .accessibilityAction(named: "Next room") { move(1) }
        .accessibilityAction(named: "Previous room") { move(-1) }
        .accessibilityAction(named: "Door page") { go(.door) }
        .accessibilityAction(named: "Back up") { go(.landing) }
        .task {
            focused = true
            withTesseraAnimation(.smooth(duration: 0.46), reduceMotion: reduceMotion) { entered = true }
        }
    }

    // MARK: The stage

    private var canvas: some View {
        ZStack(alignment: .topLeading) {
            glows
            guides
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { pick(nil) }
                .accessibilityHidden(true)
            ForEach(Array(places.enumerated()), id: \.element.key) { index, place in
                pane(place, index: index)
            }
            ForEach(leaving) { place in
                LayoutGlassPane(place: place, tint: tint, look: look, isEmpty: false, isSelected: false,
                                roomName: room.name, positionLine: "", flipToken: 0, direction: direction,
                                sheenToken: 0, hidden: false)
                    .opacity(leavingFade)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            if let liquid {
                LiquidLayer(clock: clock, change: liquid, tint: tint)
                    .opacity(liquidOpacity * 0.16)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            card
        }
        .frame(width: LayoutPlaces.phone.width, height: LayoutPlaces.phone.height, alignment: .topLeading)
        .opacity(entered ? 1 : 0)
    }

    private func pane(_ place: LayoutPlace, index _: Int) -> some View {
        let empty = level == .landing && room.emptyPlaces.contains(place.name)
        let view = LayoutGlassPane(place: place, tint: tint, look: look, isEmpty: empty,
                                   isSelected: selection == place.key, roomName: room.name,
                                   positionLine: room.position(level), flipToken: flipTokens[place.key] ?? 0,
                                   direction: direction, sheenToken: sheenToken, hidden: hidden.contains(place.key))
        return Group {
            if place.isGap || place.isPlate {
                view.allowsHitTesting(false)
            } else {
                view
                    .overlay {
                        Button { tap(place) } label: { Color.clear.contentShape(Rectangle()) }
                            .buttonStyle(.plain)
                            .frame(width: place.paneFrame.width, height: place.paneFrame.height)
                            .position(x: place.paneFrame.midX, y: place.paneFrame.midY)
                            .accessibilityLabel(accessibilityLabel(place, empty: empty))
                            .accessibilityHint("Shows its card")
                            .accessibilityIdentifier("layout.pane.\(place.slug)")
                            .accessibilityAddTraits(selection == place.key ? .isSelected : [])
                    }
            }
        }
    }

    private func accessibilityLabel(_ place: LayoutPlace, empty: Bool) -> String {
        if place.name == "Title" {
            return "Title, \(room.name), \(room.position(level))"
        }
        return place.name + (empty ? ", empty" : "")
    }

    // MARK: Backdrop

    /// Three soft room-tinted glows so the glass has light to bend.
    private var glows: some View {
        ZStack {
            glow(x: 0.18, y: 0.22, w: 0.60, h: 0.34, alpha: 0.22)
            glow(x: 0.86, y: 0.58, w: 0.50, h: 0.30, alpha: 0.16)
            glow(x: 0.40, y: 0.96, w: 0.70, h: 0.28, alpha: 0.14)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func glow(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, alpha: Double) -> some View {
        let size = LayoutPlaces.phone
        return Ellipse()
            .fill(RadialGradient(
                colors: [tint.opacity(room == .bridge ? alpha * 0.4 : alpha), .clear],
                center: .center,
                startRadius: 0,
                endRadius: size.width * w * 0.7
            ))
            .frame(width: size.width * w * 1.4, height: size.height * h * 1.4)
            .position(x: size.width * x, y: size.height * y)
    }

    /// The 24 pt side margins as dashed guides, each labelled 24.
    private var guides: some View {
        ZStack {
            ForEach([LayoutPlaces.margin, LayoutPlaces.phone.width - LayoutPlaces.margin], id: \.self) { x in
                Path { path in
                    path.move(to: CGPoint(x: x, y: 44))
                    path.addLine(to: CGPoint(x: x, y: 852))
                }
                .stroke(tint.opacity(0.26), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
            Text("24").position(x: 12, y: 36)
            Text("24").position(x: LayoutPlaces.phone.width - 12, y: 36)
        }
        .font(LayoutFont.number(9))
        .foregroundStyle(tint.mix(with: Theme.Colors.inkSecondary, by: 0.4))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Card

    @ViewBuilder
    private var card: some View {
        if let key = selection, let place = places.first(where: { $0.key == key }) {
            let low = place.isLow
            VStack {
                if !low {
                    Spacer(minLength: 0)
                }
                LayoutCard(place: place, room: room, level: level, tint: tint, look: look)
                    .padding(.horizontal, 16)
                    .onTapGesture {}
                if low {
                    Spacer(minLength: 0)
                }
            }
            .padding(.top, low ? 196 : 0)
            .padding(.bottom, low ? 0 : LayoutPlaces.phone.height - 762)
            .frame(width: LayoutPlaces.phone.width, height: LayoutPlaces.phone.height)
            .transition(AnyTransition.opacity.combined(with: reduceMotion ? .identity : .offset(y: 16))
                .combined(with: reduceMotion ? .identity : .scale(scale: 0.98)))
            .zIndex(5)
        }
    }

    // MARK: Gestures

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let dx = value.translation.width, dy = value.translation.height
                if abs(dx) > 50, abs(dx) > abs(dy) {
                    move(dx < 0 ? 1 : -1)
                } else if abs(dy) > 50 {
                    go(dy < 0 ? .door : .landing)
                }
            }
    }

    private func tap(_ place: LayoutPlace) {
        guard !busy else { return }
        if selection == place.key {
            if place.name == "Dial", level == .landing {
                if room == .bridge {
                    move(1)
                } else {
                    go(.door)
                }
                return
            }
            if place.name == "Nav word" {
                if level == .door {
                    go(.landing)
                } else {
                    dismiss()
                }
                return
            }
            pick(nil)
            return
        }
        pick(place.key)
    }

    private func pick(_ key: String?) {
        withTesseraAnimation(.spring(duration: 0.42, bounce: 0.1), reduceMotion: reduceMotion) { selection = key }
    }

    // MARK: Changes

    private func move(_ step: Int) {
        guard !busy else { return }
        change(room: room.moved(step), level: room == .bridge || room.moved(step) == .bridge ? .landing : level,
               direction: Double(step))
    }

    private func go(_ next: LayoutLevel) {
        guard !busy, room != .bridge, level != next else { return }
        change(room: room, level: next, direction: next == .door ? 1 : -1)
    }

    private func change(room nextRoom: LayoutRoom, level nextLevel: LayoutLevel, direction dir: Double) {
        let plan = LayoutChange.plan(from: places, to: LayoutPlaces.places(nextRoom, nextLevel))
        let roomChanged = nextRoom != room
        direction = dir
        selection = nil
        withTesseraAnimation(.easeInOut(duration: 0.45), reduceMotion: reduceMotion) {
            room = nextRoom
            level = nextLevel
        }
        let old = places
        let next = LayoutPlaces.places(nextRoom, nextLevel)

        // Panes that kept their frame only take the tint and play their label.
        for key in plan.steady {
            flipTokens[key, default: 0] += 1
        }
        if roomChanged {
            sheenToken += 1
        }

        guard !reduceMotion, plan.isLiquid, !busy else {
            places = next
            leaving = []
            return
        }
        busy = true
        hidden = Set(plan.settle)
        leaving = old.filter { plan.leaving.contains($0.key) }
        leavingFade = 1
        places = next
        liquid = plan
        clock = 0
        liquidOpacity = 1
        withTesseraAnimation(.easeOut(duration: 0.16), reduceMotion: reduceMotion) { leavingFade = 0 }
        withTesseraAnimation(.linear(duration: plan.total / 1000), reduceMotion: reduceMotion) { clock = plan.total }
        Task { await settle(plan) }
    }

    /// After the liquid: each new pane sets into glass (300 ms blur-in, 14 ms apart), then the liquid fades.
    private func settle(_ plan: LayoutChange) async {
        try? await Task.sleep(for: .milliseconds(Int(plan.total) + 20))
        leaving = []
        for (index, key) in plan.settle.enumerated() {
            withTesseraAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.3).delay(Double(index) * 0.014),
                                 reduceMotion: reduceMotion) { _ = hidden.remove(key) }
        }
        withTesseraAnimation(.easeOut(duration: 0.32), reduceMotion: reduceMotion) { liquidOpacity = 0 }
        try? await Task.sleep(for: .milliseconds(360 + plan.settle.count * 14))
        liquid = nil
        busy = false
    }
}

/// The liquid pass: every pane that changes shape is a blob (blur 7, alpha threshold) that springs to its new frame.
/// Animatable so the clock runs through `withTesseraAnimation`.
struct LiquidLayer: View, Animatable {
    var clock: Double
    let change: LayoutChange
    let tint: Color

    nonisolated var animatableData: Double {
        get { clock }
        set { clock = newValue }
    }

    var body: some View {
        Canvas { context, _ in
            context.addFilter(.alphaThreshold(min: 0.4, color: tint))
            context.addFilter(.blur(radius: 7))
            context.drawLayer { layer in
                for track in change.tracks {
                    let rect = change.rect(track, at: clock)
                    if track.gone {
                        layer.opacity = max(0, 1 - ((clock - track.delay) / LayoutChange.springMs) * 1.4)
                    } else {
                        layer.opacity = 1
                    }
                    let radius = min(22, min(rect.width, rect.height) * 0.32)
                    layer.fill(Path(roundedRect: rect, cornerRadius: radius, style: .continuous), with: .color(.black))
                }
            }
        }
        .frame(width: LayoutPlaces.phone.width, height: LayoutPlaces.phone.height)
    }
}
