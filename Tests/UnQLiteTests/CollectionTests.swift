import XCTest
@testable import UnQLite


final class CollectionTests: BaseTestCase {
    static var allTests = [
        ("testCollection", testCollection),
        ("testFilter", testFilter),
        ("testFilterExpression", testFilterExpression),
        ("testFilterExpressionExt", testFilterExpressionExt),
        ("testFilterExpressionContains", testFilterExpressionContains),
        ("testFilterExpressionEqual", testFilterExpressionEqual),
    ]


    static let productsCount = 10
    static var productsData: [[String: Any]]!

    var clProducts: UnQLite.Collection!
    
    override static func setUp() {
        super.setUp()
        productsData = (1...productsCount).map {
            ["id": $0, "name": "Product Name \($0)", "qty": $0 * 2, "price": Double($0) * 1.5, "is_four": $0 % 4 == 0]
        }
    }
    
    override func setUp() {
        super.setUp()
        
        clProducts = try! db.collection(with: "products")
        try! clProducts.store(CollectionTests.productsData)
    }

    
    func testCollection() throws {
        XCTAssertEqual(try clProducts.recordCount(), CollectionTests.productsCount)

        for id in [0, 1, 2, 3] {
            var item = try clProducts.fetch(recordId: id)
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, CollectionTests.productsData[id]))
        }
        
        try clProducts.delete(recordId: 0)
        XCTAssertEqual(try clProducts.recordCount(), CollectionTests.productsCount - 1)

        try clProducts.delete(recordId: 1)
        XCTAssertEqual(try clProducts.recordCount(), CollectionTests.productsCount - 2)
        
        let id = Expression<Int>("id")
        let name = Expression<String>("name")
        let qty = Expression<Int>("qty")
        let price = Expression<Double>("price")
        let isFour = Expression<Bool>("is_four")

        try clProducts.update(recordId: 2,
            id     <- 10,
            name   <- "Update prodict by id 10",
            qty    <- 13,
            price  <- 13.666,
            isFour <- false
        )

        var item = try clProducts.fetch(recordId: 2)
        item.removeValue(forKey: "__id")
        
        let newRecord: [String: Any] = [
            "id": 10,
            "name": "Update prodict by id 10",
            "qty": 13,
            "price": 13.666,
            "is_four": false
        ]

        XCTAssertTrue(compareDict(item, newRecord))
    }
    
    func testFilter() throws {
        let result = try clProducts.fetch { $0["id"] as? Int == 4 }
        XCTAssertEqual(result.count, 1)

        if var item = result.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, CollectionTests.productsData[3]))
        }
    }

    func testFilterExpression() throws {
        let id = Expression<Int>("id")

        let result = try clProducts.fetch(id == 4)
        XCTAssertEqual(result.count, 1)

        if var item = result.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, CollectionTests.productsData[3]))
        }
    }

    func testFilterExpressionExt() throws {
        let id = Expression<Int>("id")
        let qty = Expression<Int>("qty")
        let price = Expression<Double>("price")

        let result = try clProducts.fetch(id == 1 || price * qty == 300)
        XCTAssertEqual(result.count, 2)
        
        if var item = result.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, CollectionTests.productsData[0]))
        }
        
        if var item = result.last {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, CollectionTests.productsData[9]))
        }
    }

    func testFilterExpressionContains() throws {
        let name = Expression<String>("name")

        let result = try clProducts.fetch(name.contains("name 1", ignoreCase: true))
        XCTAssertEqual(result.count, 2)
        
        if var item = result.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, CollectionTests.productsData[0]))
        }
        
        if var item = result.last {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, CollectionTests.productsData[9]))
        }
    }

    func testFilterExpressionEqual() throws {
        let name = Expression<String>("name")

        let result = try clProducts.fetch(
            name.equal("product name 1", ignoreCase: true) || name.equal("product name 10", ignoreCase: true)
        )
        XCTAssertEqual(result.count, 2)
        
        if var item = result.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, CollectionTests.productsData[0]))
        }
        
        if var item = result.last {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(compareDict(item, CollectionTests.productsData[9]))
        }
    }

}
