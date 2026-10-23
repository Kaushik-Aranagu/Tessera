import SwiftUI

// CLOUD-WRITTEN, NOT COMPILED. Small helpers the Notes, Lists and Money landings share, on top of Builder B's
// `LandingPage` frame (LandingPage.swift). Nothing here draws a frame.

/// Each app's accent, from the Theme tokens (design 131 table). Kitchen's is `KitchenFront.accent`.
enum LandingAccent {
    static var money: Color {
        Theme.Colors.Accent.money
    }

    static var notes: Color {
        Theme.Colors.Accent.notes
    }

    static var lists: Color {
        Theme.Colors.Accent.lists
    }
}

/// A sentence with its one key word, for pages whose words come from the app (Core's `LandingSentence` cannot be
/// built outside Core). `text(accent:)` is the same drawing as `LandingText.build`.
struct AccentedSentence: Equatable {
    let text: String
    let key: String?

    func attributed(accent: Color) -> AttributedString {
        var result = AttributedString(text)
        if let key, let range = result.range(of: key) {
            result[range].foregroundColor = accent
        }
        return result
    }
}

/// "A, B, and C" / "A and B" / "A": the house comma list with "and".
enum LandingList {
    static func joined(_ names: [String]) -> String {
        switch names.count {
        case 0: ""
        case 1: names[0]
        case 2: "\(names[0]) and \(names[1])"
        default: names.dropLast().joined(separator: ", ") + ", and " + names[names.count - 1]
        }
    }
}

/// When a landing was last looked at, kept on this phone only (UserDefaults), like `ReviewChoices`. Never in the op
/// log, a backup, a log or a widget.
enum LandingSeen {
    static func date(_ id: String, defaults: UserDefaults = .standard) -> Date? {
        let value = defaults.double(forKey: "landing.seen.\(id)")
        return value > 0 ? Date(timeIntervalSince1970: value) : nil
    }

    static func mark(_ id: String, at date: Date, defaults: UserDefaults = .standard) {
        defaults.set(date.timeIntervalSince1970, forKey: "landing.seen.\(id)")
    }
}
