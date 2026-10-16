import Observation
import SwiftUI
import UIKit

// MARK: - Looks

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

    struct Workout: Sendable, Equatable {
        var ground: UInt32
        var raised: UInt32
        var ink: UInt32
        var signal: UInt32
        var rest: UInt32
        var tess: UInt32
        var health: UInt32
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
    var workout: Workout

    var id: String {
        name
    }

    static let porcelain = Look(
        name: "Porcelain", isDark: false, field: .pigmentBloom,
        ground: 0xFFFFFF, raised: 0xF5F4F8, ink: 0x17141F, context: 0x6A4C9C, muted: 0xB9B3C3, tess: 0x2450D8,
        live: 0xE2432A, liveInk: 0xC23A22, now: 0xF0A500, health: 0x12936A, training: 0xCC3F68, neutral: 0x9C95A8,
        sky: 0x7FB6E0,
        workout: Workout(ground: 0x14111A, raised: 0x221D2C, ink: 0xF5F2EC, signal: 0xFF5B3A, rest: 0xF0A500,
                         tess: 0x8FB0FF, health: 0x3FC58F)
    )

    static let obsidian = Look(
        name: "Obsidian", isDark: true, field: .emissive,
        ground: 0x000000, raised: 0x0F0E12, ink: 0xF5F2EC, context: 0xB7A6E0, muted: 0x5C5765, tess: 0x86B4FF,
        live: 0xFF5B3A, liveInk: 0xFF7A5C, now: 0xFFC23D, health: 0x3FD49A, training: 0xFF6B92, neutral: 0x8E879A,
        sky: 0x7CC4F0,
        workout: Workout(ground: 0x000000, raised: 0x141217, ink: 0xF5F2EC, signal: 0xFF5B3A, rest: 0xFFC23D,
                         tess: 0x86B4FF, health: 0x3FD49A)
    )

    static let plein = Look(
        name: "Plein", isDark: false, field: .plein,
        ground: 0xF2ECE3, raised: 0xFAF6EF, ink: 0x2B2440, context: 0x7A5C8E, muted: 0xA39AAE, tess: 0x2A64A0,
        live: 0xC8452F, liveInk: 0xB83C28, now: 0xE0B341, health: 0x6E9E6A, training: 0x6E9E6A, neutral: 0xA39AAE,
        sky: 0x9EC3D6,
        workout: Workout(ground: 0x1C1828, raised: 0x3B2D57, ink: 0xF3ECE0, signal: 0xD9563F, rest: 0xE8BD4C,
                         tess: 0x9DBFE6, health: 0x7FB07A)
    )

    static let lacquer = Look(
        name: "Lacquer", isDark: true, field: .lacquer,
        ground: 0x140F1B, raised: 0x221A2D, ink: 0xF1E7D6, context: 0xC3A6DE, muted: 0x6C6078, tess: 0x8DB2FF,
        live: 0xF06A4C, liveInk: 0xFF8466, now: 0xE8B54A, health: 0x8FCB9E, training: 0xF07FA0, neutral: 0x9A8FA6,
        sky: 0x9DBCD6,
        workout: Workout(ground: 0x0C0812, raised: 0x1C1426, ink: 0xF1E7D6, signal: 0xF06A4C, rest: 0xE8B54A,
                         tess: 0x8DB2FF, health: 0x8FCB9E)
    )

    static let celadon = Look(
        name: "Celadon", isDark: false, field: .glaze,
        ground: 0xE7EEE9, raised: 0xFFFFFF, ink: 0x0F231D, context: 0x456680, muted: 0x97ABA2, tess: 0x2C59BE,
        live: 0xD8462C, liveInk: 0xB8361E, now: 0xD99A1C, health: 0x23866A, training: 0xC24766, neutral: 0x7E918A,
        sky: 0x8DBBD6,
        workout: Workout(ground: 0x0E1C17, raised: 0x18302A, ink: 0xEEF3EF, signal: 0xEE7056, rest: 0xE2A93A,
                         tess: 0x9DBBEA, health: 0x5DBE98)
    )

    static let all: [Look] = [.porcelain, .obsidian, .plein, .lacquer, .celadon]
    static let light: [Look] = [.porcelain, .plein, .celadon]
    static let dark: [Look] = [.obsidian, .lacquer]

    /// The VoiceOver hint and preview caption (docs/research/theme-names.md).
    var line: String {
        switch name {
        case "Porcelain": "Pure white. Colour pools only behind what matters now."
        case "Obsidian": "True black. Colour turns to light and glows."
        case "Plein": "Warm paper with soft washes and grain, painted outdoors."
        case "Lacquer": "Plum black with one slow sheen that moves as you tilt."
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
    nonisolated(unsafe) static let shared = ThemeStore()

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

    /// A pinned name steps through all five looks, light and dark.
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
