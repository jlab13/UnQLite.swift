import XCTest
@testable import UnQLite


let id = Expression<Int>("id")
let name = Expression<String>("name")
let qty = Expression<Int>("qty")
let price = Expression<Double>("price")
let isFour = Expression<Bool>("is_four")

let productsCount = 10
let productsData: [[String: Any]] = (1...productsCount).map {
    ["id": $0, "name": "Product Name \($0)", "qty": $0 * 2, "price": Double($0) * 1.5, "is_four": $0 % 4 == 0]
}


final class CollectionTests: BaseTestCase {
    var clProducts: UnQLite.Collection!
    
    override func setUp() {
        super.setUp()
        
        clProducts = try! db.collection(with: "products")
        try! clProducts.append(productsData)
    }

    
    func testProductsCollection() throws {
        XCTAssertEqual(try clProducts.recordCount(), productsCount)

        for id in [0, 1, 2, 3] {
            var item = try clProducts.fetch(by: id)
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, productsData[id]))
        }
        
        try clProducts.delete(by: 0)
        XCTAssertEqual(try clProducts.recordCount(), productsCount - 1)

        try clProducts.delete(by: 1)
        XCTAssertEqual(try clProducts.recordCount(), productsCount - 2)
        
        let newRecord: [String: Any] = [
            "id": 10,
            "name": "Update prodict by id 10",
            "qty": 13,
            "price": 13.666,
            "is_four": false
        ]
        
        try clProducts.update(record: newRecord, by: 2)

        var item = try clProducts.fetch(by: 2)
        item.removeValue(forKey: "__id")
        XCTAssertTrue(compareDict(item, newRecord))
    }
    
    func testProductsFilter() throws {
        let result = try clProducts.filter { $0["id"] as? Int == 4 }
        XCTAssertEqual(result.count, 1)

        if var item = result.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, productsData[3]))
        }
    }

    func testProductsFilterExpression() throws {
        let result = try clProducts.filter(id == 4)
        XCTAssertEqual(result.count, 1)

        if var item = result.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, productsData[3]))
        }
    }

    func testProductsFilterExpressionExt() throws {
        let result = try clProducts.filter(id == 1 || price * qty == 300)
        XCTAssertEqual(result.count, 2)
        
        if var item = result.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, productsData[0]))
        }
        
        if var item = result.last {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, productsData[9]))
        }
    }

    func testProductsFilterExpressionContains() throws {
        let result = try clProducts.filter(name.contains("name 1"))
        XCTAssertEqual(result.count, 2)
        
        if var item = result.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, productsData[0]))
        }
        
        if var item = result.last {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, productsData[9]))
        }
    }

    func testProductsFilterExpressionEqual() throws {
        let result = try clProducts.filter(
            name.equal("product name 1", ignoreCase: true) || name.equal("product name 10", ignoreCase: true)
        )
        XCTAssertEqual(result.count, 2)
        
        if var item = result.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, productsData[0]))
        }
        
        if var item = result.last {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, productsData[9]))
        }
    }

}
