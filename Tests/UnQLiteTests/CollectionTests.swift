import XCTest
@testable import UnQLite


let productsCount = 100
let products: [[String: Any]] = (1...productsCount).map {
    ["id": $0, "name": "Prodict name \($0)", "qty": $0 * 2, "price": Double($0) * 1.5, "is_four": $0 % 4 == 0]
}


final class CollectionTests: BaseTestCase {
    
    func testProductsCollection() throws {
        let cl = try db.collection(with: "products")
        try cl.append(products)
        
        XCTAssertEqual(try cl.recordCount(), productsCount)

        for id in [0, 10, 40, 60, 80] {
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
        
        try cl.update(record: newRecord, by: 10)

        var item = try cl.fetch(by: 10)
        item.removeValue(forKey: "__id")
        XCTAssertTrue(compareDict(item, newRecord))
    }
    
    func testProductsFilter() throws {
        let cl = try db.collection(with: "products")
        try cl.append( Array(products.prefix(5)) )
        let r = try cl.filter {
            print($0)
            return true
        }
        print(r)
    }

}
