import CoreGraphics
import Foundation
import TesseraCore

/// The mosaic's pages on Home (sheet 209): a horizontal swipe that starts on the mosaic, or within 30 pt of it, and
/// travels more than 40 pt changes the page: left goes to the next, right to the previous, and it wraps round. The
/// page index goes to Builder A's mosaic. After two minutes or more away the mosaic is back on its mood page. Pure
/// pieces, so the rules test without a screen.
struct MosaicPager: Equatable {
    /// How many pages the mosaic has; one until A's pages exist, so a swipe changes nothing and plays no haptic.
    var count = 1
    var index = 0
    private var leftAt: Date?

    static let reach: CGFloat = 30
    static let travel: CGFloat = 40
    static let awaySeconds: TimeInterval = 120

    /// Whether a drag is a page swipe: it began on the mosaic or within `reach` of it, went across more than `travel`,
    /// and more across than down.
    /// With more than one page the swipe must start on the mosaic itself (`reach` 0), so a Done swipe on a Next row can
    /// never turn the page.
    static func accepts(start: CGPoint, translation: CGSize, mosaic: CGRect,
                        reach: CGFloat = MosaicPager.reach) -> Bool
    {
        mosaic.insetBy(dx: -reach, dy: -reach).contains(start)
            && abs(translation.width) > travel
            && GestureTuning.axis(dx: translation.width, dy: translation.height, bias: GestureTuning.pagerBias)
            == .horizontal
            && (translation.width < 0 || GestureTuning.clearsBackEdge(startX: start.x))
    }

    /// Applies a swipe by `dx` (left is negative: next). Returns whether the page changed.
    @discardableResult
    mutating func swipe(dx: CGFloat) -> Bool {
        guard count > 1, abs(dx) > Self.travel else { return false }
        index = ((index + (dx < 0 ? 1 : -1)) % count + count) % count
        return true
    }

    mutating func leave(at date: Date) {
        leftAt = date
    }

    /// Coming back: two minutes or more away puts it on the mood page (0).
    mutating func returned(at date: Date) {
        if let leftAt, date.timeIntervalSince(leftAt) >= Self.awaySeconds {
            index = 0
        }
        leftAt = nil
    }
}
