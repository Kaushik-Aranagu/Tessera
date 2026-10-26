import CoreText
import Foundation

/// Registers the bundled variable fonts (all SIL OFL 1.1; licenses in Resources/Fonts).
enum FontRegistry {
    private static let files = [
        "BricolageGrotesque-Variable",
        "InstrumentSans-Variable",
        "InstrumentSans-Italic-Variable",
        "MartianMono-Variable",
        "InterTight-Variable",
        "Figtree-Variable",
        "Outfit-Variable",
        "Newsreader-Variable",
        "BarlowCondensed-SemiBold",
        "IBMPlexSansCondensed-Regular",
        "IBMPlexSansCondensed-Medium",
        "IBMPlexSansCondensed-Bold",
    ]

    static func registerAll() {
        for name in files {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                assertionFailure("Missing font \(name).ttf")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
