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

/// The bar with each side's plates, to scale (sheets 325 and 331): the sleeve at the middle, the plates growing outward
/// from the collar. When the load changes, an added plate drops onto the sleeve and a removed one slides off the end
/// and fades, 320 ms; with Reduce Motion the plates just change.
struct PlateBar: View {
    let load: PlateLoad
    /// The plate sizes the gym has, so a 2.5 is drawn thinner and shorter than a 45.
    let inventory: PlateInventory

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var diff = PlateDiff(kept: [], added: [], removed: [])
    @State private var progress = 1.0

    static let duration = 0.32

    var body: some View {
        PlateBarDrawing(plates: load.perSide, diff: diff, largest: inventory.plates.max() ?? 45, progress: progress)
            .frame(height: 76)
            .onChange(of: load.perSide) { old, new in
                guard !reduceMotion else {
                    diff = PlateDiff(kept: [], added: [], removed: [])
                    progress = 1
                    return
                }
                diff = PlateDiff.between(old, new)
                progress = 0
                withTesseraAnimation(.easeOut(duration: Self.duration), reduceMotion: reduceMotion) { progress = 1 }
            }
            .accessibilityElement()
            .accessibilityLabel(load.isBarOnly ? "Bar only" : load.line)
    }
}

/// Draws the bar for a `progress` from 0 to 1 (animatable, so SwiftUI interpolates it each frame).
private struct PlateBarDrawing: View, Animatable {
    let plates: [Double]
    let diff: PlateDiff
    let largest: Double
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let mid = size.height / 2
            let center = size.width / 2
            let sleeve = Path(CGRect(x: 0, y: mid - 3, width: size.width, height: 6))
            context.fill(sleeve, with: .color(Chalk.quiet))
            // The plates now on the bar, then the ones leaving (drawn at their old place, sliding out and fading).
            var layout: [(plate: Double, position: Int, dx: CGFloat, dy: CGFloat, alpha: Double)] = []
            for (position, plate) in plates.enumerated() {
                let isAdded = diff.added.contains { $0.position == position }
                layout.append((plate, position, 0, isAdded ? -24 * (1 - progress) : 0, isAdded ? progress : 1))
            }
            for item in diff.removed {
                layout.append((item.plate, item.position, 28 * progress, 0, 1 - progress))
            }
            for entry in layout {
                let before = plates.prefix(min(entry.position, plates.count)).reduce(0) { $0 + width(of: $1) + 3 }
                let fallback = diff.removed.contains { $0.position == entry.position } && entry.position >= plates.count
                let offset = 36 + 3 + (fallback ? removedOffset(entry.position) : before)
                let height = height(of: entry.plate, in: size)
                let width = width(of: entry.plate)
                for side: CGFloat in [1, -1] {
                    let x = side > 0 ? center + offset + entry.dx : center - offset - width - entry.dx
                    let rect = CGRect(x: x, y: mid - height / 2 + entry.dy, width: width, height: height)
                    context.stroke(Path(roundedRect: rect, cornerRadius: 3),
                                   with: .color(Chalk.white.opacity(entry.alpha)), lineWidth: 2.4)
                }
            }
            let cap = CGRect(x: center - 36, y: mid - 12, width: 72, height: 24)
            context.fill(Path(roundedRect: cap, cornerRadius: 4), with: .color(Chalk.faint))
        }
    }

    private func width(of plate: Double) -> CGFloat {
        12 * (0.6 + 0.4 * max(CGFloat(plate / largest), 0.18))
    }

    private func height(of plate: Double, in size: CGSize) -> CGFloat {
        size.height * (0.28 + 0.72 * max(CGFloat(plate / largest), 0.18))
    }

    /// A removed plate sits where it was: after the plates both loads share, in the old order.
    private func removedOffset(_ position: Int) -> CGFloat {
        let ordered = (diff.kept + diff.removed).sorted { $0.position < $1.position }
        return ordered.prefix { $0.position < position }.reduce(0) { $0 + width(of: $1.plate) + 3 }
    }
}
