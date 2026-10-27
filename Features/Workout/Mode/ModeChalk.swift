import SwiftUI

/// The workout mode's material (sheet 327): slate, and everything in chalk in Barlow Condensed. The values are the
/// blackboard's own (`TrainingBlackboard`), named once here so the whole-screen mode and the keystone agree.
enum Chalk {
    static let white = Color(hex: 0xF1EEE6)
    /// Chalk blue: Tess's blue lifted for slate (the workout palette's tess).
    static let blue = Color(hex: 0x9DBFE6)
    static let quiet = white.opacity(0.58)
    static let faint = white.opacity(0.32)

    /// Barlow Condensed 600. `relativeTo` lets the small lines follow Dynamic Type; the numerals use a fixed slot and
    /// shrink to fit instead.
    static func font(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("BarlowCondensed-SemiBold", size: size, relativeTo: style)
    }
}

/// The bar with each side's plates, to scale (sheet 325): the sleeve at the middle, the plates growing outward in the
/// order they go on, heaviest nearest the collar. Drawn in chalk; no animation of its own (the plates are a fact).
struct PlateBar: View {
    let load: PlateLoad
    /// The plate sizes the gym has, so a 2.5 is drawn thinner and shorter than a 45.
    let inventory: PlateInventory

    var body: some View {
        Canvas { context, size in
            let mid = size.height / 2
            let barHeight: CGFloat = 6
            let sleeve = Path(CGRect(x: 0, y: mid - barHeight / 2, width: size.width, height: barHeight))
            context.fill(sleeve, with: .color(Chalk.quiet))
            let largest = inventory.plates.max() ?? 45
            let thickness: CGFloat = 12
            let gap: CGFloat = 3
            // Both sides mirror: plates stack outward from the collar, heaviest first.
            let center = size.width / 2
            var offset: CGFloat = 36
            for plate in load.perSide {
                let ratio = max(CGFloat(plate / largest), 0.18)
                let height = size.height * (0.28 + 0.72 * ratio)
                let width = thickness * (0.6 + 0.4 * ratio)
                offset += gap
                let right = CGRect(x: center + offset, y: mid - height / 2, width: width, height: height)
                let left = CGRect(x: center - offset - width, y: mid - height / 2, width: width, height: height)
                for rect in [right, left] {
                    context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(Chalk.white), lineWidth: 2.4)
                }
                offset += width
            }
            let cap = CGRect(x: center - 36, y: mid - 12, width: 72, height: 24)
            context.fill(Path(roundedRect: cap, cornerRadius: 4), with: .color(Chalk.faint))
        }
        .frame(height: 76)
        .accessibilityElement()
        .accessibilityLabel(load.isBarOnly ? "Bar only" : load.line)
    }
}
