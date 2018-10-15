
// MARK: - Arithmetic Operators

public func +(lhs: Expression<String>, rhs: Expression<String>) -> Expression<String> {
    return Expression<String>(raw: "..".infix(lhs, rhs).raw)
}

public func +(lhs: Expression<String>, rhs: String) -> Expression<String> {
    return Expression<String>(raw: "..".infix(lhs, rhs).raw)
}

public func +(lhs: String, rhs: Expression<String>) -> Expression<String> {
    return Expression<String>(raw: "..".infix(lhs, rhs).raw)
}

public func +(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

public func -(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

public func *(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

public func /(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

public prefix func -(rhs: Expressible) -> Expressible {
    return prefix(rhs)
}

public prefix func ++(rhs: Expressible) -> Expressible {
    return prefix(rhs)
}

public postfix func ++(rhs: Expressible) -> Expressible {
    return postfix(rhs)
}


// MARK: - Bitwise Operators

/// Returns a one in each bit position for which the corresponding bits of both operands are ones.
public func &(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

/// Returns a one in each bit position for which the corresponding bits of either or both operands are ones.
public func |(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

/// Returns a one in each bit position for which the corresponding bits of either but not both operands are ones.
public func ^(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

/// Shifts a in binary representation b bits to the left, shifting in zeros from the right.
public func <<(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

/// Shifts a in binary representation b bits to the right, discarding bits shifted off.
public func >>(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

/// Inverts the bits of its operand.
public prefix func ~(rhs: Expressible) -> Expressible {
    return prefix(rhs)
}


// MARK: - Comparison Operators

/// Returns true if the operands are equal.
public func ==(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

/// Returns true if the operands are not equal.
public func !=(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

/// Returns true if the operands are equal and of the same type.
public func ===(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

/// Returns true if the operands are not equal and/or not of the same type.
public func !==(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

/// Returns true if the left operand is greater than the right operand.
public func >(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

/// Returns true if the left operand is greater than or equal to the right operand.
public func >=(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

/// Returns true if the left operand is less than the right operand.
public func <(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

/// Returns true if the left operand is less than or equal to the right operand.
public func <=(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}


// MARK: - Logical Operators

/// (Logical AND) Returns lhs if it can be converted to false; otherwise, returns rhs.
/// Thus, when used with Boolean values, && returns true if both operands are true; otherwise, returns false.
public func &&(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

/// (Logical OR) Returns lhs if it can be converted to true; otherwise, returns rhs.
/// Thus, when used with Boolean values, || returns true if either operand is true; if both are false, returns false.
public func ||(lhs: Expressible, rhs: Expressible) -> Expressible {
    return infix(lhs, rhs)
}

/// (Logical NOT) Returns false if its single operand can be converted to true; otherwise, returns true.
public prefix func !(rhs: Expressible) -> Expressible {
    return prefix(rhs)
}

