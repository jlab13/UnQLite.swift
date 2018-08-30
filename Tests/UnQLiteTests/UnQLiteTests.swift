import XCTest
@testable import UnQLite


final class UnQLiteTests: XCTestCase {

    static var allTests = [
        ("testKeyValue", testKeyValue),
    ]
    

    func testKeyValue() throws {
    	let db = try UnQLite(fileName: ":mem:", mode: .inMemory)

    	try db.set(0, forKey: "int")
    	XCTAssertEqual(try db.integer(forKey: "int"), 0)

    	try db.set(Int.max, forKey: "int")
    	XCTAssertEqual(try db.integer(forKey: "int"), Int.max)

    	try db.set(Int.min, forKey: "int")
    	XCTAssertEqual(try db.integer(forKey: "int"), Int.min)
    }

}
