import CoreGraphics

/// Every point of the 402 x 874 screen belongs to a named place (sheet 283 v4). An empty place is kept and marked,
/// never filled by its neighbour. Phone points: x, y, width, height. The scaffold and the layout test read these.
enum LandingPlace: String, CaseIterable {
    case statusBar, masthead, breathAboveKeystone, keystone, caption, widget, breathBelowWidget, doors
    case breathAboveFoot, foot, homeBar

    var frame: CGRect {
        switch self {
        case .statusBar: CGRect(x: 0, y: 0, width: 402, height: 44)
        case .masthead: CGRect(x: 0, y: 44, width: 402, height: 138)
        case .breathAboveKeystone: CGRect(x: 24, y: 182, width: 354, height: 14)
        case .keystone: CGRect(x: 24, y: 196, width: 354, height: 182)
        case .caption: CGRect(x: 24, y: 378, width: 354, height: 34)
        case .widget: CGRect(x: 24, y: 412, width: 354, height: 200)
        case .breathBelowWidget: CGRect(x: 24, y: 612, width: 354, height: 28)
        case .doors: CGRect(x: 24, y: 640, width: 354, height: 120)
        case .breathAboveFoot: CGRect(x: 24, y: 760, width: 354, height: 16)
        case .foot: CGRect(x: 0, y: 776, width: 402, height: 76)
        case .homeBar: CGRect(x: 0, y: 852, width: 402, height: 22)
        }
    }

    /// The three Breaths are always empty: nothing is drawn in them.
    var isBreath: Bool {
        self == .breathAboveKeystone || self == .breathBelowWidget || self == .breathAboveFoot
    }

    /// The places inside the Masthead (Bridge holds the Settings word and the Departure board there instead).
    enum Masthead {
        static let title = CGRect(x: 24, y: 50, width: 260, height: 48)
        static let navWord = CGRect(x: 300, y: 50, width: 94, height: 46)
        static let switcher = CGRect(x: 24, y: 106, width: 200, height: 76)
        static let needs = CGRect(x: 228, y: 118, width: 150, height: 58)
        static let settingsWord = CGRect(x: 24, y: 74, width: 110, height: 44)
        static let departureBoard = CGRect(x: 140, y: 74, width: 238, height: 104)
    }

    enum Widget {
        static let glyph = CGRect(x: 298, y: 444, width: 80, height: 80)
        /// The content starts here (the header sits at 429).
        static let contentTop: CGFloat = 429
    }

    enum Doors {
        // Kaushik, Oct 26: the dial is on the RIGHT (he is right-handed) and the door summary on the LEFT.
        static let dial = CGRect(x: 218, y: 640, width: 160, height: 120)
        static let summary = CGRect(x: 24, y: 640, width: 192, height: 120)
    }

    enum Foot {
        static let actionWord = CGRect(x: 24, y: 786, width: 220, height: 62)
        /// The word's frame height at the default size; at larger sizes it grows upward.
        static let designHeight: CGFloat = 62
        static let tess = CGRect(x: 306, y: 776, width: 96, height: 96)
    }

    /// The back edge (swipe back) and the empty right edge.
    static let backEdge = CGRect(x: 0, y: 0, width: 24, height: 874)
    static let rightEdge = CGRect(x: 378, y: 0, width: 24, height: 874)
}
