import Foundation

/// A tiny arithmetic language for computed fields: numbers, field keys, `+ - * /`, unary minus, parentheses.
/// Example: `weight * (1 + reps / 30)`.
indirect enum Expression: Equatable, Sendable {
    case number(Double)
    case variable(String)
    case negate(Expression)
    case binary(Character, Expression, Expression)

    enum ParseError: Error, Equatable {
        case unexpectedEnd
        case unexpectedCharacter(Character)
        case trailingInput
    }

    static func parse(_ source: String) throws -> Expression {
        var parser = Parser(characters: Array(source))
        let expression = try parser.parseSum()
        parser.skipWhitespace()
        guard parser.isAtEnd else { throw ParseError.trailingInput }
        return expression
    }

    /// Field keys this expression reads.
    var variables: Set<String> {
        switch self {
        case .number: []
        case let .variable(name): [name]
        case let .negate(inner): inner.variables
        case let .binary(_, lhs, rhs): lhs.variables.union(rhs.variables)
        }
    }

    /// Returns nil if a variable is missing or a division by zero occurs.
    func evaluate(_ lookup: (String) -> Double?) -> Double? {
        switch self {
        case let .number(value):
            return value
        case let .variable(name):
            return lookup(name)
        case let .negate(inner):
            return inner.evaluate(lookup).map { -$0 }
        case let .binary(symbol, lhs, rhs):
            guard let left = lhs.evaluate(lookup), let right = rhs.evaluate(lookup) else { return nil }
            switch symbol {
            case "+": return left + right
            case "-": return left - right
            case "*": return left * right
            case "/": return right == 0 ? nil : left / right
            default: return nil
            }
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

    mutating func parseSum() throws -> Expression {
        var lhs = try parseProduct()
        while let symbol = peek(), symbol == "+" || symbol == "-" {
            index += 1
            lhs = try .binary(symbol, lhs, parseProduct())
        }
        return lhs
    }

    mutating func parseProduct() throws -> Expression {
        var lhs = try parseUnary()
        while let symbol = peek(), symbol == "*" || symbol == "/" {
            index += 1
            lhs = try .binary(symbol, lhs, parseUnary())
        }
        return lhs
    }

    mutating func parseUnary() throws -> Expression {
        if peek() == "-" {
            index += 1
            return try .negate(parseUnary())
        }
        return try parsePrimary()
    }

    mutating func parsePrimary() throws -> Expression {
        guard let character = peek() else { throw Expression.ParseError.unexpectedEnd }
        if character == "(" {
            index += 1
            let inner = try parseSum()
            guard peek() == ")" else { throw Expression.ParseError.unexpectedEnd }
            index += 1
            return inner
        }
        if character.isNumber || character == "." {
            let start = index
            while !isAtEnd, characters[index].isNumber || characters[index] == "." {
                index += 1
            }
            guard let value = Double(String(characters[start ..< index])) else {
                throw Expression.ParseError.unexpectedCharacter(character)
            }
            return .number(value)
        }
        if character.isLetter || character == "_" {
            let start = index
            while !isAtEnd, characters[index].isLetter || characters[index].isNumber || characters[index] == "_" {
                index += 1
            }
            return .variable(String(characters[start ..< index]))
        }
        throw Expression.ParseError.unexpectedCharacter(character)
    }
}
