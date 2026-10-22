import Foundation

/// Small word rules shared by the sentences (plural agreement), so no two templates guess differently.
public enum HouseWords {
    /// "Beans", "Potatoes" and "Mashed potatoes" agree as plurals ("start", "are"); "Rice", "Hummus", "Couscous",
    /// "Asparagus" and "Grass" do not. Only the last word counts. A caller that knows better passes its own answer.
    public static func isPlural(_ name: String) -> Bool {
        let last = name.split(separator: " ").last.map { $0.lowercased() } ?? ""
        return last.count > 2 && last.hasSuffix("s") && !["ss", "us", "is"].contains { last.hasSuffix($0) }
    }
}
