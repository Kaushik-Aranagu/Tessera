import Foundation

/// A versioned bundle of classes (built-ins now; app packages and imports such as a wger exercise set later).
/// Every class it installs records the package and version, so upgrades can apply underneath the person's edits.
public struct CatalogPackage: Hashable, Sendable {
    public let id: String
    public let version: Int
    public let name: String
    /// Where the content comes from, and its license, kept per package for attribution.
    public let source: String
    public let license: String
}

public extension ClassDef {
    /// Marks a shipped class as edited by the person, so package upgrades keep their changes.
    func markUserModified() {
        isUserModified = true
    }
}

public extension FieldDef {
    /// Marks a shipped field as edited by the person, so package upgrades keep their changes.
    func markUserModified() {
        isUserModified = true
    }
}
