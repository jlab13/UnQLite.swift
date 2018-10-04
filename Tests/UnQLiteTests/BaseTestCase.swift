import XCTest
@testable import UnQLite


class BaseTestCase: XCTestCase {
    var db: Connection!
    
    override func setUp() {
        super.setUp()
        db = try! Connection()
    }
    
    func compareDict(_ lhs: [String: Any], _ rhs: [String: Any]) -> Bool {
        let nsdl = NSDictionary(dictionary: lhs)
        let nsdr = NSDictionary(dictionary: rhs)
        return nsdl.isEqual(to: nsdr)
    }
    
}
