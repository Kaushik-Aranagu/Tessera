import Foundation

/// A room's color is how he tells rooms apart as he moves between them, so two rooms never share one (Design sheet
/// 365, R1 spec section 4): a room's color sits ΔE76 20 or more from every other room's color, in light and in dark.
public enum RoomColor {
    public struct Pair: Equatable, Sendable {
        public let light: UInt32
        public let dark: UInt32?

        public init(_ light: UInt32, _ dark: UInt32? = nil) {
            self.light = light
            self.dark = dark
        }
    }

    public nonisolated static let minimumDistance = 20.0

    /// The color roles a room may take, as the app paints them (light, dark). Roles with no entry (ink, inkSoft, ember,
    /// wine, slate) are Tess's or neutral and are never a room's own color.
    public nonisolated static let roles: [String: Pair] = [
        "ochre": Pair(0xA8701F, 0xD49A52), "sage": Pair(0x3F7A62, 0x8DBFA7),
        "violet": Pair(0x5B3FB8, 0xB9A9E0), "olive": Pair(0x5E6B1F, 0xB5BE7A), "dusk": Pair(0x8E4A78, 0xD79AA6),
        "rain": Pair(0x557A93, 0x9DBACE),
    ]

    /// Roles Design has passed as a room's own color without a table entry: slate is the Chart room's, and the board
    /// checked it against every room (sheet 365).
    public nonisolated static let passed: Set<String> = ["slate"]

    /// Whether a role may be a room's own color: passed by Design, or clear of every other room in both themes.
    @MainActor public static func isFree(_ role: String, besides own: String? = nil) -> Bool {
        if passed.contains(role) {
            return true
        }
        return roles[role].map { clash(of: $0, besides: own) == nil } ?? false
    }

    /// The other rooms' colors, by room name. The app sets the whole dial's table at launch; these are the ones the
    /// design sheets name. The Chart room's own color never counts against itself.
    @MainActor public static var otherRooms: [String: Pair] = [
        "Purse": Pair(0x2A7878), "Watch": Pair(0x8E4A78, 0xD59AC4), "Log": Pair(0x8A4570, 0xE3A3CB),
        "Training": Pair(0x0B62AE, 0x8FB0EE), "Kitchen": roles["ochre"]!, "Notes": roles["violet"]!,
        "Money": roles["sage"]!, "Routines": roles["dusk"]!, "Lookout": roles["rain"]!,
    ]

    /// Colors he may name in words, as the board sees them: what a word means before it is a role.
    public nonisolated static let words: [String: Pair] = [
        "teal": Pair(0x2A7878, 0x6FB8B8), "blue": Pair(0x0B62AE, 0x8FB0EE), "green": Pair(0x3F7A62, 0x8DBFA7),
        "purple": Pair(0x5B3FB8, 0xB9A9E0), "orange": Pair(0xA8701F, 0xD49A52), "pink": Pair(0x8E4A78, 0xD79AA6),
        "olive": Pair(0x5E6B1F, 0xB5BE7A), "red": Pair(0xB0302A, 0xE08A80),
    ]

    // MARK: Distance

    /// CIE76 ΔE between two sRGB colors.
    public nonisolated static func deltaE(_ a: UInt32, _ b: UInt32) -> Double {
        let (l1, a1, b1) = lab(a)
        let (l2, a2, b2) = lab(b)
        return ((l1 - l2) * (l1 - l2) + (a1 - a2) * (a1 - a2) + (b1 - b2) * (b1 - b2)).squareRoot()
    }

    nonisolated static func lab(_ rgb: UInt32) -> (Double, Double, Double) {
        func linear(_ channel: UInt32) -> Double {
            let c = Double(channel) / 255
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let (r, g, b) = (linear((rgb >> 16) & 0xFF), linear((rgb >> 8) & 0xFF), linear(rgb & 0xFF))
        let x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047
        let y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
        let z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883
        func f(_ t: Double) -> Double {
            t > 216.0 / 24389 ? cbrt(t) : (24389.0 / 27 * t + 16) / 116
        }
        let (fx, fy, fz) = (f(x), f(y), f(z))
        return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))
    }

    /// The nearest distance in either theme between a candidate and an other room's color.
    nonisolated static func distance(_ candidate: Pair, _ other: Pair) -> Double {
        var nearest = deltaE(candidate.light, other.light)
        if let darkA = candidate.dark, let darkB = other.dark {
            nearest = min(nearest, deltaE(darkA, darkB))
        }
        return nearest
    }

    /// The other room (and how far) that a candidate color is too close to, or nil when it is clear of all of them.
    @MainActor public static func clash(of candidate: Pair,
                                        besides own: String? = nil) -> (room: String, distance: Double)?
    {
        otherRooms.filter { $0.key != own }
            .map { ($0.key, distance(candidate, $0.value)) }
            .filter { $0.1 < minimumDistance }
            .min { $0.1 < $1.1 }
            .map { (room: $0.0, distance: $0.1) }
    }

    /// The role nearest a color that is clear of every other room, if any.
    @MainActor public static func nearestAllowedRole(to candidate: Pair, besides own: String? = nil) -> String? {
        let free = roles.filter { clash(of: $0.value, besides: own) == nil }
        return free.min { distance(candidate, $0.value) < distance(candidate, $1.value) }?.key
    }
}
