import Foundation

/// Low Power Mode, read in one place (Coordinator ruling on #945): screens that slow their motion or timers in Low
/// Power ask here rather than reading the process info themselves, so the read is one reviewed line.
enum PowerState {
    static var isLowPower: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}
