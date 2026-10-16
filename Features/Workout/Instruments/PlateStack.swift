import SwiftUI

/// Round 6 ("Plein") paint. Kept here so a restyle is a one-line change. The big plates take
/// `Theme.Colors.plate(_:)`; the change plates have no colour there.
private enum Paint {
    static var cream: Color {
        Theme.Colors.Workout.ink
    }

    static var label: Color {
        Theme.Colors.Workout.inkSecondary
    }

    static var sleeve: Color {
        cream.opacity(0.38)
    }

    static var plateLight: Color {
        cream.opacity(0.25)
    }

    static var plateShade: Color {
        Theme.Colors.Workout.ground.opacity(0.45)
    }

    /// Change plates are real plates: fixed in every look.
    static var changeLarge: Color {
        Theme.Colors.plate(2.5)
    }

    static var changeSmall: Color {
        Theme.Colors.plate(1.25)
    }
}

/// Plates per side as a label line, "25 + 5 + 1.25 EACH SIDE" (or "BAR ONLY"), from Core's `WeightDial`. Optionally
/// draws one side of the bar before it: the sleeve, then the plates outward; adding or removing a plate slides only
/// that plate in or out from the sleeve.
struct PlateStack: View {
    let weight: Double
    /// One side's plates, heaviest first (empty for the bar alone).
    let perSide: [Double]
    /// The text is primary; the drawing is optional.
    var drawsPlates: Bool = false
    /// The set block's large drawing (docs/design/set-block.md): tallest plate 150 pt, the caption under the bar,
    /// plates dropping on from above and lifting off.
    var large: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale

    private enum Metrics {
        static let plateWidth: CGFloat = 9
        static let plateRadius: CGFloat = 2
        static let sleeveWidth: CGFloat = 6
        static let sleeveHeight: CGFloat = 22
        static let tallest: CGFloat = 64
    }

    /// A plate keyed by its size and how many of that size come before it, so 82.5 → 85 swaps only the small one.
    private struct Plate: Identifiable {
        let kilograms: Double
        let occurrence: Int
        var id: String {
            "\(kilograms)-\(occurrence)"
        }
    }

    var body: some View {
        let plates = keyed(perSide)
        let layout = large ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.s))
            : AnyLayout(HStackLayout(spacing: Theme.Spacing.m))
        layout {
            if drawsPlates {
                drawing(plates)
            }
            Text(caption(plates))
                .textRole(.label)
                .foregroundStyle(Paint.label)
                .contentTransition(.numericText())
                .tesseraAnimation(Theme.Motion.snappy, value: weight)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Plates per side")
        .accessibilityValue(accessibilityValue(plates))
    }

    private func drawing(_ plates: [Plate]) -> some View {
        HStack(spacing: large ? 2 : 1) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(Paint.sleeve)
                .frame(width: Metrics.sleeveWidth * scale, height: Metrics.sleeveHeight * scale)
                .zIndex(1)
            ForEach(plates) { plate in
                plateView(plate.kilograms)
                    .transition(plateTransition)
            }
        }
        .frame(height: Metrics.tallest * scale)
        .clipped()
        .tesseraAnimation(large ? .spring(response: 0.3, dampingFraction: 0.72) : Theme.Motion.snappy,
                          value: plates.map(\.id))
    }

    private var plateTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        // Large: new plates drop on from 30 pt above; removed ones lift 26 pt and fade.
        return large
            ? .asymmetric(insertion: .offset(y: -30).combined(with: .opacity),
                          removal: .offset(y: -26).combined(with: .opacity))
            : .move(edge: .leading).combined(with: .opacity)
    }

    /// Tallest plate 150 pt when large, 64 otherwise.
    private var scale: CGFloat {
        large ? 150 / Metrics.tallest : 1
    }

    private func plateView(_ kilograms: Double) -> some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.plateRadius, style: .continuous)
        let pixel = 1 / displayScale
        return shape
            .fill(color(for: kilograms))
            .overlay(alignment: .leading) { Paint.plateLight.frame(width: pixel) }
            .overlay(alignment: .trailing) { Paint.plateShade.frame(width: pixel) }
            .clipShape(shape)
            .frame(width: Metrics.plateWidth * (large ? 1.9 : 1), height: Self.height(for: kilograms) * scale)
    }

    private func color(for kilograms: Double) -> Color {
        switch kilograms {
        case 2.5: Paint.changeLarge
        case 1.25: Paint.changeSmall
        default: Theme.Colors.plate(kilograms)
        }
    }

    private static func height(for kilograms: Double) -> CGFloat {
        switch kilograms {
        case 25, 20: 64
        case 15: 56
        case 10: 46
        case 5: 36
        case 2.5: 28
        default: 22
        }
    }

    private func keyed(_ sizes: [Double]) -> [Plate] {
        var seen: [Double: Int] = [:]
        return sizes.map { size in
            let occurrence = seen[size, default: 0]
            seen[size] = occurrence + 1
            return Plate(kilograms: size, occurrence: occurrence)
        }
    }

    private func caption(_ plates: [Plate]) -> String {
        guard !plates.isEmpty else { return "Bar only" }
        return plates.map { Self.formatted($0.kilograms) }.joined(separator: " + ") + " each side"
    }

    private func accessibilityValue(_ plates: [Plate]) -> String {
        guard !plates.isEmpty else { return "Bar only" }
        let perSide = plates.reduce(0) { $0 + $1.kilograms }
        let list = plates.map { Self.formatted($0.kilograms) }.formatted(.list(type: .and))
        return "\(Self.formatted(perSide)) kilograms: \(list)"
    }

    private static func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 2)))
    }
}

#Preview {
    let weight = 82.5
    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
        PlateStack(weight: weight, perSide: [25, 5, 1.25])
        PlateStack(weight: weight, perSide: [25, 5, 1.25], drawsPlates: true)
        PlateStack(weight: 20, perSide: [], drawsPlates: true)
        PlateStack(weight: 142.5, perSide: [25, 25, 10, 1.25], drawsPlates: true)
    }
    .padding(Theme.Spacing.gutter)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .background(Theme.Colors.Workout.ground)
}
