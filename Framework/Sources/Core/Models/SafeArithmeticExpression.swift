import Foundation

/// Arithmetic text that is safe to pass to `NSExpression(format:)`.
///
/// `NSExpression(format:)` throws an uncaught ObjC exception on anything else
/// (`2.0%3.0`, `*3.25`, an empty string). Exponents are allowed because
/// `String(Double)` emits `1e-07`.
enum SafeArithmeticExpression {
    static func isSafe(_ expression: String) -> Bool {
        guard !expression.isEmpty else { return false }
        var index = expression.startIndex
        var depth = 0
        var expectValue = true
        var sawDigit = false

        while index < expression.endIndex {
            let character = expression[index]
            if character == "(" {
                guard expectValue else { return false }
                depth += 1
                index = expression.index(after: index)
                continue
            }
            if character == ")" {
                guard !expectValue, depth > 0 else { return false }
                depth -= 1
                expectValue = false
                index = expression.index(after: index)
                continue
            }
            if character == "+" || character == "-" || character == "*" || character == "/" {
                if expectValue {
                    guard character == "-" else { return false }
                    index = expression.index(after: index)
                    continue
                }
                expectValue = true
                index = expression.index(after: index)
                continue
            }
            guard expectValue, character.isNumber || character == "." else { return false }
            var sawDot = false
            var sawNumeral = false
            while index < expression.endIndex {
                let digit = expression[index]
                if digit.isNumber {
                    sawNumeral = true
                    sawDigit = true
                    index = expression.index(after: index)
                } else if digit == "." {
                    if sawDot { return false }
                    sawDot = true
                    index = expression.index(after: index)
                } else if digit == "e" || digit == "E" {
                    guard sawNumeral else { return false }
                    index = expression.index(after: index)
                    if index < expression.endIndex, expression[index] == "+" || expression[index] == "-" {
                        index = expression.index(after: index)
                    }
                    var sawExponentDigit = false
                    while index < expression.endIndex, expression[index].isNumber {
                        sawExponentDigit = true
                        index = expression.index(after: index)
                    }
                    guard sawExponentDigit else { return false }
                    break
                } else {
                    break
                }
            }
            guard sawNumeral else { return false }
            expectValue = false
        }
        return depth == 0 && !expectValue && sawDigit
    }
}
