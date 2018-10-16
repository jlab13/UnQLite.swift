
public protocol Expressible {
    var raw: String { get }
}


public class ExpressionType: Expressible, Hashable {
    public static func == (lhs: ExpressionType, rhs: ExpressionType) -> Bool {
        return lhs.raw == rhs.raw
    }
    
    public let raw: String
    
    public var hashValue: Int {
        return self.raw.hashValue
    }
    
    public lazy var field: String? = {
        let parts = self.raw.split(separator: ".")
        return parts.count > 1 ? String(parts[1]) : nil
    }()
    
    internal init(raw: String) {
        self.raw = raw
    }
}


public class Expression<DataType>: ExpressionType {
    
    override init(raw: String) {
        super.init(raw: raw)
    }

    public init(_ field: String) {
        super.init(raw: "$rec.\(field)")
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
    
    public func contains(_ aString: String, ignoreCase: Bool = false) -> Expression<Bool> {
        let jx9Func = ignoreCase ? "stripos" : "strpos"
        return Expression<Bool>(raw: "\(jx9Func)(\(self.raw), \"\(aString)\")")
    }
    
    public func equal(_ aString: String, ignoreCase: Bool = false) -> Expression<Bool> {
        let jx9Func = ignoreCase ? "strcasecmp" : "strcmp"
        return Expression<Bool>(raw: "\(jx9Func)(\(self.raw), \"\(aString)\") == 0")
    }
    
}


extension String: Expressible {
    public var raw: String {
        return "\"\(self)\""
    }
    
    public func contains(_ aExpression: Expressible, ignoreCase: Bool = false) -> Expression<Bool> {
        let jx9Func = ignoreCase ? "stripos" : "strpos"
        return Expression<Bool>(raw: "\(jx9Func)(\"\(self)\", \(aExpression.raw))")
    }
    
    public func equal(_ aExpression: Expressible, ignoreCase: Bool = false) -> Expression<Bool> {
        let jx9Func = ignoreCase ? "strcasecmp" : "strcmp"
        return Expression<Bool>(raw: "\(jx9Func)(\"\(self)\", \(aExpression.raw)) == 0")
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
