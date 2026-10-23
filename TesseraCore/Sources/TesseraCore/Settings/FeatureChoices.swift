import Foundation

/// Where two features do the same job, they are one choice, not two switches (sheet 203): choosing one turns the other
/// off. Each option is a name and what it sets: flags On or Off, and values for the switches with more than two. The
/// app shows the options as words with the chosen one underlined; this is only the data and the rule.
public struct FeatureChoice: Equatable, Sendable, Identifiable {
    public struct Option: Equatable, Sendable, Identifiable {
        public let id: String
        public let name: String
        /// Flags this option needs On, or Off.
        public let flags: [String: Bool]
        /// Values of the switches with more than two (the app's ReviewChoices ids).
        public let values: [String: String]
    }

    public let id: String
    /// The line as a sentence, with its value on the right: "Home is", "Pages turn by".
    public let sentence: String
    public let options: [Option]
    /// Which option reads when the stored state matches none (an older install, or a flag turned off by hand).
    public let defaultOption: String
}

/// What a person's settings amount to: the flags he turned Off, and the values of the switches with more than two.
public struct FeatureState: Equatable, Sendable {
    public var off: Set<String>
    public var values: [String: String]

    public init(off: Set<String> = [], values: [String: String] = [:]) {
        self.off = off
        self.values = values
    }
}

public enum FeatureChoices {
    public static let all: [FeatureChoice] = [
        FeatureChoice(
            id: "homeIs", sentence: "Home is",
            options: [
                .init(id: "mosaic", name: "Mosaic",
                      flags: ["homeMosaic": true, "homeMosaicMoods": true, "homeMosaicMoments": true,
                              "homeV2": false],
                      values: [:]),
                .init(id: "homeV2", name: "Home v2",
                      flags: ["homeV2": true, "homeMosaic": false, "homeMosaicMoods": false,
                              "homeMosaicMoments": false],
                      values: [:]),
            ],
            defaultOption: "mosaic"
        ),
        // The reading layout is folded in: the three turns come with the refit type sizes, Today keeps today's.
        FeatureChoice(
            id: "pagesTurnBy", sentence: "Pages turn by",
            options: [
                .init(
                    id: "slide",
                    name: "Slide",
                    flags: [:],
                    values: ["pageTurn": "Slide", "readingLayout": "Sheet 99"]
                ),
                .init(id: "turn", name: "Turn", flags: [:], values: ["pageTurn": "Turn", "readingLayout": "Sheet 99"]),
                .init(
                    id: "rotate",
                    name: "Rotate",
                    flags: [:],
                    values: ["pageTurn": "Rotate", "readingLayout": "Sheet 99"]
                ),
                .init(id: "today", name: "Today", flags: [:], values: ["pageTurn": "Today", "readingLayout": "Today"]),
            ],
            defaultOption: "today"
        ),
    ]

    /// What a new install starts from: every flag On, and each choice at its default option (so the loser of a conflict
    /// starts Off). The stored state is this plus whatever he changed.
    public static var shipped: FeatureState {
        var state = FeatureState()
        for choice in all {
            state = choosing(choice.defaultOption, in: choice.id, state: state)
        }
        return state
    }

    public static func choice(_ id: String) -> FeatureChoice? {
        all.first { $0.id == id }
    }

    /// The option that reads now: the first whose flags and values all hold, else the default.
    public static func selected(_ choiceID: String, in state: FeatureState) -> FeatureChoice.Option? {
        guard let choice = choice(choiceID) else { return nil }
        return choice.options.first { matches($0, state) }
            ?? choice.options.first { $0.id == choice.defaultOption }
    }

    private static func matches(_ option: FeatureChoice.Option, _ state: FeatureState) -> Bool {
        option.flags.allSatisfy { state.off.contains($0.key) != $0.value }
            && option.values.allSatisfy { state.values[$0.key] == $0.value }
    }

    /// Choosing an option sets what it names and so turns the other off. Anything that is not a choice or an option
    /// changes nothing.
    public static func choosing(_ optionID: String, in choiceID: String, state: FeatureState) -> FeatureState {
        guard let option = choice(choiceID)?.options.first(where: { $0.id == optionID }) else { return state }
        var next = state
        for (flag, on) in option.flags {
            next.off = FeatureFlags.setting(flag, on: on, off: next.off)
        }
        for (id, value) in option.values {
            next.values[id] = value
        }
        return next
    }
}
