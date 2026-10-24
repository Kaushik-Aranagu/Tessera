import SwiftUI

/// The set mark (sheet 230): one cable-machine weight stack per set, 11 x 24 pt (12 x 28 at the focus), 5 pt between
/// sets. Parts top to bottom: the grip (5.2 pt, stroke 1.6) on a short cable, the cap (the top plate, 1.4), a rod
/// (0.8, ink 3) and a floor (1, ink 3). One plate line per rep. Logged reps lift up under the cap in go green at
/// 1.15; reps still to do rest on the floor in ink 3 at 0.8. The rod stops at the first plate it carries, and with
/// nothing lifted at the top resting plate; it never runs to the floor. Cable and cap turn green once the set has
/// any reps; the grip turns green when the set is full.
struct StackMarkSpec: Equatable, Hashable {
    /// Reps planned: one plate line each.
    var reps: Int
    /// Reps logged: lifted under the cap.
    var lifted: Int
    var isFocus = false

    var hasAny: Bool {
        lifted > 0
    }

    var isFull: Bool {
        reps > 0 && lifted >= reps
    }

    /// Plate lines drawn: the plan, or the reps done when he did more (so nothing is lost off the stack).
    var plates: Int {
        min(max(reps, lifted, 1), StackMarkGeometry.maxPlates)
    }

    var spoken: String {
        "\(lifted) of \(reps) reps"
    }
}

/// Where every line of a stack sits, in points from the top left of its frame. Pure, so the parts are tested.
struct StackMarkGeometry: Equatable {
    static let normal = CGSize(width: 11, height: 24)
    static let focus = CGSize(width: 12, height: 28)
    static let gap: CGFloat = 5
    static let maxPlates = 20
    static let gripWidth: CGFloat = 5.2

    enum Stroke {
        static let grip: CGFloat = 1.6
        static let cap: CGFloat = 1.4
        static let rod: CGFloat = 0.8
        static let floor: CGFloat = 1
        static let lifted: CGFloat = 1.15
        static let resting: CGFloat = 0.8
        static let cable: CGFloat = 1
    }

    let size: CGSize
    let plates: Int

    init(spec: StackMarkSpec) {
        size = spec.isFocus ? Self.focus : Self.normal
        plates = spec.plates
    }

    var gripY: CGFloat {
        size.height * 0.04 + Stroke.grip / 2
    }

    var capY: CGFloat {
        size.height * 0.21
    }

    var floorY: CGFloat {
        size.height - Stroke.floor / 2
    }

    var midX: CGFloat {
        size.width / 2
    }

    /// Plate lines are a little narrower than the cap and floor.
    var plateInset: CGFloat {
        1.4
    }

    /// The space between plate lines: 2 pt, tighter as the plan grows so the lifted stack never meets the resting one.
    var plateGap: CGFloat {
        let room = floorY - capY - 2.5
        return max(0.8, min(2.0, room / CGFloat(max(plates, 1)) * 0.9))
    }

    /// Plate `index` (0 is the first rep to lift, the top one resting): resting on the floor, and lifted under the cap.
    func restingY(_ index: Int) -> CGFloat {
        floorY - plateGap * CGFloat(plates - index)
    }

    func liftedY(_ index: Int) -> CGFloat {
        capY + plateGap * CGFloat(index + 1)
    }

    /// Where plate `index` is with `lift` plates lifted (fractional while the stack moves, in order).
    func plateY(_ index: Int, lift: Double) -> CGFloat {
        let progress = CGFloat(min(max(lift - Double(index), 0), 1))
        let eased = progress * progress * (3 - 2 * progress)
        return restingY(index) + (liftedY(index) - restingY(index)) * eased
    }

    func isLifted(_ index: Int, lift: Double) -> Bool {
        lift - Double(index) >= 0.5
    }

    /// The rod runs from the cap to the last plate it carries; with none, to the top resting plate. Never the floor.
    func rodEnd(lift: Double) -> CGFloat {
        let carried = Int(lift.rounded(.down))
        if carried > 0 {
            return plateY(carried - 1, lift: lift)
        }
        return plateY(0, lift: lift)
    }
}

/// One stack, drawn in a canvas; `lift` is how many plates are up, fractional while they travel (animatable, so the
/// plates rise in order, 70 ms apart, when the caller animates it).
struct StackMark: View, Animatable {
    var spec: StackMarkSpec
    var lift: Double

    init(spec: StackMarkSpec, lift: Double? = nil) {
        self.spec = spec
        self.lift = lift ?? Double(spec.lifted)
    }

    nonisolated var animatableData: Double {
        get { lift }
        set { lift = newValue }
    }

    var body: some View {
        let geometry = StackMarkGeometry(spec: spec)
        let green = Theme.Colors.Go.green
        let quiet = Theme.Colors.inkTertiary
        let cap = Theme.Colors.inkSecondary
        let any = lift > 0.05
        let full = lift >= Double(spec.plates) - 0.05 && spec.reps > 0
        Canvas { context, _ in
            let width = geometry.size.width
            func line(_ from: CGPoint, _ end: CGPoint, _ color: Color, _ thickness: CGFloat) {
                var path = Path()
                path.move(to: from)
                path.addLine(to: end)
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: thickness, lineCap: .round))
            }
            // The floor and the rod are ink 3 (quiet).
            line(CGPoint(x: 0.5, y: geometry.floorY), CGPoint(x: width - 0.5, y: geometry.floorY), quiet,
                 StackMarkGeometry.Stroke.floor)
            line(CGPoint(x: geometry.midX, y: geometry.capY), CGPoint(x: geometry.midX, y: geometry.rodEnd(lift: lift)),
                 quiet, StackMarkGeometry.Stroke.rod)
            // Plates.
            for index in 0 ..< geometry.plates {
                let y = geometry.plateY(index, lift: lift)
                let isUp = geometry.isLifted(index, lift: lift)
                line(CGPoint(x: geometry.plateInset, y: y), CGPoint(x: width - geometry.plateInset, y: y),
                     isUp ? green : quiet,
                     isUp ? StackMarkGeometry.Stroke.lifted : StackMarkGeometry.Stroke.resting)
            }
            // The cap, and the cable up to the grip.
            line(CGPoint(x: 0.7, y: geometry.capY), CGPoint(x: width - 0.7, y: geometry.capY), any ? green : cap,
                 StackMarkGeometry.Stroke.cap)
            line(CGPoint(x: geometry.midX, y: geometry.gripY), CGPoint(x: geometry.midX, y: geometry.capY),
                 any ? green : quiet, StackMarkGeometry.Stroke.cable)
            // The grip.
            let half = StackMarkGeometry.gripWidth / 2
            line(
                CGPoint(x: geometry.midX - half, y: geometry.gripY),
                CGPoint(x: geometry.midX + half, y: geometry.gripY),
                full ? green : cap,
                StackMarkGeometry.Stroke.grip
            )
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .accessibilityHidden(true)
    }
}

/// The stacks of a lift, left to right: one per planned set, 5 pt apart; the set under way is drawn larger. Fixed
/// slot: it is as high as the focus stack whatever is drawn, so nothing around it shifts.
struct StackRow: View {
    let sets: [StackMarkSpec]
    var spoken: String

    var body: some View {
        HStack(alignment: .bottom, spacing: StackMarkGeometry.gap) {
            ForEach(Array(sets.enumerated()), id: \.offset) { _, spec in
                StackMark(spec: spec)
            }
        }
        .frame(height: StackMarkGeometry.focus.height, alignment: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }
}
