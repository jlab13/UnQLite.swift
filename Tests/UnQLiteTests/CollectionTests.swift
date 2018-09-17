import XCTest
@testable import UnQLite


final class CollectionTests: XCTestCase {
    static var allTests = [
        ("usersCollection", testUsersCollection),
    ]

    var db: Connection!

    override func setUp() {
        super.setUp()
        db = try! Connection()
    }
    
    func testUsersCollection() throws {
        let users: [[String: Any]] = [
            ["name": "Huey", "age": 3, "width": 13.5],
            ["name": "Mickey", "age": 11, "width": 10.0],
        ]
        
        let cl = try db.collection(with: "users")
        try cl.append(users)
        print(try cl.recordCount())
    }
    
}
