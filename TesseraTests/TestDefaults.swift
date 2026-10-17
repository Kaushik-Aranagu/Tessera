import Foundation

extension UserDefaults {
    /// One throwaway suite for the app tests' launch decisions (QA on #665): wiped each time it's handed out, so its
    /// plist never piles up and no test sees another's decision.
    static func testSuite() -> UserDefaults {
        let name = "com.kaushikaranagu.tessera.app-tests"
        UserDefaults().removePersistentDomain(forName: name)
        return UserDefaults(suiteName: name) ?? .standard
    }
}
