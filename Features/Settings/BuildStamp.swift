import Foundation

/// The short git SHA the running build was made from, so a glance at the phone says which release it is. Stamped by
/// the release scripts through the `TESSERA_BUILD_SHA` build setting (Info.plist key `TesseraBuildSHA`); a build made
/// any other way reads "dev".
enum BuildStamp {
    static var short: String {
        normalised(Bundle.main.infoDictionary?["TesseraBuildSHA"] as? String)
    }

    /// Seven hex characters at most, or "dev" when nothing sensible was stamped (including an unresolved setting).
    static func normalised(_ raw: String?) -> String {
        guard let raw else { return "dev" }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isHex = !trimmed.isEmpty && trimmed.allSatisfy(\.isHexDigit)
        return isHex ? String(trimmed.prefix(7)) : "dev"
    }
}
