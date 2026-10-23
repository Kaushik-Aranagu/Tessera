import Observation
import SwiftUI
import UIKit

// MARK: - Looks

/// A look's own app accents and sky (sheet 213): the looks tune the accents, not only the ground. Single values, not a
/// light and a dark pair: a look is one or the other.
struct LookAccents: Sendable, Equatable {
    var training: UInt32
    var kitchen: UInt32
    var routines: UInt32
    var lists: UInt32
    var notes: UInt32
    var money: UInt32
    /// The sky word's two stops ("Sunset").
    var skyFrom: UInt32
    var skyTo: UInt32
}

/// One theme as single values (docs/design/themes.md). A theme changes only the ground with its field, the ink and
/// the pigments; type, ink actions, dabs, the soul, motion and layout are the same in every look.
struct Look: Sendable, Identifiable, Equatable {
    enum Field: Sendable, Equatable {
        /// Porcelain: flat white; the pigment pools as a watercolour bloom behind the action of the moment.
        case pigmentBloom
        /// Obsidian: pixels off; pigment becomes light (halo, an emitted glow behind the action).
        case emissive
        /// Plein: today's washes and grain.
        case plein
        /// Lacquer: plum-black deepening down, one specular band.
        case lacquer
        /// Celadon: a flat glaze that pools darker at the foot.
        case glaze
    }

    var name: String
    var isDark: Bool
    var field: Field
    var ground: UInt32
    var raised: UInt32
    var ink: UInt32
    var context: UInt32
    var muted: UInt32
    var tess: UInt32
    var live: UInt32
    /// `live` as text on light grounds (contrast); equals `live` on dark looks.
    var liveInk: UInt32
    var now: UInt32
    var health: UInt32
    var training: UInt32
    var neutral: UInt32
    var sky: UInt32
    /// The glint (themes.md addendum, "Sheen"): gold through the letters on white looks (normal blend, 60%),
    /// light passing over everything else (plus-lighter).
    var sheen: UInt32 = 0xFFE2A8
    var sheenOnLetters = false
    /// The accents this look tunes; nil leaves the app's own pair.
    var accents: LookAccents?
    /// Exact solids for ink 2 and ink 3 where the derived tints would come out cold (the warm greys of White and
    /// Black); nil derives them from ink at the usual alphas.
    var ink2: UInt32?
    var ink3: UInt32?
    /// Lacquer's field: the shade it deepens to and its specular band.
    var fieldShade: UInt32 = 0x06030A
    var fieldSpecular: UInt32 = 0xFFF4E6

    var id: String {
        name
    }

    static let porcelain = Look(
        name: "Porcelain", isDark: false, field: .pigmentBloom,
        ground: 0xFFFFFF, raised: 0xF6F5F9, ink: 0x121016, context: 0x5A3DAF, muted: 0xB9B3C3, tess: 0x2450D8,
        live: 0xE2432A, liveInk: 0xC23A22, now: 0xF0A500, health: 0x12936A, training: 0xCC3F68, neutral: 0x9C95A8,
        sky: 0x7FB6E0,
        sheen: 0xF0A500, sheenOnLetters: true
    )

    static let obsidian = Look(
        name: "Obsidian", isDark: true, field: .emissive,
        ground: 0x000000, raised: 0x0F0E12, ink: 0xF5F2EC, context: 0xB7A6E0, muted: 0x5C5765, tess: 0x86B4FF,
        live: 0xFF5B3A, liveInk: 0xFF7A5C, now: 0xFFC23D, health: 0x3FD49A, training: 0xFF6B92, neutral: 0x8E879A,
        sky: 0x7CC4F0
    )

    static let plein = Look(
        name: "Plein", isDark: false, field: .pigmentBloom,
        ground: 0xF3EDE2, raised: 0xFBF7F0, ink: 0x26201E, context: 0x7D4E6E, muted: 0xBDB2A4, tess: 0x2A4FA8,
        live: 0xB9452B, liveInk: 0xA33A22, now: 0xC98E1B, health: 0x5E8F5A, training: 0xB04A5E, neutral: 0xA89C90,
        sky: 0x8DB4C8,
        sheen: 0xE0B341
    )

    static let lacquer = Look(
        name: "Lacquer", isDark: true, field: .lacquer,
        ground: 0x130A0D, raised: 0x221317, ink: 0xF3E8D6, context: 0xD9A6B8, muted: 0x6E5C62, tess: 0x8FB5FF,
        live: 0xF0583A, liveInk: 0xFF7C5E, now: 0xE9B64A, health: 0x86C9A0, training: 0xF48BA6, neutral: 0x9E8F93,
        sky: 0xA6BCD6,
        fieldShade: 0x050203, fieldSpecular: 0xFFF1E0
    )

