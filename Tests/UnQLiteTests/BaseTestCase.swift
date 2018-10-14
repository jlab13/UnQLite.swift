import XCTest
@testable import UnQLite


class BaseTestCase: XCTestCase {
    var db: Connection!
    
    override func setUp() {
        super.setUp()
        db = try! Connection()
    }
    
    func compareDict(_ lhs: [AnyHashable: Any], _ rhs: [AnyHashable: Any]) -> Bool {
        let nsdl = NSDictionary(dictionary: lhs)
        return nsdl.isEqual(to: rhs)
    }
    
}
