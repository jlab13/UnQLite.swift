import XCTest
@testable import UnQLite


final class KeyValueTests: BaseTestCase {
    static var allTests = [
        ("testThreadsafe", testThreadsafe),
        ("testInt", testInt),
        ("testFloat", testFloat),
        ("testDouble", testDouble),
        ("testSubscript", testSubscript),
        ("testString", testString),
        ("testData", testData),
    ]
    
    func testThreadsafe() {
        XCTAssertTrue(db.isThreadsafe)
    }
    
    func testInt() throws {
        try db.set(0, forKey: "int_zero")
        XCTAssertEqual(try db.integer(forKey: "int_zero"), 0)

        try db.set(Int.max, forKey: "int_max")
        XCTAssertEqual(try db.integer(forKey: "int_max"), Int.max)

        try db.set(Int.min, forKey: "int_min")
        XCTAssertEqual(try db.integer(forKey: "int_min"), Int.min)

        let initialInt = 13
        try db.setNumeric(initialInt, forKey: "int_generic")
        let readedInt: Int = try db.numeric(forKey: "int_generic")
        XCTAssertEqual(initialInt, readedInt)
    }

    func testFloat() throws {
        try db.set(Float(0), forKey: "float_zero")
        XCTAssertEqual(try db.float(forKey: "float_zero"), 0)

        try db.set(Float.greatestFiniteMagnitude, forKey: "float_01")
        XCTAssertEqual(try db.float(forKey: "float_01"), Float.greatestFiniteMagnitude)

        try db.set(Float.leastNormalMagnitude, forKey: "float_02")
        XCTAssertEqual(try db.float(forKey: "float_02"), Float.leastNormalMagnitude)

        try db.set(Float.leastNonzeroMagnitude, forKey: "float_03")
        XCTAssertEqual(try db.float(forKey: "float_03"), Float.leastNonzeroMagnitude)

        let initialFloat: Float = 13.666
        try db.setNumeric(initialFloat, forKey: "float_generic")
        let readedFloat: Float = try db.numeric(forKey: "float_generic")
        XCTAssertEqual(initialFloat, readedFloat)
    }

    func testDouble() throws {
        try db.set(Double(0), forKey: "double_zero")
        XCTAssertEqual(try db.double(forKey: "double_zero"), 0)

        try db.set(Double.greatestFiniteMagnitude, forKey: "double_01")
        XCTAssertEqual(try db.double(forKey: "double_01"), Double.greatestFiniteMagnitude)

        try db.set(Double.leastNormalMagnitude, forKey: "double_02")
        XCTAssertEqual(try db.double(forKey: "double_02"), Double.leastNormalMagnitude)

        try db.set(Double.leastNonzeroMagnitude, forKey: "double_03")
        XCTAssertEqual(try db.double(forKey: "double_03"), Double.leastNonzeroMagnitude)

        let initialDouble: Double = 13.666
        try db.setNumeric(initialDouble, forKey: "double_generic")
        let readedDouble: Double = try db.numeric(forKey: "double_generic")
        XCTAssertEqual(initialDouble, readedDouble)
    }

    func testSubscript() throws {
        // Test Int
        for i in 0..<100 {
            let key = "key_\(i)"
            db[key] = i
            XCTAssertEqual(db[key], i)
        }

        // Test UInt8
        for i in 0..<100 {
            let ui8 = UInt8(i)
            let key = "key_\(i)"
            db[key] = ui8
            XCTAssertEqual(db[key], ui8)
        }

        // Test UInt16
        for i in 0..<100 {
            let ui16 = UInt16(i)
            let key = "key_\(i)"
            db[key] = ui16
            XCTAssertEqual(db[key], ui16)
        }

        // Test UInt32
        for i in 0..<100 {
            let ui32 = UInt32(i)
            let key = "key_\(i)"
            db[key] = ui32
            XCTAssertEqual(db[key], ui32)
        }

        // Test UInt64
        for i in 0..<100 {
            let ui64 = UInt64(i)
            let key = "key_\(i)"
            db[key] = ui64
            XCTAssertEqual(db[key], ui64)
        }

        // Test Float
        for i in 0..<100 {
            let f = Float(i)
            let key = "key_\(i)"
            db[key] = f
            XCTAssertEqual(db[key], f)
        }

        // Test Double
        for i in 0..<100 {
            let d = Double(i)
            let key = "key_\(i)"
            db[key] = d
            XCTAssertEqual(db[key], d)
        }

    }
    
    func testString() throws {
        let ascii    = String( (0x20...0x7E).compactMap { Character(Unicode.Scalar($0)!) } )
        let cyrillic = String( (0x400...0x4FF).compactMap { Character(Unicode.Scalar($0)!) } )
        let katakana = String( (0x30A0...0x30FF).compactMap { Character(Unicode.Scalar($0)!) } )
        let emoji    = String( (0x1F600...0x1F64F).compactMap { Character(Unicode.Scalar($0)!) } )
        
        try db.set(ascii, forKey: "ascii")
        try db.set(cyrillic, forKey: "cyrillic")
        try db.set(katakana, forKey: "katakana")
        try db.set(emoji, forKey: "emoji")
        
        XCTAssertEqual(try db.string(forKey: "ascii"), ascii)
        XCTAssertEqual(try db.string(forKey: "cyrillic"), cyrillic)
        XCTAssertEqual(try db.string(forKey: "katakana"), katakana)
        XCTAssertEqual(try db.string(forKey: "emoji"), emoji)
        
        db["subscript_ascii"] = ascii
        XCTAssertEqual(db["subscript_ascii"], ascii)
        
        db["subscript_cyrillic"] = cyrillic
        XCTAssertEqual(db["subscript_cyrillic"], cyrillic)
        
        db["subscript_katakana"] = katakana
        XCTAssertEqual(db["subscript_katakana"], katakana)
        
        db["subscript_emoji"] = emoji
        XCTAssertEqual(db["subscript_emoji"], emoji)
    }
    
    func testData() throws {
        let data = Data(repeating: 0xFF, count: 1024)
        try db.set(data, forKey: "data")
        XCTAssertEqual(try db.data(forKey: "data"), data)
        
        let rndData = Data((0...2048).map { _ in UInt8.random(in: 0...255) })
        try db.set(rndData, forKey: "rnd_data")
        XCTAssertEqual(try db.data(forKey: "rnd_data"), rndData)
        
        XCTAssertNotEqual(try db.data(forKey: "data"), try db.data(forKey: "rnd_data"))
        
        db["subscript_data"] = data
        XCTAssertEqual(db["subscript_data"], data)
        
        db["subscript_rnd_data"] = rndData
        XCTAssertEqual(db["subscript_rnd_data"], rndData)
    }
}
