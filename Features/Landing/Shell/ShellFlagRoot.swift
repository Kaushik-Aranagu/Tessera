import SwiftUI

/// The simulator's way into the standing shell: `-shell` opens the Log through it. LaunchFlags is simulator-only, so
/// it never reaches the phone. (Layout mode is its own feature in Features/LayoutMode, opened from Settings.)
struct ShellFlagRoot: View {
    static var isAsked: Bool {
        LaunchFlags.has("-shell") || LaunchFlags.value(after: "-shellRoom") != nil
    }

    /// `-shellRoom deck` (simulator only) opens that room through the shell; the Log otherwise.
    var body: some View {
        if let room = LaunchFlags.value(after: "-shellRoom"), let host = ShellRooms.host(for: room) {
            host
        } else {
            NotesShellHost()
        }
    }
}