    static let celadon = Look(
        name: "Celadon", isDark: false, field: .glaze,
        ground: 0xE0EAE2, raised: 0xFFFFFF, ink: 0x0C1E19, context: 0x3A6584, muted: 0x97ABA2, tess: 0x2C59BE,
        live: 0xD94B2E, liveInk: 0xB23A1F, now: 0xCF9418, health: 0x1F8B6A, training: 0xBF4664, neutral: 0x7E918A,
        sky: 0x86B8D4,
        sheen: 0xD99A1C, sheenOnLetters: true
    )

    /// White (sheet 213): a pure white page with accents tuned dark enough to read on it.
    static let white = Look(
        name: "White", isDark: false, field: .pigmentBloom,
        ground: 0xFFFFFF, raised: 0xECECEC, ink: 0x121212, context: 0x623AA4, muted: 0xB9B3C3, tess: 0x2450D8,
        live: 0xE2432A, liveInk: 0xC23A22, now: 0xF0A500, health: 0x12936A, training: 0xCC3F68, neutral: 0x9C95A8,
        sky: 0x7FB6E0,
        sheen: 0xF0A500, sheenOnLetters: true,
        accents: LookAccents(training: 0x9E1C3A, kitchen: 0x9A6212, routines: 0x9A4255, lists: 0x536016,
                             notes: 0x5E2EA8, money: 0x357059, skyFrom: 0xA85A18, skyTo: 0xA33C62),
        ink2: 0x54514D, ink3: 0x86827C
    )

    /// Black (sheet 213): true black with accents tuned bright enough to glow.
    static let black = Look(
        name: "Black", isDark: true, field: .emissive,
        ground: 0x000000, raised: 0x0F0E12, ink: 0xF4F1EC, context: 0xB7A6E0, muted: 0x5C5765, tess: 0x86B4FF,
        live: 0xFF5B3A, liveInk: 0xFF7A5C, now: 0xFFC23D, health: 0x3FD49A, training: 0xFF6B92, neutral: 0x8E879A,
        sky: 0x7FD6E8,
        accents: LookAccents(training: 0xCC4478, kitchen: 0xF4B25E, routines: 0xEBA2B2, lists: 0xC6CF82,
                             notes: 0xC6B7EE, money: 0x97CBB2, skyFrom: 0xFFB062, skyTo: 0xF286A6),
        ink2: 0xA3A09B, ink3: 0x6E6B67
    )

    static let all: [Look] = [.porcelain, .obsidian, .plein, .lacquer, .celadon, .white, .black]
    static let light: [Look] = [.porcelain, .plein, .celadon, .white]
    static let dark: [Look] = [.obsidian, .lacquer, .black]

    /// The VoiceOver hint and preview caption (docs/research/theme-names.md).
    var line: String {
        switch name {
        case "Porcelain": "Pure white. Colour pools only behind what matters now."
        case "Obsidian": "True black. Colour turns to light and glows."
        case "Plein": "Warm paper, flat, with earth pigments."
        case "Lacquer": "Black-red lacquer with one slow sheen that moves as you tilt."
        case "White": "Pure white, with accents deep enough to read on it."
        case "Black": "True black, with accents that glow."
        default: "Pale green glaze that pools darker at the foot of the page."
        }
    }

    static func named(_ name: String) -> Look? {
        all.first { $0.name.lowercased() == name.lowercased() }
    }
}

// MARK: - The choice

/// Which looks are on: one by day, one by night, or one pinned for both. Persisted; views that read a token inside
/// `body` redraw on a switch through Observation (a colour copied into a stored `let` won't).
@Observable
final class ThemeStore {
    nonisolated(unsafe) static let shared = ThemeStore(defaults: ThemeStore.sharedDefaults)

    /// The look lives in the App Group (verified on the free Personal Team, 2026-10-16), so widgets read the same
    /// choice. A choice saved before the group existed moves over once.
    static let appGroup = "group.com.kaushikaranagu.tessera"

    static var sharedDefaults: UserDefaults {
        guard let group = UserDefaults(suiteName: appGroup) else { return .standard }
        let standard = UserDefaults.standard
        for key in ["look.day", "look.night", "look.pinned"] where group.object(forKey: key) == nil {
            if let value = standard.string(forKey: key) {
                group.set(value, forKey: key)
            }
        }
        return group
    }

    /// Whether this phone's look was ever chosen (a restore applies a backup's look only when it wasn't).
    var wasEverChosen: Bool {
        defaults.object(forKey: Key.day) != nil || defaults.object(forKey: Key.night) != nil
    }

    /// A restored backup's look, applied only if this phone never chose one (theme-names.md, "backups").
    func adoptRestored(day: String?, night: String?, pinned: String?) {
        guard !wasEverChosen, let dayLook = day.flatMap(Look.named), let nightLook = night.flatMap(Look.named)
        else { return }
        self.day = dayLook
        self.night = nightLook
        self.pinned = pinned.flatMap(Look.named)
        save()
    }

