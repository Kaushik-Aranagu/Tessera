import Foundation

/// H5 of the input hygiene plan (docs/ai/harness/input-hygiene.md): every tool call is checked against the schema it
/// was offered with, in one place, before anything runs. The API holds a strict tool to its schema, but a request
/// keeps only so many tools strict (the rest go plain), and eagerly streamed input is not held to anything. A call
/// that doesn't fit runs nothing; the model reads what is wrong and can try again.
///
/// It reads the JSON Schema that `TessSchema` and the harness specs write: `type` (one or a union), `enum`, `anyOf`,
/// `properties`, `required`, `additionalProperties: false` and `items`. The line it returns names fields, never a
/// value from the call, so nothing the model wrote is echoed back.
enum ToolInputCheck {
    /// The deepest a call's arguments may nest.
    static let maxDepth = 16

    /// What is wrong with a call's arguments, in words the model can correct from, or nil when they fit. A schema
    /// that isn't readable JSON checks nothing (the harness wrote it).
    static func problem(_ input: Data, schema: Data) -> String? {
        guard let schema = (try? JSONSerialization.jsonObject(with: schema)) as? [String: Any] else { return nil }
        guard let value = try? JSONSerialization.jsonObject(with: input, options: [.fragmentsAllowed]) else {
            return "Error: the arguments aren't readable JSON."
        }
        return check(value, schema, at: "the arguments", depth: 0).map { "Error: \($0)." }
    }

    static func check(_ value: Any, _ schema: [String: Any], at path: String, depth: Int) -> String? {
        guard depth <= maxDepth else { return "\(path) nest too deeply" }
        if let branches = schema["anyOf"] as? [[String: Any]] {
            guard branches.contains(where: { check(value, $0, at: path, depth: depth + 1) == nil }) else {
                return "\(path) fit none of the forms it may take"
            }
        }
        let types = (schema["type"] as? [String]) ?? (schema["type"] as? String).map { [$0] } ?? []
        if !types.isEmpty, !types.contains(where: { matches(value, $0) }) {
            return "\(path) should be \(types.map(name).joined(separator: " or "))"
        }
        // A nullable choice may be written as a type union with null and an enum that leaves null out.
        if let values = schema["enum"] as? [Any], !(value is NSNull && allowsNull(schema)),
           !values.contains(where: { same($0, value) })
        {
            return "\(path) should be one of " + values.map { "\($0)" }.joined(separator: ", ")
        }
        if let object = value as? [String: Any] {
            let properties = schema["properties"] as? [String: [String: Any]] ?? [:]
            // A field that may be null may also be left out: a plain tool's model often does.
            for key in schema["required"] as? [String] ?? [] where object[key] == nil {
                guard let property = properties[key], allowsNull(property) else { return "\(path) need \"\(key)\"" }
            }
            if schema["additionalProperties"] as? Bool == false,
               let extra = object.keys.sorted().first(where: { properties[$0] == nil })
            {
                return "\(path) have no field \"\(extra.prefix(40))\""
            }
            for key in object.keys.sorted() {
                guard let property = properties[key], let field = object[key] else { continue }
                if let problem = check(field, property, at: "\"\(key)\"", depth: depth + 1) {
                    return problem
                }
            }
        }
        if let list = value as? [Any], let items = schema["items"] as? [String: Any] {
            for (index, item) in list.enumerated() {
                if let problem = check(item, items, at: "item \(index + 1) of \(path)", depth: depth + 1) {
                    return problem
                }
            }
        }
        return nil
    }

    static func allowsNull(_ schema: [String: Any]) -> Bool {
        if let types = schema["type"] as? [String], types.contains("null") {
            return true
        }
        return (schema["anyOf"] as? [[String: Any]])?.contains { allowsNull($0) || $0["type"] as? String == "null" }
            ?? false
    }

    static func isBool(_ value: Any) -> Bool {
        (value as? NSNumber).map { CFGetTypeID($0) == CFBooleanGetTypeID() } ?? false
    }

    static func matches(_ value: Any, _ type: String) -> Bool {
        switch type {
        case "string": value is String
        case "boolean": isBool(value)
        case "number": !isBool(value) && value is NSNumber
        case "integer": !isBool(value) && (value as? NSNumber).map { $0.doubleValue.rounded() == $0.doubleValue }
            ?? false
        case "null": value is NSNull
        case "array": value is [Any]
        case "object": value is [String: Any]
        default: true
        }
    }

    static func name(_ type: String) -> String {
        switch type {
        case "string": "text"
        case "integer": "a whole number"
        case "number": "a number"
        case "boolean": "true or false"
        case "array": "a list"
        case "object": "an object"
        default: type
        }
    }

    static func same(_ a: Any, _ b: Any) -> Bool {
        (a as? NSObject)?.isEqual(b) ?? false
    }
}
