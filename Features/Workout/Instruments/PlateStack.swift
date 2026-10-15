import SwiftUI

/// Round 6 ("Plein") paint. Kept here so a restyle is a one-line change. The big plates take
/// `Theme.Colors.plate(_:)`; the change plates have no colour there.
private enum Paint {
    static let cream = Color(hex: 0xF3ECE0)
    static let label = Color(hex: 0xA79FB5)
    static let sleeve = cream.opacity(0.38)
    static let plateLight = cream.opacity(0.25)
    static let plateShade = Color(hex: 0x1C1828).opacity(0.45)
    static let changeLarge = Color(hex: 0x55534F)
    static let changeSmall = Color(hex: 0xA8A49C)
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
        HStack(spacing: Theme.Spacing.m) {
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
        HStack(spacing: 1) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(Paint.sleeve)
                .frame(width: Metrics.sleeveWidth, height: Metrics.sleeveHeight)
                .zIndex(1)
            ForEach(plates) { plate in
                plateView(plate.kilograms)
                    .transition(plateTransition)
            }
        }
        .frame(height: Metrics.tallest)
        .clipped()
        .tesseraAnimation(Theme.Motion.snappy, value: plates.map(\.id))
    }

    private var plateTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .leading).combined(with: .opacity)
    }

    private func plateView(_ kilograms: Double) -> some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.plateRadius, style: .continuous)
        let pixel = 1 / displayScale
        return shape
            .fill(color(for: kilograms))
            .overlay(alignment: .leading) { Paint.plateLight.frame(width: pixel) }
            .overlay(alignment: .trailing) { Paint.plateShade.frame(width: pixel) }
            .clipShape(shape)
            .frame(width: Metrics.plateWidth, height: Self.height(for: kilograms))
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
