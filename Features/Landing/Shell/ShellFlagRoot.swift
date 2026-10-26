import SwiftUI

/// The simulator's way into the standing shell: `-shell` opens the Log through it. LaunchFlags is simulator-only, so
/// it never reaches the phone. (Layout mode is its own feature in Features/LayoutMode, opened from Settings.)
struct ShellFlagRoot: View {
    static var isAsked: Bool {
        LaunchFlags.has("-shell")
    }

    var body: some View {
        NotesShellHost()
    }
}
