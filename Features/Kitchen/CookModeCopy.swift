import Foundation
import TesseraCore

/// Cook mode's words and sizes, ruled final by Product (Oct 17, 4:52; kitchen-cook-mode-accessibility-acceptance.md
/// K84). A pure formatter, so the cook-mode view only lays them out. Timer labels are his own words ("Simmer"); a
/// private recipe is only ever "Private recipe".
enum CookModeCopy {
    /// The bottom bar before the last step, and its hint (K84.9).
    static let next = "Next"
    static let nextHint = "Next step"
    /// The bottom bar on the last step: hold to finish, never a tap (K84.6, K84.14, K84.26).
    static let done = "Done"
    static let finishHint = "Hold to finish"
    /// VoiceOver's named action on the bar, for anyone who can't hold (K84.26).
    static let finishAction = "Finish"

    /// The heading: "Weeknight dal, cooking" (K84.20).
    static func heading(recipe: String, lastWeightKg: Double?) -> String {
        "\(name(recipe, lastWeightKg: lastWeightKg)), cooking"
    }

    /// "Step 2 of 6" (K84.20, K84.21).
    static func step(_ index: Int, of count: Int) -> String {
        "Step \(index + 1) of \(count)"
    }

    /// A timer reaching zero, announced once: "Simmer is done." (K84.22).
    static func timerDone(_ label: String) -> String {
        "\(label) is done."
    }

    /// The finished timer's own line, with its Stop action beside it: "Simmer, done." (K84.22).
    static func timerDoneLine(_ label: String) -> String {
        "\(label), done."
    }

    /// Stopping a timer: "Simmer stopped." with UNDO (K84.7, K84.15).
    static func timerStopped(_ label: String) -> String {
        "\(label) stopped."
    }

    /// UNDO of a stop: "Simmer, back." (K84.24).
    static func timerBack(_ label: String) -> String {
        "\(label), back."
    }

    /// A running timer read aloud, durations in words: "Simmer, 8 minutes left." (K84.20, K41.12).
    static func timeLeft(_ label: String, seconds: TimeInterval) -> String {
        "\(label), \(duration(seconds)) left."
    }

    /// "8 minutes", "1 minute", "1 hour 5 minutes", "under a minute".
    static func duration(_ seconds: TimeInterval) -> String {
        let minutes = Int((seconds / 60).rounded(.up))
        guard seconds >= 60 else { return seconds > 0 ? "under a minute" : "0 minutes" }
        let hours = minutes / 60, rest = minutes % 60
        func unit(_ count: Int, _ word: String) -> String {
            "\(count) \(word)\(count == 1 ? "" : "s")"
        }
        if hours == 0 {
            return unit(rest, "minute")
        }
        return rest == 0 ? unit(hours, "hour") : "\(unit(hours, "hour")) \(unit(rest, "minute"))"
    }

    /// Every cook-mode target is at least 64 pt, 88 pt from AX1 up (K84 setup, K84.9).
    static func minTarget(accessibilitySize: Bool) -> CGFloat {
        accessibilitySize ? 88 : 64
    }

    private static func name(_ recipe: String, lastWeightKg: Double?) -> String {
        ObjectPrivacy.isPrivateRecipeTitle(recipe, lastWeightKg: lastWeightKg) ? ObjectPrivacy.recipeLabel : recipe
    }
}
