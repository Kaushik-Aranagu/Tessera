import Foundation

/// Low Power Mode, read in one place (Coordinator ruling on #945): screens that slow their motion or timers in Low
/// Power ask here rather than reading the process info themselves, so the read is one reviewed line.
enum PowerState {
    /// Fires when Low Power turns on or off; ask `isLowPower` again when it does. Kept here so this stays the one
    /// file that names the process info.
    static var changes: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
    }

    static var isLowPower: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}
