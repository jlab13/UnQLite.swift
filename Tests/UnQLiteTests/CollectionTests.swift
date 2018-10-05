import XCTest
@testable import UnQLite


let productsCount = 10
let products: [[String: Any]] = (1...productsCount).map {
    ["id": $0, "name": "Prodict name \($0)", "qty": $0 * 2, "price": Double($0) * 1.5, "is_four": $0 % 4 == 0]
}


final class CollectionTests: BaseTestCase {
    
    func testProductsCollection() throws {
        let cl = try db.collection(with: "products")
        try cl.append(products)
        
        XCTAssertEqual(try cl.recordCount(), productsCount)

        for id in [0, 1, 2, 3] {
            var item = try cl.fetch(by: id)
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, products[id]))
        }
        
        try cl.delete(by: 0)
        XCTAssertEqual(try cl.recordCount(), productsCount - 1)

        try cl.delete(by: 1)
        XCTAssertEqual(try cl.recordCount(), productsCount - 2)
        
        let newRecord: [String: Any] = [
            "id": 10,
            "name": "Update prodict by id 10",
            "qty": 13,
            "price": 13.666,
            "is_four": false
        ]
        
        try cl.update(record: newRecord, by: 2)

        var item = try cl.fetch(by: 2)
        item.removeValue(forKey: "__id")
        XCTAssertTrue(compareDict(item, newRecord))
    }
    
    func testProductsFilter() throws {
        let cl = try db.collection(with: "products")
        try cl.append(products)
        let result = try cl.filter { $0["id"] as? Int == 4 }

        var item = result.first!
        item.removeValue(forKey: "__id")

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(compareDict(item, products[3]))
    }

}
