import Foundation

/// Money and Reading show only when areas are shown: the Review switch "Areas shown" set to "All". The row turns
/// live later; until then this is off, so no Money or Reading line appears anywhere (today's behavior).
///
/// This branch is cut from Core's `core/reading`, which predates `ReviewChoices`. Once it meets master, the body
/// becomes `ReviewChoices.shared.value(of: "areasShown") == "All"`. Until then it reads the same kept value the
/// switch writes ("review.areasShown"); a switch that isn't live never writes it, so this stays off. Under `-demo`
/// the switch keeps nothing, so this is off there too. `-areasAll` (simulator only) shows them for recordings.
enum AreasShown {
    static var isOn: Bool {
        if LaunchFlags.has("-areasAll") {
            return true
        }
        guard !LaunchFlags.has("-demo") else { return false }
        return UserDefaults.standard.string(forKey: "review.areasShown") == "All"
    }
}
