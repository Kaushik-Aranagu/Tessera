import AppIntents
import Foundation

/// What the rest Live Activity's buttons ask the running workout to do.
enum RestAction: Sendable {
    /// Log the planned set, exactly like hold to log.
    case logPlannedSet
    /// Add 15 seconds to the rest.
    case extendRest
    /// End the rest now.
    case skipRest
    /// Once rest is over: skip the planned set.
    case skipSet
}

/// Hands rest actions from the intents to the live workout. The intents are compiled into both the app and the widget
/// extension (the extension needs the types for `Button(intent:)`), but a `LiveActivityIntent` always performs in the
/// app process, where the app installs `handler` at launch (see `LiveWorkout`). In the extension it stays nil.
@MainActor
enum RestIntentRelay {
    static var handler: ((RestAction) async -> Void)?

    static func perform(_ action: RestAction) async {
        await handler?(action)
    }
}

/// Done: logs the planned set, the same action as hold to log.
struct LogPlannedSetIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Log Planned Set"
    static let description = IntentDescription("Logs the planned set of the running workout.")
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await RestIntentRelay.perform(.logPlannedSet)
        return .result()
    }
}

/// +15s on the rest.
struct ExtendRestIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Add 15 Seconds of Rest"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await RestIntentRelay.perform(.extendRest)
        return .result()
    }
}

/// Ends the rest now.
struct SkipRestIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Skip Rest"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await RestIntentRelay.perform(.skipRest)
        return .result()
    }
}

/// Skip once rest is over: skips the planned set.
struct SkipSetIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Skip Set"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await RestIntentRelay.perform(.skipSet)
        return .result()
    }
}
