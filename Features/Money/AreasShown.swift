import Foundation

/// Money and Reading show only when areas are shown: the Review switch "Areas shown" set to "All". The row turns
/// live later; until then it reads its default ("Today's"), so no Money or Reading line appears anywhere (today's
/// behavior). `-areasAll` (simulator only) shows them for recordings and walks.
@MainActor
enum AreasShown {
    static var isOn: Bool {
        LaunchFlags.has("-areasAll") || ReviewChoices.shared.value(of: "areasShown") == "All"
    }
}
