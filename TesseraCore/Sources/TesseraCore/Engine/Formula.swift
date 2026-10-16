import Foundation

/// The one small expression language behind computed fields (and, later, filters and automations).
/// Numbers, field keys, `+ - * /`, unary minus, parentheses and a few functions:
/// `min`, `max`, `abs`, `round`, `floor`, `ceil`, and `coalesce` (first argument with a value).
/// Example: `weight * (1 + reps / 30)`.
public indirect enum Formula: Equatable, Sendable {
    case number(Double)
    case variable(String)
    case negate(Formula)
    case binary(Character, Formula, Formula)
    case call(String, [Formula])

    public enum ParseError: Error, Equatable {
        case unexpectedEnd
        case unexpectedCharacter(Character)
        case trailingInput
        case unknownFunction(String)
        case wrongArgumentCount(String)
    }

    public static let functions: [String: ClosedRange<Int>] = [
        "min": 1 ... Int.max, "max": 1 ... Int.max,
        "abs": 1 ... 1, "round": 1 ... 1, "floor": 1 ... 1, "ceil": 1 ... 1,
        "coalesce": 1 ... Int.max,
    ]

    public static func parse(_ source: String) throws -> Formula {
        var parser = Parser(characters: Array(source))
        let formula = try parser.parseSum()
        parser.skipWhitespace()
        guard parser.isAtEnd else { throw ParseError.trailingInput }
        return formula
    }

    /// Field keys this formula reads.
    public var variables: Set<String> {
        switch self {
        case .number: []
        case let .variable(name): [name]
        case let .negate(inner): inner.variables
        case let .binary(_, lhs, rhs): lhs.variables.union(rhs.variables)
        case let .call(_, arguments): arguments.reduce(into: Set<String>()) { $0.formUnion($1.variables) }
        }
    }

    /// Returns nil if a variable is missing or a division by zero occurs.
    public func evaluate(_ lookup: (String) -> Double?) -> Double? {
        switch self {
        case let .number(value):
            value
        case let .variable(name):
            lookup(name)
        case let .negate(inner):
            inner.evaluate(lookup).map { -$0 }
        case let .binary(symbol, lhs, rhs):
            lhs.evaluate(lookup).flatMap { left in
                rhs.evaluate(lookup).flatMap { right in Self.apply(symbol, left, right) }
            }
        case let .call("coalesce", arguments):
            // The first argument that has a value: `coalesce(rpe, 10)`.
            Self.firstValue(arguments, lookup)
        case let .call(name, arguments):
            Self.call(name, arguments.map { $0.evaluate(lookup) })
        }
    }

    private static func firstValue(_ arguments: [Formula], _ lookup: (String) -> Double?) -> Double? {
        for argument in arguments {
            if let value = argument.evaluate(lookup) {
                return value
            }
        }
        return nil
    }

    private static func apply(_ symbol: Character, _ left: Double, _ right: Double) -> Double? {
        switch symbol {
        case "+": left + right
        case "-": left - right
        case "*": left * right
        case "/": right == 0 ? nil : left / right
        default: nil
        }
    }

    private static func call(_ name: String, _ arguments: [Double?]) -> Double? {
        let values = arguments.compactMap(\.self)
        guard values.count == arguments.count, let first = values.first else { return nil }
        switch name {
        case "min": return values.min()
        case "max": return values.max()
        case "abs": return Swift.abs(first)
        case "round": return first.rounded()
        case "floor": return first.rounded(.down)
        case "ceil": return first.rounded(.up)
        default: return nil
        }
    }
}

private struct Parser {
    let characters: [Character]
    var index = 0

    var isAtEnd: Bool {
        index >= characters.count
    }

    mutating func skipWhitespace() {
        while !isAtEnd, characters[index].isWhitespace {
            index += 1
        }
    }

    mutating func peek() -> Character? {
        skipWhitespace()
        return isAtEnd ? nil : characters[index]
    }

    mutating func parseSum() throws -> Formula {
        var lhs = try parseProduct()
        while let symbol = peek(), symbol == "+" || symbol == "-" {
            index += 1
            lhs = try .binary(symbol, lhs, parseProduct())
        }
        return lhs
    }

    mutating func parseProduct() throws -> Formula {
        var lhs = try parseUnary()
        while let symbol = peek(), symbol == "*" || symbol == "/" {
            index += 1
            lhs = try .binary(symbol, lhs, parseUnary())
        }
        return lhs
    }

    mutating func parseUnary() throws -> Formula {
        if peek() == "-" {
            index += 1
            return try .negate(parseUnary())
        }
        return try parsePrimary()
    }

    mutating func parsePrimary() throws -> Formula {
        guard let character = peek() else { throw Formula.ParseError.unexpectedEnd }
        if character == "(" {
            index += 1
            let inner = try parseSum()
            guard peek() == ")" else { throw Formula.ParseError.unexpectedEnd }
            index += 1
            return inner
        }
        if character.isNumber || character == "." {
            let start = index
            while !isAtEnd, characters[index].isNumber || characters[index] == "." {
                index += 1
            }
            guard let value = Double(String(characters[start ..< index])) else {
                throw Formula.ParseError.unexpectedCharacter(character)
            }
            return .number(value)
        }
        if character.isLetter || character == "_" {
            let start = index
            while !isAtEnd, characters[index].isLetter || characters[index].isNumber || characters[index] == "_" {
                index += 1
            }
            let name = String(characters[start ..< index])
            guard peek() == "(" else { return .variable(name) }
            return try parseCall(name)
        }
        throw Formula.ParseError.unexpectedCharacter(character)
    }

    mutating func parseCall(_ name: String) throws -> Formula {
        guard let arity = Formula.functions[name] else { throw Formula.ParseError.unknownFunction(name) }
        index += 1 // "("
        var arguments: [Formula] = []
        if peek() != ")" {
            try arguments.append(parseSum())
            while peek() == "," {
                index += 1
                try arguments.append(parseSum())
            }
        }
        guard peek() == ")" else { throw Formula.ParseError.unexpectedEnd }
        index += 1
        guard arity.contains(arguments.count) else { throw Formula.ParseError.wrongArgumentCount(name) }
        return .call(name, arguments)
    }
}
