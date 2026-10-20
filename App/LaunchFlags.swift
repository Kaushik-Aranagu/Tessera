import Foundation

/// Every launch argument for demos, recordings and tests reads through here, and here they exist only on the
/// simulator (docs/research/debug-paths.md): the build that goes on his phone from Xcode is a Debug build, so
/// `#if DEBUG` can't keep a ticked argument away from his real data.
enum LaunchFlags {
    /// True only on the simulator.
    nonisolated static var allowed: Bool {
        #if targetEnvironment(simulator)
            true
        #else
            false
        #endif
    }

    /// Whether `flag` was passed, on the simulator.
    nonisolated static func has(_ flag: String,
                                in arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool
    {
        allowed && arguments.contains(flag)
    }

    /// The value after `flag` ("-demoTime 18:10"), on the simulator.
    nonisolated static func value(after flag: String,
                                  in arguments: [String] = ProcessInfo.processInfo.arguments) -> String?
    {
        guard allowed, let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1)
        else { return nil }
        return arguments[index + 1]
    }
}

// Note: the Watch app's -demoSet / -demoRest / -demoPrivate flags (Watch/WatchStore.swift) read CommandLine directly
// instead of through here, in a #if targetEnvironment(simulator) block, so they can never run on a real watch.
