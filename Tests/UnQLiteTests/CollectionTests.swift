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


    static var productsData: [[String: Any]]!
    static var invoiceData: [[String: Any]]!

    var clProducts: UnQLite.Collection!
    var clInvoice: UnQLite.Collection!

    override static func setUp() {
        super.setUp()
        self.productsData = (1...10).map { (id) -> [String: Any] in
            ["id": id, "name": "Product Name \(id)", "qty": id * 2, "price": Double(id) * 1.5, "is_four": id % 4 == 0]
        }
        self.invoiceData = (1...10).map { (id) -> [String: Any] in
            ["id": id, "product": productsData[id - 1], "qty": id * 2, "price": Double(id) * 1.5]
        }
    }
    
    override func setUp() {
        super.setUp()
        
        clProducts = try! db.collection(with: "products")
        try! clProducts.store(CollectionTests.productsData)

        clInvoice = try! db.collection(with: "invoice")
        try! clInvoice.store(CollectionTests.invoiceData)
    }

    
    func testCollection() throws {
        XCTAssertEqual(try clProducts.count(), CollectionTests.productsData.count)

        for id in [0, 1, 2, 3] {
            var item = try clProducts.fetch(recordId: id)
            item.removeValue(forKey: "__id")
            XCTAssertTrue(isEqualDict(item, CollectionTests.productsData[id]))
        }
        
        try clProducts.delete(recordId: 0)
        XCTAssertEqual(try clProducts.count(), CollectionTests.productsData.count - 1)

        try clProducts.delete(recordId: 1)
        XCTAssertEqual(try clProducts.count(),CollectionTests.productsData.count - 2)
        
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

        XCTAssertTrue(isEqualDict(item, newRecord))
    }
    
    func testFilter() throws {
        let products = try clProducts.fetch { $0["id"] as? Int == 4 }
        XCTAssertEqual(products.count, 1)
        if var item = products.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(isEqualDict(item, CollectionTests.productsData[3]))
        }
        
        let invoices = try clInvoice.fetch {
            if let product = $0["product"] as? [String: Any], product["id"] as? Int == 4 {
                return true
            }
            return false
        }
        XCTAssertEqual(invoices.count, 1)
        
        if var item = invoices.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(isEqualDict(item, CollectionTests.invoiceData[3]))
        }

    }

    func testFilterExpression() throws {
        let id = Expression<Int>("id")
        let productId = Expression<Int>("product.id")

        let producs = try clProducts.fetch(id == 4)
        XCTAssertEqual(producs.count, 1)
        if var item = producs.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(isEqualDict(item, CollectionTests.productsData[3]))
        }
        
        let invoices = try clProducts.fetch(productId == 4)
        XCTAssertEqual(invoices.count, 1)
        
        if var item = invoices.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(isEqualDict(item, CollectionTests.productsData[3]))
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
            XCTAssertTrue(isEqualDict(item, CollectionTests.productsData[0]))
        }
        
        if var item = result.last {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(isEqualDict(item, CollectionTests.productsData[9]))
        }
    }

    func testFilterExpressionContains() throws {
        let name = Expression<String>("name")

        let products = try clProducts.fetch(name.contains("name 1", ignoreCase: true))
        XCTAssertEqual(products.count, 2)
        
        if var item = products.first {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(isEqualDict(item, CollectionTests.productsData[0]))
        }
        
        if var item = products.last {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(isEqualDict(item, CollectionTests.productsData[9]))
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
            XCTAssertTrue(isEqualDict(item, CollectionTests.productsData[0]))
        }
        
        if var item = result.last {
            item.removeValue(forKey: "__id")
            XCTAssertTrue(isEqualDict(item, CollectionTests.productsData[9]))
        }
    }

}
