import XCTest
@testable import UnQLite


final class VirtualMachineTests: XCTestCase {
    static var allTests = [
        ("getTypeCast", testGetTypeCast),
        ("getObject", testGetObject),
        ("setTypeCast", testSetTypeCast),
    ]

    var db: Connection!

    override func setUp() {
        super.setUp()
        db = try! Connection()
    }

    func testGetTypeCast() throws {
        let script = """
        $vm_int = 1;
        $vm_double = 1.1;
        $vm_true = true;
        $vm_false = false;
        $vm_str = "Hello VM";
        $vm_array = [0,1,2,3,4,5,6,7,8,9];
        $vm_obj = {key1: 1, key2: 2};
        """
        let vm = try db.vm(with: script)
        try vm.execute()

        XCTAssertEqual(try vm.value(by: "vm_true") as? Bool, true)
        XCTAssertEqual(try vm.value(by: "vm_false") as? Bool, false)
        XCTAssertEqual(try vm.value(by: "vm_int") as? Int, 1)
        XCTAssertEqual(try vm.value(by: "vm_double") as? Double, 1.1)
        XCTAssertEqual(try vm.value(by: "vm_str") as? String, "Hello VM")
        XCTAssertEqual(try vm.value(by: "vm_array") as? [Int], [0,1,2,3,4,5,6,7,8,9])
        XCTAssertEqual(try vm.value(by: "vm_obj") as? [String: Int], ["key1": 1, "key2": 2])
    }

    func testGetObject() throws {
        let script = """
        $obj = {
            vm_int: 1,
            vm_double: 1.1,
            vm_true: true,
            vm_false: false,
            vm_str: "Hello VM",
            vm_array: [0,1,2,3,4,5,6,7,8,9],
            vm_obj: {key1: 1, key2: 2}
        }
        """
        let vm = try db.vm(with: script)
        try vm.execute()

        let obj = try vm.value(by: "obj") as? [String: Any]
        XCTAssertNotNil(obj)
        
        XCTAssertEqual(obj?["vm_true"] as? Bool, true)
        XCTAssertEqual(obj?["vm_false"] as? Bool, false)
        XCTAssertEqual(obj?["vm_int"] as? Int, 1)
        XCTAssertEqual(obj?["vm_double"] as? Double, 1.1)
        XCTAssertEqual(obj?["vm_str"] as? String, "Hello VM")
        XCTAssertEqual(obj?["vm_array"] as? [Int], [0,1,2,3,4,5,6,7,8,9])
        XCTAssertEqual(obj?["vm_obj"] as? [String: Int], ["key1": 1, "key2": 2])
    }
    
    func testSetTypeCastAsObj() throws {
        let script = """
        $obj = {
            vm_true: $sw_true,
            vm_false: $sw_false,
            vm_int: $sw_int,
            vm_double: $sw_double,
            vm_str: $sw_str,
            vm_array: $sw_array,
            vm_obj: $sw_obj,
        }
        """
        
        let sw_true = true
        let sw_false = false
        let sw_int = Int.max
        let sw_double = Double.greatestFiniteMagnitude
        let sw_str = "Hello VM"
        let sw_array = [0,1,2,3,4,5,6,7,8,9]
        let sw_obj = ["key1": 1, "key2": 2]
        
        let vm = try db.vm(with: script)

        try vm.setVariable(value: sw_true, by: "sw_true")
        try vm.setVariable(value: sw_false, by: "sw_false")
        try vm.setVariable(value: sw_int, by: "sw_int")
        try vm.setVariable(value: sw_double, by: "sw_double")
        try vm.setVariable(value: sw_str, by: "sw_str")
        try vm.setVariable(value: sw_array, by: "sw_array")
        try vm.setVariable(value: sw_obj, by: "sw_obj")
        
        try vm.execute()
        
        let obj = try vm.value(by: "obj") as? [String: Any]
        XCTAssertNotNil(obj)
        
        XCTAssertEqual(obj?["vm_true"] as? Bool, sw_true)
        XCTAssertEqual(obj?["vm_false"] as? Bool, sw_false)
        XCTAssertEqual(obj?["vm_int"] as? Int, sw_int)
        XCTAssertEqual(obj?["vm_double"] as? Double, sw_double)
        XCTAssertEqual(obj?["vm_str"] as? String, sw_str)
        XCTAssertEqual(obj?["vm_array"] as? [Int], sw_array)
        XCTAssertEqual(obj?["vm_obj"] as? [String: Int], sw_obj)
    }
    
    func testSetTypeCast() throws {
        let script = """
        $vm_true = $sw_true;
        $vm_false = $sw_false;
        $vm_int = $sw_int;
        $vm_double = $sw_double;
        $vm_str = $sw_str;
        $vm_array = $sw_array;
        $vm_obj = $sw_obj;
        """
        
        let sw_true = true
        let sw_false = false
        let sw_int = Int.max
        let sw_double = Double.greatestFiniteMagnitude
        let sw_str = "Hello VM"
        let sw_array = [0,1,2,3,4,5,6,7,8,9]
        let sw_obj = ["key1": 1, "key2": 2]

        let vm = try db.vm(with: script)

        try vm.setVariable(value: sw_true, by: "sw_true")
        try vm.setVariable(value: sw_false, by: "sw_false")
        try vm.setVariable(value: sw_int, by: "sw_int")
        try vm.setVariable(value: sw_double, by: "sw_double")
        try vm.setVariable(value: sw_str, by: "sw_str")
        try vm.setVariable(value: sw_array, by: "sw_array")
        try vm.setVariable(value: sw_obj, by: "sw_obj")

        try vm.execute()
        
        XCTAssertEqual(try vm.value(by: "vm_true") as? Bool, sw_true)
        XCTAssertEqual(try vm.value(by: "vm_false") as? Bool, sw_false)
        XCTAssertEqual(try vm.value(by: "vm_int") as? Int, sw_int)
        XCTAssertEqual(try vm.value(by: "vm_double") as? Double, sw_double)
        XCTAssertEqual(try vm.value(by: "vm_str") as? String, sw_str)
        XCTAssertEqual(try vm.value(by: "vm_array") as? [Int], sw_array)
        XCTAssertEqual(try vm.value(by: "vm_obj") as? [String: Int], sw_obj)
    }

}
