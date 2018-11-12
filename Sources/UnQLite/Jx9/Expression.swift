
public protocol Expressible {
    var raw: String { get }
}


public struct Expression<DataType>: Expressible {
    public let raw: String
    
    public init(raw: String) {
        self.raw = raw
    }
    
    public init(_ keyPath: String) {
        self.init(raw: "\(expressionRecordVariable).\(keyPath)")
    }
}


extension String {
    
    func join(_ expressions: [Expressible]) -> Expressible {
        let raws = expressions.map { $0.raw }
        return Expression<Void>(raw: raws.joined(separator: self))
    }
    
    func infix(_ lhs: Expressible, _ rhs: Expressible, wrap: Bool = true) -> Expressible {
        let expression = Expression<Void>(raw: " \(self) ".join([lhs, rhs]).raw)
        guard wrap else {
            return expression
        }
        return "".wrap(expression)
    }
    
    func prefix(_ expression: Expressible) -> Expressible {
        return Expression<Void>(raw: "\(self)\(expression.raw)")
    }
    
    func postfix(_ expression: Expressible) -> Expressible {
        return Expression<Void>(raw: "\(expression.raw)\(self)")
    }
    
    func wrap(_ expression: Expressible) -> Expressible {
        return Expression<Void>(raw: "\(self)(\(expression.raw))")
    }
    
}


func infix(_ lhs: Expressible, _ rhs: Expressible, wrap: Bool = true, function: String = #function) -> Expressible {
    return function.infix(lhs, rhs, wrap: wrap)
}

func wrap(_ expression: Expressible, function: String = #function) -> Expressible {
    return function.wrap(expression)
}

func prefix(_ expression: Expressible, function: String = #function) -> Expressible {
    return function.prefix(expression)
}

func postfix(_ expression: Expressible, function: String = #function) -> Expressible {
    return function.postfix(expression)
}


extension Expressible {
    
    internal var field: String? {
        let parts = self.raw.split(separator: ".")
        return parts.count > 1 && parts.first == "$rec" ? String(parts[1]) : nil
    }
    
    public func contains(_ aExpression: Expressible, ignoreCase: Bool = false) -> Expression<Bool> {
        let jx9Func = ignoreCase ? "stripos" : "strpos"
        return Expression<Bool>(raw: "\(jx9Func)(\(self.raw), \(aExpression.raw))")
    }
    
    public func equal(_ aExpression: Expressible, ignoreCase: Bool = false) -> Expression<Bool> {
        let jx9Func = ignoreCase ? "strcasecmp" : "strcmp"
        return Expression<Bool>(raw: "\(jx9Func)(\(self.raw), \(aExpression.raw)) == 0")
    }

}


extension String: Expressible {
    public var raw: String {
        return "\"\(self)\""
    }
}

extension Bool: Expressible {
    public var raw: String {
        return String(self)
    }
}

extension Int: Expressible {
    public var raw: String {
        return String(self)
    }
}

extension Float: Expressible {
    public var raw: String {
        return String(self)
    }
}

extension Double: Expressible {
    public var raw: String {
        return String(self)
    }
}
