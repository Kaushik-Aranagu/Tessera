import QuartzCore
import SwiftUI
import TesseraCore

/// What a wheel tells one of its rows while it draws: where the row is against the finger and what it should look
/// like. Rows are built at the focused size; the wheel scales each by `scale` (anchored leading) and softens it.
struct WheelRowState: Equatable {
    let index: Int
    /// Signed distance in rows between this row and where the wheel is now (fractional while a finger is down).
    let distance: Double
    /// The row the wheel will rest on (the nearest one).
    let isFocused: Bool
    /// The row the wheel springs back to.
    let isHome: Bool
    /// Point size at this distance, from the style's table.
    let size: CGFloat
    /// Whole rows away from the focus: what the static blur is read from.
    let away: Int
}

/// Who owns a touch on a number sitting inside a wheel: a drag that starts on the number never moves the wheel
/// (accept check 3). The number claims at the first sign of a drag; the wheel checks before it follows a finger.
@MainActor
final class WheelTouchGate {
    private(set) var isClaimed = false

    func claim() {
        isClaimed = true
    }

    func release() {
        isClaimed = false
    }
}

extension EnvironmentValues {
    @Entry var wheelTouchGate: WheelTouchGate?
}

/// The one wheel (sheet 230): plan, session, week, library and the number dial are all this. Rows sit on a vertical
/// depth axis with the focus in the middle: a hold-scroll tracks the finger 1:1, a flick moves exactly one row with a
/// spring snap and one light tick per row, a tap on another row centres it and a tap on the focused row hands back
/// to the caller (open its page). It springs home 6 s after the last touch (`WheelHome`).
///
/// A plain tap MUST reach the row buttons: the drag rides on `.simultaneousGesture` (never `.highPriorityGesture`,
/// whose LongPress+Drag(0) swallowed the apps list's taps), and a tap straight after the wheel lets go is read as the
/// finger stopping it (`TapHoldoff`).
struct DepthWheel<Item: Identifiable, Row: View>: View {
    let items: [Item]
    @Binding var focus: Int
    /// The row the wheel springs back to.
    var home: Int
    var style: WheelStyle
    /// Rows before this cannot take the focus (a header row that scrolls away).
    var minFocus = 0
    /// Something holds the wheel where it is (an exercise page is open): the spring-back waits.
    var paused = false
    /// What VoiceOver calls the list.
    var label: String
    /// A row was tapped; `wasFocused` is true when it already had the focus (open it).
    var onTap: (Item, _ wasFocused: Bool) -> Void = { _, _ in }
    /// An accessibility identifier for a row's button (UI tests find rows by it).
    var rowIdentifier: (Item) -> String? = { _ in nil }
    @ViewBuilder var row: (Item, WheelRowState) -> Row

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.lowPowerMotion) private var lowPower
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.wheelTouchGate) private var gate

    /// While a finger is down: where the touch began and where the wheel is.
    @State private var drag: (start: Double, position: Double)?
    @State private var axisIsVertical: Bool?
    @State private var holdoff = TapHoldoff()
    @State private var cue = HapticCue()
    @State private var touches = 0
    @State private var lastTick = 0
    @State private var isTouching = false

    private var range: ClosedRange<Int> {
        minFocus ... max(minFocus, items.count - 1)
    }

    private var rows: Int {
        style.rows(accessibility: typeSize.isAccessibilitySize)
    }

    private var position: Double {
        drag?.position ?? Double(focus)
    }

    var body: some View {
        let position = position
        let nearest = WheelMath.nearest(position: position, in: range)
        let window = items.isEmpty ? nil : WheelMath.window(
            position: position,
            visibleRows: rows,
            in: 0 ... items.count - 1
        )
        ZStack {
            if let window {
                ForEach(Array(window), id: \.self) { index in
                    rowView(index, position: position, nearest: nearest)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .center)
        .clipped()
        .contentShape(Rectangle())
        .simultaneousGesture(dragGesture)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
        .tesseraFeedback(cue)
        .task(id: HomeKey(touches: touches, paused: paused || voiceOver, touching: isTouching, away: focus != home)) {
            guard focus != home, !(paused || voiceOver), !isTouching else { return }
            try? await Task.sleep(for: .seconds(WheelHome.idle))
            guard !Task.isCancelled else { return }
            withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { focus = home }
        }
    }

    private var height: CGFloat {
        style.pitch * CGFloat(rows) + style.extra * 2
    }

    private func rowView(_ index: Int, position: Double, nearest: Int) -> some View {
        let distance = Double(index) - position
        let state = WheelRowState(index: index, distance: distance, isFocused: index == nearest, isHome: index == home,
                                  size: style.size(at: distance), away: index - nearest)
        let blur = WheelDepth.blur(away: state.away, enabled: WheelDepth.settingIsOn, reduceMotion: reduceMotion,
                                   reduceTransparency: reduceTransparency, lowPower: lowPower)
        return Button { tapped(index) } label: {
            row(items[index], state)
                .scaleEffect(style.scale(at: distance), anchor: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: style.pitch)
                .contentShape(Rectangle())
        }
        .buttonStyle(WheelRowButtonStyle())
        .accessibilityIdentifier(rowIdentifier(items[index]) ?? "wheel-row")
        // The blur is set once per row from how many rows it is from the focus, so a drag never re-renders it.
        .blur(radius: blur)
        .tesseraAnimation(Theme.Motion.firm, value: blur)
        .opacity(WheelMath.opacity(distance: distance, visibleRows: rows))
        .offset(y: style.offset(at: distance))
        .allowsHitTesting(abs(distance) < Double(rows) / 2)
    }

    // MARK: Touch

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: CGFloat(GestureTuning.dragStart), coordinateSpace: .global)
            .onChanged { value in
                guard gate?.isClaimed != true else { return }
                if axisIsVertical == nil {
                    axisIsVertical = GestureTuning.axis(dx: Double(value.translation.width),
                                                        dy: Double(value.translation.height)) == .vertical
                }
                guard axisIsVertical == true else { return }
                holdoff.moved(at: CACurrentMediaTime())
                isTouching = true
                if drag == nil {
                    drag = (Double(focus), Double(focus))
                    lastTick = focus
                }
                guard let start = drag?.start else { return }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    drag?.position = WheelMath.position(start: start, translation: value.translation.height,
                                                        pitch: style.pitch, in: range)
                }
                let row = WheelMath.nearest(position: position, in: range)
                if row != lastTick {
                    lastTick = row
                    cue.play(.pageTurn)
                }
            }
            .onEnded { value in
                defer {
                    axisIsVertical = nil
                    isTouching = false
                    touches += 1
                    holdoff.moved(at: CACurrentMediaTime())
                }
                guard axisIsVertical == true, drag != nil else {
                    drag = nil
                    return
                }
                let target = WheelMath.release(position: position, translation: value.translation.height,
                                               velocity: value.velocity.height, pitch: style.pitch, in: range)
                if target != lastTick {
                    cue.play(.pageTurn)
                }
                withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) {
                    focus = target
                    drag = nil
                }
            }
    }

    private func tapped(_ index: Int) {
        guard items.indices.contains(index), holdoff.allowsTap(at: CACurrentMediaTime()) else { return }
        touches += 1
        let wasFocused = index == focus
        if !wasFocused, index >= minFocus {
            cue.play(.pageTurn)
            withTesseraAnimation(Theme.Motion.firm, reduceMotion: reduceMotion) { focus = index }
        }
        onTap(items[index], wasFocused)
    }

    private struct HomeKey: Hashable {
        let touches: Int
        let paused: Bool
        let touching: Bool
        let away: Bool
    }
}

/// A wheel row's button: no highlight, no chrome; the row draws itself.
struct WheelRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
