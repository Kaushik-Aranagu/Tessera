import Foundation

/// Where a piece of text came from (input-hygiene H4, docs/ai/harness/input-hygiene.md rule 5). It is stamped where
/// the text enters and travels with everything made from it, so a later step can tell his words from a page's.
public enum Provenance: Sendable, Hashable, Codable {
    /// Typed or said by him.
    case author
    /// An object or a number from the engine.
    case app
    /// Tess's own bookkeeping: counts, checks, timings.
    case harness
    /// Written by a model for a job. Checked before it is shown or kept; never an instruction.
    case model(job: String)
    /// A web page or a search result, by its site.
    case web(site: String)
    /// What a tool returned.
    case tool(name: String)

    /// How far the text is believed. Order matters: `min` over a run is what the run may do.
    public enum Trust: Int, Sendable, Comparable, Codable {
        /// Third-party text: data only, never an instruction, a belief or a lesson.
        case untrusted
        /// A model's words: checked before they are shown or kept.
        case modelWritten
        /// His own words.
        case author
        /// The engine's numbers and Tess's own records.
        case exact

        public static func < (lhs: Trust, rhs: Trust) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public var trust: Trust {
        switch self {
        case .author: .author
        case .app, .harness: .exact
        case .model: .modelWritten
        case .web: .untrusted
        // A tool can echo what a model or a page put in; a result that holds only engine values is stamped `.app`.
        case .tool: .untrusted
        }
    }

    /// The short name a pack's data block and a ledger row carry: "web:example.org", "tool:recall".
    public var label: String {
        switch self {
        case .author: "author"
        case .app: "app"
        case .harness: "harness"
        case let .model(job): "model:\(job)"
        case let .web(site): "web:\(site)"
        case let .tool(name): "tool:\(name)"
        }
    }

    /// A web page's site: its host without "www.", lowercased; "page" when the link has no host.
    public static func page(_ url: URL?) -> Provenance {
        let host = url?.host()?.lowercased() ?? ""
        let site = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return .web(site: site.isEmpty ? "page" : site)
    }

    /// The source of a server tool's result block, as the API sent it (`web_search_tool_result`,
    /// `web_fetch_tool_result`): the first site it holds. Nil for any other block.
    public static func ofServerBlock(_ raw: Data) -> Provenance? {
        guard let block = (try? JSONSerialization.jsonObject(with: raw)) as? [String: Any],
              let type = block["type"] as? String, serverResultTypes.contains(type) else { return nil }
        func firstURL(_ value: Any?) -> String? {
            if let object = value as? [String: Any] {
                if let url = object["url"] as? String {
                    return url
                }
                for key in object.keys.sorted() {
                    if let found = firstURL(object[key]) {
                        return found
                    }
                }
            }
            if let list = value as? [Any] {
                for item in list {
                    if let found = firstURL(item) {
                        return found
                    }
                }
            }
            return nil
        }
        return page(firstURL(block["content"]).flatMap(URL.init(string:)))
    }

    /// The server tool result blocks that carry third-party text.
    public static let serverResultTypes: Set<String> = ["web_search_tool_result", "web_fetch_tool_result"]
}
