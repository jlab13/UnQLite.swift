import XCTest
@testable import UnQLite


class ExpressionTests: XCTestCase {
    static var allTests = [
        ("testExpression", testExpression),
        ("testArithmeticOperators", testArithmeticOperators),
        ("testBitwiseOperators", testBitwiseOperators),
        ("testComparisonOperators", testComparisonOperators),
        ("testLogicalOperators", testLogicalOperators),
    ]

    func testExpression() {
        let id = Expression<Int>("id")
        let qty = Expression<Int>("qty")
        let price = Expression<Double>("price")
        let text = Expression<String>("text")

        XCTAssertEqual(id.raw, "$rec.id")
        XCTAssertEqual(qty.raw, "$rec.qty")
        XCTAssertEqual(price.raw, "$rec.price")
        XCTAssertEqual(text.raw, "$rec.text")
    }

    func testArithmeticOperators() {
        let price = Expression<Double>("price")
        let qty = Expression<Int>("qty")
        let text = Expression<String>("text")

        XCTAssertEqual((text + "two").raw, "($rec.text .. \"two\")")
        XCTAssertEqual(("one" + text).raw, "(\"one\" .. $rec.text)")

        XCTAssertEqual((price + qty).raw, "($rec.price + $rec.qty)")
        XCTAssertEqual((price - qty).raw, "($rec.price - $rec.qty)")
        XCTAssertEqual((price * qty).raw, "($rec.price * $rec.qty)")
        XCTAssertEqual((price / qty).raw, "($rec.price / $rec.qty)")
        XCTAssertEqual((-qty).raw, "-$rec.qty")
        XCTAssertEqual((++qty).raw, "++$rec.qty")
        XCTAssertEqual((qty++).raw, "$rec.qty++")

        XCTAssertEqual((price + 13).raw, "($rec.price + 13)")
        XCTAssertEqual((price - 13).raw, "($rec.price - 13)")
        XCTAssertEqual((price * 13).raw, "($rec.price * 13)")
        XCTAssertEqual((price / 13).raw, "($rec.price / 13)")

        let dbVal = Double(0.13)
        XCTAssertEqual((price + dbVal).raw, "($rec.price + 0.13)")
        XCTAssertEqual((price - dbVal).raw, "($rec.price - 0.13)")
        XCTAssertEqual((price * dbVal).raw, "($rec.price * 0.13)")
        XCTAssertEqual((price / dbVal).raw, "($rec.price / 0.13)")

        let flVal = Float(13.13)
        XCTAssertEqual((price + flVal).raw, "($rec.price + 13.13)")
        XCTAssertEqual((price - flVal).raw, "($rec.price - 13.13)")
        XCTAssertEqual((price * flVal).raw, "($rec.price * 13.13)")
        XCTAssertEqual((price / flVal).raw, "($rec.price / 13.13)")
    }

    func testBitwiseOperators() {
        let price = Expression<Double>("price")
        let qty = Expression<Int>("qty")

        XCTAssertEqual((price & qty).raw, "($rec.price & $rec.qty)")
        XCTAssertEqual((price | qty).raw, "($rec.price | $rec.qty)")
        XCTAssertEqual((price ^ qty).raw, "($rec.price ^ $rec.qty)")
        XCTAssertEqual((price << qty).raw, "($rec.price << $rec.qty)")
        XCTAssertEqual((price >> qty).raw, "($rec.price >> $rec.qty)")
        XCTAssertEqual((~qty).raw, "~$rec.qty")

        XCTAssertEqual((price & 13).raw, "($rec.price & 13)")
        XCTAssertEqual((price | 13).raw, "($rec.price | 13)")
        XCTAssertEqual((price ^ 13).raw, "($rec.price ^ 13)")
        XCTAssertEqual((price << 13).raw, "($rec.price << 13)")
        XCTAssertEqual((price >> 13).raw, "($rec.price >> 13)")
    }

    func testComparisonOperators() {
        let price = Expression<Double>("price")
        let qty = Expression<Int>("qty")

        XCTAssertEqual((price == qty).raw, "($rec.price == $rec.qty)")
        XCTAssertEqual((price != qty).raw, "($rec.price != $rec.qty)")
        XCTAssertEqual((price === qty).raw, "($rec.price === $rec.qty)")
        XCTAssertEqual((price !== qty).raw, "($rec.price !== $rec.qty)")
        XCTAssertEqual((price > qty).raw, "($rec.price > $rec.qty)")
        XCTAssertEqual((price < qty).raw, "($rec.price < $rec.qty)")
        XCTAssertEqual((price >= qty).raw, "($rec.price >= $rec.qty)")
        XCTAssertEqual((price <= qty).raw, "($rec.price <= $rec.qty)")

        XCTAssertEqual((price == 13).raw, "($rec.price == 13)")
        XCTAssertEqual((price != 13).raw, "($rec.price != 13)")
        XCTAssertEqual((price === 13).raw, "($rec.price === 13)")
        XCTAssertEqual((price !== 13).raw, "($rec.price !== 13)")
        XCTAssertEqual((price > 13).raw, "($rec.price > 13)")
        XCTAssertEqual((price < 13).raw, "($rec.price < 13)")
        XCTAssertEqual((price >= 13).raw, "($rec.price >= 13)")
        XCTAssertEqual((price <= 13).raw, "($rec.price <= 13)")
    }

    func testLogicalOperators() {
        let price = Expression<Double>("price")
        let qty = Expression<Int>("qty")

        XCTAssertEqual((price && qty).raw, "($rec.price && $rec.qty)")
        XCTAssertEqual((price || qty).raw, "($rec.price || $rec.qty)")

        XCTAssertEqual((price && 13).raw, "($rec.price && 13)")
        XCTAssertEqual((price || 13).raw, "($rec.price || 13)")
    }

}
