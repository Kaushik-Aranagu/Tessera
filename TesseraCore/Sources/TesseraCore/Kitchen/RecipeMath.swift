import Foundation

/// Recipe sizes (kitchen slice 4). Nothing is stored: a cook remembers the size it used.
public enum RecipeMath {
    /// The lines at a new size, rounded the way you'd measure: whole eggs and onions, grams and millilitres to 1 under
    /// 10, 5 under 100 and 10 above, spoons to a half, cups to a quarter. "To taste" lines don't change.
    public static func scaled(_ lines: [IngredientLine], from serves: Int, to target: Int) -> [IngredientLine] {
        guard serves > 0, target > 0, serves != target else { return lines }
        let factor = Double(target) / Double(serves)
        return lines.map { line in
            guard !line.toTaste, let amount = line.amount else { return line }
            var scaled = line
            scaled.amount = round(amount * factor, unit: line.unit)
            scaled.amountMax = line.amountMax.map { round($0 * factor, unit: line.unit) }
            return scaled
        }
    }

    static func round(_ value: Double, unit: KitchenUnit?) -> Double {
        switch unit {
        case .gram, .millilitre:
            let step: Double = value < 10 ? 1 : value < 100 ? 5 : 10
            return max(step, (value / step).rounded() * step)
        case .kilogram, .litre:
            return max(0.05, (value * 20).rounded() / 20)
        case .teaspoon, .tablespoon:
            return max(0.5, (value * 2).rounded() / 2)
        case .cup:
            return max(0.25, (value * 4).rounded() / 4)
        case nil, .clove, .pinch, .handful, .bunch, .can, .slice, .sprig, .piece, .stick, .head:
            return max(1, value.rounded())
        }
    }
}

public extension IngredientLine {
    /// The amount as you'd write it: "2", "1½", "2–3", "0.5" for kilos. Nil with no amount.
    var amountText: String? {
        guard let amount else { return nil }
        let low = Self.kitchenNumber(amount, unit: unit)
        guard let amountMax, amountMax != amount else { return low }
        return "\(low)–\(Self.kitchenNumber(amountMax, unit: unit))"
    }

    /// "200 g", "1½ tbsp", "2 cloves", "2" (an onion has no unit), nil for "to taste".
    var quantityText: String? {
        guard let text = amountText else { return nil }
        guard let unit else { return text }
        let plural = (amountMax ?? amount ?? 1) > 1
        let word = switch unit {
        case .clove, .pinch, .handful, .bunch, .can, .slice, .sprig, .piece, .stick, .head, .cup:
            plural ? (unit == .bunch || unit == .pinch ? "\(unit.rawValue)es" : "\(unit.rawValue)s") : unit.rawValue
        default: unit.rawValue
        }
        return "\(text) \(word)"
    }

    static func kitchenNumber(_ value: Double, unit: KitchenUnit?) -> String {
        let whole = value.rounded(.down)
        let fraction = value - whole
        let glyph: String? = switch fraction {
        case 0.24 ... 0.26: "¼"
        case 0.49 ... 0.51: "½"
        case 0.74 ... 0.76: "¾"
        default: nil
        }
        if unit != .kilogram, unit != .litre, let glyph {
            return whole == 0 ? glyph : "\(Int(whole))\(glyph)"
        }
        return value.formatted(.number.precision(.fractionLength(0 ... 2)))
    }
}
