import Foundation

/// The information sheet 325 adds to the Galley's modes, as pure functions: the heat and the doneness cue for a
/// cooking step (read from the step's own words, else from its verb), and where an aisle is and how to pick a thing
/// for shopping. Generic defaults: a store's real layout is not known, so the aisle notes are the usual ones.
enum GalleyCues {
    // MARK: Cooking

    /// "Medium high" when the step says it, else the usual heat for its verb; nil when neither is known.
    static func heat(_ step: String) -> String? {
        let lower = step.lowercased().replacingOccurrences(of: "-", with: " ")
        for (needle, label) in [("medium high", "Medium high"), ("medium low", "Medium low"), ("high heat", "High"),
                                ("low heat", "Low"), ("medium heat", "Medium"), ("over high", "High"),
                                ("over low", "Low"), ("over medium", "Medium")]
        {
            if lower.contains(needle) {
                return label
            }
        }
        let verb = firstVerb(lower)
        switch verb {
        case "sear", "char", "brown", "fry", "saute", "sauté", "toast": return "Medium high"
        case "simmer", "soften", "sweat", "reduce", "warm": return "Low"
        case "boil": return "High"
        case "stir", "fold", "mix", "serve", "rest", "chop", "slice", "season", "whisk": return nil
        default: return nil
        }
    }

    /// What tells you it is done, by verb: "Turn it when it lets go of the pan".
    static func doneness(_ step: String) -> String? {
        switch firstVerb(step.lowercased()) {
        case "brown", "sear": "Turn it when it lets go of the pan"
        case "char": "Leave it until it blisters and darkens at the edges"
        case "soften", "sweat": "Ready when it goes soft and clear"
        case "saute", "sauté", "fry": "Ready when it is golden at the edges"
        case "simmer", "reduce": "Ready when it coats the back of a spoon"
        case "boil": "Ready at a rolling boil"
        case "toast": "Ready when it smells nutty"
        case "bake", "roast": "Ready when it is golden and sizzling"
        case "rest": "Leave it be so the juices settle"
        case "season": "Taste, then add a pinch more"
        case "serve": "Plate it while it is hot"
        default: nil
        }
    }

    private static func firstVerb(_ lower: String) -> String {
        lower.split(whereSeparator: { !$0.isLetter }).first.map(String.init) ?? ""
    }

    // MARK: Shopping

    /// Where the aisle usually is, from its name.
    static func aisleSpot(_ aisle: String) -> String? {
        switch aisle.lowercased() {
        case "produce": "Right by the doors"
        case "bakery": "Near the doors, by the ovens"
        case "dairy and eggs", "dairy": "Along the back wall"
        case "meat and seafood", "meat": "At the back, by the counter"
        case "frozen": "Down the middle, in the cases"
        case "cans and jars", "pantry", "spices": "In the middle aisles"
        case "household": "At the far end"
        default: nil
        }
    }

    /// How to pick a thing, by its name.
    static func pick(_ item: String) -> String? {
        let lower = item.lowercased()
        func has(_ words: [String]) -> Bool {
            words.contains { lower.contains($0) }
        }
        if has(["avocado", "peach", "pear", "mango", "plum", "tomato", "banana"]) {
            return "Pick ones that give a little"
        }
        if has(["milk", "yogurt", "yoghurt", "cream", "butter", "cheese", "egg"]) {
            return "The date furthest out is at the back"
        }
        if has(["melon", "squash", "pineapple"]) {
            return "Pick one that feels heavy for its size"
        }
        if has(["lime", "lemon", "orange"]) {
            return "Pick firm ones with a thin, glossy skin"
        }
        if has(["onion", "garlic", "potato"]) {
            return "Pick firm ones with no soft spots"
        }
        if has(["lettuce", "spinach", "herb", "cilantro", "parsley", "basil", "kale"]) {
            return "Pick crisp leaves with no wilting"
        }
        if has(["chicken", "beef", "pork", "fish", "salmon", "meat"]) {
            return "Pick the latest date and cold to the touch"
        }
        return nil
    }
}
