import SwiftUI

/// The small mouth's shape (tess-picks.md 18c): one curve with three dials. `curve` is the middle's drop (+1 a small
/// smile, down only to -0.35), `tilt` raises only the right corner (never drops the left), `open` rounds the line into
/// a soft o. `width` is 5.6 pt, 4.4 when she sleeps. Derived from her mode plus overlays, so no view picks a face.
struct SoulExpression: Equatable {
    var curve: CGFloat = 0.2
    var tilt: CGFloat = 0
    var open: CGFloat = 0
    var width: CGFloat = 5.6

    static let rest = SoulExpression()

    /// What the router knows when it works out a face.
    struct Moment {
        var mode: TessSoul.Mode = .idle
        var isAsleep = false
        var isAskWaiting = false
        /// Her line was just shown (1.5 s), her beat is landing (940 ms).
        var isSmiling = false
        /// Her own failure (`claudeFailed`, 1.2 s): the only thing that ever turns a corner down.
        var isFailed = false
        /// Live things own their surface: idle shape only.
        var isLive = false
    }

    /// The row of the table in 18c for a moment. Never a frown at him: only `isFailed` goes below the middle.
    static func resolve(_ moment: Moment) -> SoulExpression {
        if moment.isLive {
            return .rest
        }
        if moment.isAsleep {
            return SoulExpression(curve: 0, tilt: 0, open: 0, width: 4.4)
        }
        if moment.isFailed {
            return SoulExpression(curve: -0.35)
        }
        if moment.mode == .listening {
            return SoulExpression(curve: 0, open: 0.75)
        }
        if moment.isSmiling {
            return SoulExpression(curve: 1)
        }
        if moment.isAskWaiting {
            return SoulExpression(curve: 0.3, tilt: 0.4)
        }
        if moment.mode == .thinking {
            return SoulExpression(curve: 0.2, tilt: 0.4)
        }
        return .rest
    }

    /// Every change of shape takes 250 ms, ease-in-out; her line's smile relaxes over 600 ms.
    static let transition = 0.25
    static let relax = 0.6
    /// Her line's smile lasts 1.5 s, her failure's corner 1.2 s.
    static let lineSmile = 1.5
    static let failure = 1.2

    /// The mouth follows the eyes' glance at 70%.
    static let glanceShare: CGFloat = 0.7
    /// Centred under the eyes: the main dabs' mean, 2.6 pt down (soul scale 1).
    static let drop: CGFloat = 2.6
    static let height: CGFloat = 1.1

    /// Where the mouth sits, in the canvas's points from its centre (the same transform as the eyes).
    static func centre(of frame: SoulFrame) -> CGPoint {
        let mains = frame.dabs.prefix(3)
        let count = CGFloat(max(mains.count, 1))
        let scale = frame.look.scale
        return CGPoint(x: mains.reduce(0) { $0 + $1.x } / count * scale + frame.shift.x,
                       y: (mains.reduce(0) { $0 + $1.y } / count + drop) * scale + frame.shift.y)
    }
}

/// The line itself, drawn in a box `width` wide (soul scale 1), centred on the origin. The corners lift 0.5 pt at
/// full curve, the middle drops 1.7 pt, the right corner raises up to 0.9 pt with the tilt.
struct SoulMouthLine: Shape {
    var curve: CGFloat
    var tilt: CGFloat
    var width: CGFloat

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat> {
        get { AnimatablePair(AnimatablePair(curve, tilt), width) }
        set {
            curve = newValue.first.first
            tilt = newValue.first.second
            width = newValue.second
        }
    }

    func path(in _: CGRect) -> Path {
        let half = width / 2
        let lift = 0.5 * curve
        let left = CGPoint(x: -half, y: -lift)
        let right = CGPoint(x: half, y: -lift - 0.9 * max(tilt, 0))
        // The middle of a quadratic sits halfway to its control; put the middle's drop where the dial says.
        let middle = 1.7 * curve - 0.25 * (left.y + right.y)
        var path = Path()
        path.move(to: left)
        path.addQuadCurve(to: right, control: CGPoint(x: 0, y: middle / 0.5))
        return path
    }
}

/// The soft o: 2.7 × 2.8 pt filled at open 1, a line's size at 0.
struct SoulMouthBlob: Shape {
    var open: CGFloat

    var animatableData: CGFloat {
        get { open }
        set { open = newValue }
    }

    func path(in _: CGRect) -> Path {
        let wide = 5.6 + (2.7 - 5.6) * open
        let tall = SoulExpression.height + (2.8 - SoulExpression.height) * open
        return Path(ellipseIn: CGRect(x: -wide / 2, y: -tall / 2, width: wide, height: tall))
    }
}

/// A single short stroke under the eyes, in the eyes' dark pigment at 70% so the eyes lead. It never animates on its
/// own, never loops and never talks: it only turns when the moment does.
struct SoulMouth: View {
    let frame: SoulFrame
    let expression: SoulExpression
    let gaze: SoulGaze
    let color: Color
    /// The eyes' extra look (tilt), in look units.
    var extraLook = CGSize.zero
    /// Reduce Motion: shapes crossfade (150 ms), no glance offset.
    var still = false
    var duration = SoulExpression.transition

    var body: some View {
        let centre = SoulExpression.centre(of: frame)
        let scale = frame.look.scale
        let glance = still ? .zero : gaze.offset
        let blobShare = min(expression.open * 1.4, 1)
        ZStack {
            SoulMouthLine(curve: expression.curve, tilt: expression.tilt, width: expression.width)
                .stroke(color.opacity(0.7), style: StrokeStyle(lineWidth: SoulExpression.height, lineCap: .round))
                .opacity(1 - blobShare)
            SoulMouthBlob(open: expression.open)
                .fill(color.opacity(0.7))
                .opacity(blobShare)
        }
        .frame(width: 8, height: 8)
        .scaleEffect(scale)
        .offset(x: centre.x + (glance.width + extraLook.width * 3) * scale * SoulExpression.glanceShare,
                y: centre.y + (glance.height + extraLook.height * 2.2) * scale * SoulExpression.glanceShare)
        .opacity(frame.look.opacity)
        .tesseraAnimation(.easeInOut(duration: duration), value: expression)
        .tesseraAnimation(.spring(duration: 0.3, bounce: 0.05), value: gaze)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
