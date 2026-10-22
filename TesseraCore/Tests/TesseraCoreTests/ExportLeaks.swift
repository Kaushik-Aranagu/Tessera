import Foundation

/// Looks for a private value in an export the way a reader would: as a value, not as a run of characters. The export
/// writes dates as ISO text with fractional seconds ("2026-10-22T16:10:12.404Z"), so a plain `contains("12.40")` fails
/// about once in a hundred runs when a timestamp happens to read that way. Date strings are skipped; every other
/// string value, every key and every number is checked.
enum ExportLeaks {
    /// The needles found as values (or inside non-date strings) anywhere in the JSON.
    static func found(_ needles: [String], numbers: [Double] = [], in data: Data) throws -> [String] {
        let tree = try JSONSerialization.jsonObject(with: data)
        var hits: [String] = []
        func walk(_ node: Any) {
            if let map = node as? [String: Any] {
                for (key, value) in map {
                    check(key)
                    walk(value)
                }
            } else if let list = node as? [Any] {
                list.forEach(walk)
            } else if let text = node as? String {
                check(text)
            } else if let number = node as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
                      numbers.contains(number.doubleValue)
            {
                hits.append("\(number)")
            }
        }
        func check(_ text: String) {
            guard text.range(of: #"^\d{4}-\d{2}-\d{2}T"#, options: .regularExpression) == nil else { return }
            hits += needles.filter { text.localizedCaseInsensitiveContains($0) }
        }
        walk(tree)
        return hits
    }
}
