import SwiftUI
import TesseraCore
import TesseraTess

/// What a screen lets him change about a measure (Design sheet 115, control plane). `.unit` is what `MeasureView`
/// handles; `.number` is for the caller's own dial, drum or keyboard (editing a number never changes its unit).
enum MeasureControl {
    case number, unit
}

/// The two roles a measure is drawn in. One place for both, so a new type pair drops in without moving widths twice.
enum MeasureStyle {
    static func number(size: CGFloat, weight: Font.Weight) -> Font {
        .system(size: size, weight: weight)
    }

    static let unit: Font = .system(size: 10, weight: .semibold)
    static let unitTracking: CGFloat = 1.4
    /// Between the number and its unit, and between "1 hr" and "35 min".
    static let gap: CGFloat = 4
    static let pairGap: CGFloat = 8
    /// A swipe moves one unit per this many points.
    static let stepLength: CGFloat = 14
}

/// A number with its small unit, drawn apart: the number in its own role, the unit as a small word that can be swiped
/// (up or down: the units that fit step one at a time, a tick each, and the number converts as it goes). Display
/// only: the stored value never changes, and his pick is remembered for the whole kind, so changing one kg to lb
/// changes every weight in the app. A kind with one unit shows a plain word, with no gesture and no affordance.
/// Callers never format a number or a unit by hand.
struct MeasureView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    let measure: Measure
    var controls: Set<MeasureControl> = [.unit]
    var size: CGFloat = 16
    var weight: Font.Weight = .semibold
    var color: Color = Theme.Colors.ink

    /// The unit under the finger while a swipe is going; nil at rest.
    @State private var swiping: String?
    @State private var swipeFrom: String?
    @State private var ticks = 0
    @State private var showsReceipt = false

    /// The unit shown now: the swipe, else his pick for the kind, else the measure's own.
    private var unit: String {
        swiping ?? model.displayUnits.unit(for: measure.kind) ?? measure.unit
    }

    /// The measure expressed in `unit` (unchanged when it cannot be: money with no rates).
    private var shown: Measure {
        unit == measure.unit ? measure : measure.converted(to: unit, rates: model.ratesTable) ?? measure
    }

    private var wheel: [String] {
        MeasureParts.wheel(for: measure, rates: model.ratesTable)
    }

    private var swipes: Bool {
        controls.contains(.unit) && !wheel.isEmpty
    }

    var body: some View {
        let parts = MeasureParts.parts(of: shown)
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: MeasureStyle.pairGap))
        layout {
            if shown.isEstimate {
                Text("about").font(MeasureStyle.unit).foregroundStyle(Theme.Colors.inkSecondary)
            }
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                pair(part)
            }
            if showsReceipt {
                Text(measure.formatted)
                    .font(MeasureStyle.unit)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .transition(.opacity)
            }
        }
        .contentShape(Rectangle().inset(by: -8))
        // A simultaneous tap, so a drag that starts on the number is still the page's scroll.
        .simultaneousGesture(TapGesture().onEnded { tap() })
        .tesseraFeedback(.selection, trigger: ticks)
        .tesseraAnimation(.easeOut(duration: 0.15), value: unit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MeasureParts.spoken(shown))
        .accessibilityHint(swipes ? "Swipe up or down to change the unit" : "")
        .accessibilityAdjustableAction { direction in
            guard swipes else { return }
            choose(MeasureParts.step(wheel, from: unit, by: direction == .increment ? 1 : -1))
        }
    }

    /// One number with its unit. The unit is always drawn.
    private func pair(_ part: MeasureParts.Part) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: MeasureStyle.gap) {
            Text(part.number)
                .font(MeasureStyle.number(size: size, weight: weight))
                .monospacedDigit()
                .foregroundStyle(color)
                .contentTransition(.numericText())
            if !part.unit.isEmpty {
                Text(part.unit.uppercased())
                    .font(MeasureStyle.unit)
                    .tracking(MeasureStyle.unitTracking)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    // Only a drag that begins on the unit word is the wheel's; one that begins on the number is the
                    // page's scroll, so a list of measures still scrolls from anywhere but this small word.
                    .contentShape(Rectangle().inset(by: -10))
                    .gesture(unitGesture)
            }
        }
    }

    // MARK: Gestures

    /// The unit's drag. None when the unit does not swipe, under Reduce Motion, and at accessibility sizes: there the
    /// screen scrolls, and any drag the unit claimed (even one that waits for a press) held the scroll back when it
    /// began on a row's number, so a tap cycles the unit instead, as under Reduce Motion.
    private var unitGesture: AnyGesture<Void>? {
        guard swipes, !reduceMotion, !typeSize.isAccessibilitySize else { return nil }
        return AnyGesture(swipe.map { _ in () })
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { unitSwipeChanged($0) }
            .onEnded { _ in unitSwipeEnded() }
    }

    private func unitSwipeChanged(_ value: DragGesture.Value) {
        guard abs(value.translation.height) > abs(value.translation.width) else { return }
        let start = swipeFrom ?? unit
        swipeFrom = start
        let steps = Int((-value.translation.height / MeasureStyle.stepLength).rounded(.towardZero))
        let target = MeasureParts.step(wheel, from: start, by: steps)
        if target != swiping {
            swiping = target
            ticks += 1
        }
    }

    private func unitSwipeEnded() {
        if let target = swiping {
            choose(target)
        }
        swiping = nil
        swipeFrom = nil
    }

    /// A tap: under Reduce Motion or at accessibility sizes it cycles the unit; otherwise it shows the stored value for
    /// a second.
    private func tap() {
        if reduceMotion || typeSize.isAccessibilitySize, swipes {
            choose(MeasureParts.cycle(wheel, from: unit))
            return
        }
        guard unit != measure.unit else { return }
        showsReceipt = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            showsReceipt = false
        }
    }

    private func choose(_ target: String) {
        guard target != unit || swiping != nil else { return }
        ticks += 1
        model.chooseUnit(target, for: measure.kind)
    }
}

/// A page that shows money asks for the rates once, when it opens (never per row, never per redraw). The fetch itself
/// answers from the saved table unless one is due, at most once an hour (AppModel.refreshRates).
extension View {
    func refreshesRates() -> some View {
        modifier(RefreshesRates())
    }
}

private struct RefreshesRates: ViewModifier {
    @Environment(AppModel.self) private var model

    func body(content: Content) -> some View {
        content.task { await model.refreshRates() }
    }
}