    private(set) var day: Look
    private(set) var night: Look
    /// When set, this look holds day and night ("Obsidian always").
    private(set) var pinned: Look?
    /// `-theme <name>` (DEBUG): a pin for demos and recordings that is never saved, whatever else is tapped.
    private(set) var demoPin: Look?
    /// The workout keeps the look it opened in until it closes, so the appearance flipping mid-set can't change it
    /// (theme-schedule.md).
    private(set) var workoutHeld: Look?
    /// The system appearance (day is Light, night is Dark, whatever set it). Read from the trait before the first
    /// frame, then tracked from the root background.
    var systemIsDark: Bool {
        didSet {
            if oldValue != systemIsDark {
                rebuild()
            }
        }
    }

    /// The house concept in these looks (rebuilt on a change, read by `Theme.concept`).
    private(set) var concept: ThemeConcept = .plein

    private enum Key {
        static let day = "look.day"
        static let night = "look.night"
        static let pinned = "look.pinned"
    }

    private let defaults: UserDefaults

    init(
        defaults: UserDefaults = .standard,
        systemIsDark: Bool = UITraitCollection.current.userInterfaceStyle == .dark
    ) {
        self.defaults = defaults
        self.systemIsDark = systemIsDark
        // Porcelain by day, Obsidian by night, for everyone (Kaushik: white is his likely default; Plein is a tap
        // away in the sentence).
        day = defaults.string(forKey: Key.day).flatMap(Look.named) ?? .porcelain
        night = defaults.string(forKey: Key.night).flatMap(Look.named) ?? .obsidian
        pinned = defaults.string(forKey: Key.pinned).flatMap(Look.named)
        rebuild()
    }

    private func rebuild() {
        let (day, night) = pair
        concept = ThemeConcept.dressed(day: day, night: night, current: workoutHeld ?? current)
    }

    /// The pin in force: the demo's, else his.
    var pin: Look? {
        demoPin ?? pinned
    }

    /// The look the paint tokens (halo, blends, bloom, sheen, glows) resolve against: while the workout is open its
    /// look is held, so its pages paint in that look; otherwise the look on screen (one base across the app).
    var paintLook: Look {
        workoutHeld ?? current
    }

    /// The workout's look: the one it opened in while it's open, else the one on screen.
    var workoutLook: Look {
        workoutHeld ?? current
    }

    /// The look on screen now.
    var current: Look {
        pin ?? (systemIsDark ? night : day)
    }

    /// Day and night as the two halves of every dynamic colour.
    var pair: (day: Look, night: Look) {
        pin.map { ($0, $0) } ?? (day, night)
    }

    /// Tap a name: the next light look by day, the next dark look by night.
    func cycleDay() {
        day = Self.next(after: day, in: Look.light)
        save()
    }

    func cycleNight() {
        night = Self.next(after: night, in: Look.dark)
        save()
    }

    /// The day or night name stepped back (VoiceOver's decrement).
    func cycleDayBack() {
        day = Self.next(after: day, in: Look.light.reversed())
        save()
    }

    func cycleNightBack() {
        night = Self.next(after: night, in: Look.dark.reversed())
        save()
    }

    /// A pinned name steps through all seven looks, light and dark.
    func cyclePinned(forward: Bool = true) {
        if let demoPin {
            self.demoPin = Self.next(after: demoPin, in: forward ? Look.all : Look.all.reversed())
            return rebuild()
        }
        guard let pinned else { return }
        self.pinned = Self.next(after: pinned, in: forward ? Look.all : Look.all.reversed())
        save()
    }

    /// Hold a name to pin it; hold again to unpin, and the look goes back into its own slot (a dark look by night,
    /// a light one by day), the other slot as it was.
    func togglePin(_ look: Look) {
        if demoPin == look {
            demoPin = nil
            return rebuild()
        }
        if pinned == look {
            pinned = nil
            if look.isDark {
                night = look
            } else {
                day = look
            }
        } else {
            pinned = look
        }
        save()
    }

    /// `-theme <name>` (DEBUG): pins in memory only.
    func pin(_ look: Look) {
        demoPin = look
        rebuild()
    }

    /// The workout opens: hold its palette until it closes.
    func holdWorkoutLook() {
        workoutHeld = current
        rebuild()
    }

    func releaseWorkoutLook() {
        workoutHeld = nil
        rebuild()
    }

    private func save() {
        rebuild()
        // During a -theme demo nothing is written: taps stay in memory.
        guard demoPin == nil else { return }
        defaults.set(day.name, forKey: Key.day)
        defaults.set(night.name, forKey: Key.night)
        defaults.set(pinned?.name, forKey: Key.pinned)
    }

    private static func next(after look: Look, in looks: [Look]) -> Look {
        let index = looks.firstIndex(of: look) ?? -1
        return looks[(index + 1) % looks.count]
    }
}
