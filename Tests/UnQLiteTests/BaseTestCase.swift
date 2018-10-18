import XCTest
import Foundation

@testable import UnQLite


class BaseTestCase: XCTestCase {
    var db: Connection!
    
    override func setUp() {
        super.setUp()
        db = try! Connection()
    }
    
    func isEqual<T: Equatable>(type: T.Type, _ lhs: Any?, _ rhs: Any?) -> Bool {
        guard let lhs = lhs as? T, let rhs = rhs as? T else {
            return false
        }
        return lhs == rhs
    }
    
    func isEqualArray(_ lhs: [Any], _ rhs: [Any]) -> Bool {
        if lhs.count != rhs.count { return false }
        
        var result = true
        for (idx, lval) in lhs.enumerated() {
            switch lval {
            case let lval as [AnyHashable: Any]:
                if let rval = rhs[idx] as? [AnyHashable: Any] {
                    result = result && isEqualDict(lval, rval)
                } else {
                    return false
                }
            case let lval as [Any]:
                if let rval = rhs[idx] as? [Any] {
                    result = result && isEqualArray(lval, rval)
                } else {
                    return false
                }
            case is String:
                result = result && isEqual(type: String.self, lval, rhs[idx])
            case is Int:
                result = result && isEqual(type: Int.self, lval, rhs[idx])
            case is Double:
                result = result && isEqual(type: Double.self, lval, rhs[idx])
            case is Float:
                result = result && isEqual(type: Float.self, lval, rhs[idx])
            case is Bool:
                result = result && isEqual(type: Bool.self, lval, rhs[idx])
            default:
                result = false
            }
            
        }
        
        return result
    }
    
    
    func isEqualDict(_ lhs: [AnyHashable: Any], _ rhs: [AnyHashable: Any]) -> Bool {
        if lhs.count != rhs.count { return false }
        var result = true
        
        for lrec in lhs {
            switch lrec.value {
            case let lval as [AnyHashable: Any]:
                if let rval = rhs[lrec.key] as? [AnyHashable: Any] {
                    result = result && isEqualDict(lval, rval)
                } else {
                    return false
                }
            case let lval as [Any]:
                if let rval = rhs[lrec.key] as? [Any] {
                    result = result && isEqualArray(lval, rval)
                } else {
                    return false
                }
            case is String:
                result = result && isEqual(type: String.self, lrec.value, rhs[lrec.key])
            case is Int:
                result = result && isEqual(type: Int.self, lrec.value, rhs[lrec.key])
            case is Double:
                result = result && isEqual(type: Double.self, lrec.value, rhs[lrec.key])
            case is Float:
                result = result && isEqual(type: Float.self, lrec.value, rhs[lrec.key])
            case is Bool:
                result = result && isEqual(type: Bool.self, lrec.value, rhs[lrec.key])
            default:
                result = false
            }
        }
        
        return result
    }

}
