import Foundation

/// What he may say right now, built from the names the screen shows. It primes the recogniser and then pulls a
/// transcript back onto those names ("romanian dead lift" onto "RDL" or "Romanian deadlift"). Pure text, no audio.
public struct VoiceLexicon: Sendable, Equatable {
    public struct Entry: Sendable, Equatable {
        public var name: String
        /// Where it came from, so the focused thing outranks the rest.
        public var boost: Double
        let key: String

        init(name: String, boost: Double) {
            self.name = name
            self.boost = boost
            key = VoiceLexicon.fold(name)
        }
    }

    public private(set) var entries: [Entry]

    public init(names: [(name: String, boost: Double)] = []) {
        var seen: Set<String> = []
        entries = names.compactMap { item in
            let entry = Entry(name: item.name, boost: item.boost)
            return !entry.key.isEmpty && seen.insert(entry.key).inserted ? entry : nil
        }
    }

    /// Strings to hand the recogniser as context, most useful first, capped so the list stays short.
    public func contextualStrings(limit: Int = 200) -> [String] {
        Array(entries.sorted { $0.boost > $1.boost }.prefix(limit).map(\.name))
    }

    /// Lowercase, letters and digits only, one space between words.
    static func fold(_ text: String) -> String {
        text.lowercased().split { !($0.isLetter || $0.isNumber) }.joined(separator: " ")
    }

    /// Replaces any run of words in `transcript` that sounds like an entry with the entry itself. A run is 1 to 4 words;
    /// it matches when it is within a small edit distance of the entry (or of the entry with spaces removed, so
    /// "dead lift" finds "deadlift"). The longest, closest, most boosted match wins; exact words are left alone.
    public func resolve(_ transcript: String) -> String {
        let words = transcript.split(separator: " ").map(String.init)
        guard !words.isEmpty, !entries.isEmpty else { return transcript }
        var out: [String] = []
        var index = 0
        while index < words.count {
            var best: (length: Int, entry: Entry, score: Double)?
            for length in stride(from: min(4, words.count - index), through: 1, by: -1) {
                let run = words[index ..< index + length].joined(separator: " ")
                let heard = Self.fold(run)
                for entry in entries {
                    guard let closeness = Self.closeness(heard, entry.key), closeness > 0 else { continue }
                    let score = closeness + entry.boost * 0.01 + Double(length) * 0.001
                    if best == nil || score > best!.score {
                        best = (length, entry, score)
                    }
                }
                if best != nil { break }
            }
            if let best {
                out.append(best.entry.name)
                index += best.length
            } else {
                out.append(words[index])
                index += 1
            }
        }
        return out.joined(separator: " ")
    }

    /// 1 for an exact match, less for a near one, nil when too far. Short names must match exactly.
    static func closeness(_ heard: String, _ key: String) -> Double? {
        if heard == key { return 1 }
        let squashedHeard = heard.replacingOccurrences(of: " ", with: "")
        let squashedKey = key.replacingOccurrences(of: " ", with: "")
        // A run that starts on a different letter is a neighbouring word, not a mishearing ("log romanian…").
        guard squashedKey.count >= 5, squashedHeard.count >= 4, squashedHeard.first == squashedKey.first else {
            return nil
        }
        let distance = editDistance(squashedHeard, squashedKey)
        let allowed = max(1, squashedKey.count / 6)
        guard distance <= allowed else { return nil }
        return 0.9 - Double(distance) * 0.1
    }

    static func editDistance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous = Array(0 ... b.count)
        for i in 1 ... a.count {
            var row = [i] + Array(repeating: 0, count: b.count)
            for j in 1 ... b.count {
                row[j] = min(previous[j] + 1, row[j - 1] + 1, previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
            }
            previous = row
        }
        return previous[b.count]
    }
}

public extension TessFrame {
    /// The names he can say here. Private things arrive under their label; anything that isn't Claude-safe (Purse
    /// names) is left out, so money and body names never reach the recogniser's context.
    var vocabulary: VoiceLexicon {
        var names: [(name: String, boost: Double)] = [(room.capitalized, 1)]
        if let door { names.append((door, 1)) }
        if let window { names.append((window, 1)) }
        let focus = referent()?.item.name
        for element in elements where element.isShown {
            for item in element.items where item.taint == .claudeSafe {
                names.append((item.name, item.name == focus ? 5 : 2))
            }
            for call in element.calls {
                names.append(contentsOf: call.phrases.map { (name: $0, boost: 1.0) })
            }
        }
        return VoiceLexicon(names: names)
    }
}
