import XCTest
@testable import UnQLite


final class KeyValueTests: XCTestCase {

    static var allTests = [
        ("vm", testVM),
//        ("int", testInt),
//        ("float", testFloat),
//        ("double", testDouble),
//        ("subscript", testSubscript)
    ]

    func testVM() throws {
        let script =
"""
$age = 13;
$data = {
    name: "Vasya",
    age: $age
}

"""
//        let list_of_users = [
//            ["username": "Huey", "age": 3],
//            ["username": "Mickey", "age": 5],
//        ]
        
        let db = try UnQLite()
        let vm = try VirtualMachine(db: db, script: script)

//        try vm.setValue(true, forKey: "age")

        try vm.execute()
        
        print("-------------------")
        print(try vm.value(forKey: "age"))
        print(try vm.value(forKey: "data"))
        print("-------------------")
    }
    
//    func testInt() throws {
//        let db = try UnQLite()
//
//        try db.set(0, forKey: "int_zero")
//        XCTAssertEqual(try db.integer(forKey: "int_zero"), 0)
//
//        try db.set(Int.max, forKey: "int_max")
//        XCTAssertEqual(try db.integer(forKey: "int_max"), Int.max)
//
//        try db.set(Int.min, forKey: "int_min")
//        XCTAssertEqual(try db.integer(forKey: "int_min"), Int.min)
//
//        let initialInt = 13
//        try db.setNumeric(initialInt, forKey: "int_generic")
//        let readedInt: Int = try db.numeric(forKey: "int_generic")
//        XCTAssertEqual(initialInt, readedInt)
//    }
//
//    func testFloat() throws {
//        let db = try UnQLite()
//
//        try db.set(Float(0), forKey: "float_zero")
//        XCTAssertEqual(try db.float(forKey: "float_zero"), 0)
//
//        try db.set(Float.greatestFiniteMagnitude, forKey: "float_01")
//        XCTAssertEqual(try db.float(forKey: "float_01"), Float.greatestFiniteMagnitude)
//
//        try db.set(Float.leastNormalMagnitude, forKey: "float_02")
//        XCTAssertEqual(try db.float(forKey: "float_02"), Float.leastNormalMagnitude)
//
//        try db.set(Float.leastNonzeroMagnitude, forKey: "float_03")
//        XCTAssertEqual(try db.float(forKey: "float_03"), Float.leastNonzeroMagnitude)
//
//        let initialFloat: Float = 13.666
//        try db.setNumeric(initialFloat, forKey: "float_generic")
//        let readedFloat: Float = try db.numeric(forKey: "float_generic")
//        XCTAssertEqual(initialFloat, readedFloat)
//    }
//
//    func testDouble() throws {
//        let db = try UnQLite()
//
//        try db.set(Double(0), forKey: "double_zero")
//        XCTAssertEqual(try db.double(forKey: "double_zero"), 0)
//
//        try db.set(Double.greatestFiniteMagnitude, forKey: "double_01")
//        XCTAssertEqual(try db.double(forKey: "double_01"), Double.greatestFiniteMagnitude)
//
//        try db.set(Double.leastNormalMagnitude, forKey: "double_02")
//        XCTAssertEqual(try db.double(forKey: "double_02"), Double.leastNormalMagnitude)
//
//        try db.set(Double.leastNonzeroMagnitude, forKey: "double_03")
//        XCTAssertEqual(try db.double(forKey: "double_03"), Double.leastNonzeroMagnitude)
//
//        let initialDouble: Double = 13.666
//        try db.setNumeric(initialDouble, forKey: "double_generic")
//        let readedDouble: Double = try db.numeric(forKey: "double_generic")
//        XCTAssertEqual(initialDouble, readedDouble)
//    }
//
//    func testSubscript() throws {
//        let db = try UnQLite()
//
//        // Test Int
//        for i in 0..<100 {
//            let key = "key_\(i)"
//            db[key] = i
//            XCTAssertEqual(db[key], i)
//        }
//
//        // Test UInt8
//        for i in 0..<100 {
//            let ui8 = UInt8(i)
//            let key = "key_\(i)"
//            db[key] = ui8
//            XCTAssertEqual(db[key], ui8)
//        }
//
//        // Test UInt16
//        for i in 0..<100 {
//            let ui16 = UInt16(i)
//            let key = "key_\(i)"
//            db[key] = ui16
//            XCTAssertEqual(db[key], ui16)
//        }
//
//        // Test UInt32
//        for i in 0..<100 {
//            let ui32 = UInt32(i)
//            let key = "key_\(i)"
//            db[key] = ui32
//            XCTAssertEqual(db[key], ui32)
//        }
//
//        // Test UInt64
//        for i in 0..<100 {
//            let ui64 = UInt64(i)
//            let key = "key_\(i)"
//            db[key] = ui64
//            XCTAssertEqual(db[key], ui64)
//        }
//
//        // Test Float
//        for i in 0..<100 {
//            let f = Float(i)
//            let key = "key_\(i)"
//            db[key] = f
//            XCTAssertEqual(db[key], f)
//        }
//
//        // Test Double
//        for i in 0..<100 {
//            let d = Double(i)
//            let key = "key_\(i)"
//            db[key] = d
//            XCTAssertEqual(db[key], d)
//        }
//
//    }

}
