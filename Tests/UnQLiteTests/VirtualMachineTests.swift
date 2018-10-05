import XCTest
@testable import UnQLite


let arrayInt   = (0..<100).map { $0 }
let arrayDbl01 = arrayInt.map { Double($0) }
let arrayDbl02 = arrayInt.map { Double($0) + 0.5 }
let arrayStr   = arrayInt.map { "String number \($0)" }
let objInt     = Dictionary(uniqueKeysWithValues: zip(arrayStr, arrayInt))
let objDbl01   = Dictionary(uniqueKeysWithValues: zip(arrayStr, arrayDbl01))
let objDbl02   = Dictionary(uniqueKeysWithValues: zip(arrayStr, arrayDbl02))
let objStr     = Dictionary(uniqueKeysWithValues: zip(arrayStr, arrayStr))


final class VirtualMachineTests: BaseTestCase {

    func testGetTypeCast() throws {
        let script = """
        $vm_int = 1;
        $vm_double_01 = 1.0;
        $vm_double_02 = 1.5;
        $vm_true = true;
        $vm_false = false;
        $vm_str = "Hello VM";
        $vm_array = [0,1,2,3,4,5,6,7,8,9];
        $vm_obj = {key1: 1, key2: 2};
        """
        let vm = try db.vm(with: script)
        try vm.execute()

        XCTAssertEqual(try vm.variableValue(by: "vm_true") as? Bool, true)
        XCTAssertEqual(try vm.variableValue(by: "vm_false") as? Bool, false)
        XCTAssertEqual(try vm.variableValue(by: "vm_int") as? Int, 1)
        XCTAssertEqual(try vm.variableValue(by: "vm_double_01") as? Double, 1.0)
        XCTAssertEqual(try vm.variableValue(by: "vm_double_02") as? Double, 1.5)
        XCTAssertEqual(try vm.variableValue(by: "vm_str") as? String, "Hello VM")
        XCTAssertEqual(try vm.variableValue(by: "vm_array") as? [Int], [0,1,2,3,4,5,6,7,8,9])
        XCTAssertEqual(try vm.variableValue(by: "vm_obj") as? [String: Int], ["key1": 1, "key2": 2])
    }

    func testGetObject() throws {
        let script = """
        $obj = {
            vm_int: 1,
            vm_double_01: 1.0,
            vm_double_02: 1.5,
            vm_true: true,
            vm_false: false,
            vm_str: "Hello VM",
            vm_array_int: [0,1,2,3,4,5,6,7,8,9],
            vm_array_dbl: [0.0,1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0],
            vm_obj_int: {key1: 1, key2: 2},
            vm_obj_dbl: {key1: 1.0, key2: 2.0}
        }
        """

        let swObj: [String: Any] = [
            "vm_int": 1,
            "vm_double_01": 1.0,
            "vm_double_02": 1.5,
            "vm_true": true,
            "vm_false": false,
            "vm_str": "Hello VM",
            "vm_array_int": [0,1,2,3,4,5,6,7,8,9],
            "vm_array_dbl": [0.0,1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0],
            "vm_obj_int": ["key1": 1, "key2": 2],
            "vm_obj_dbl": ["key1": 1.0, "key2": 2.0]
        ]

        let vm = try db.vm(with: script)
        try vm.execute()

        let vmObj = try vm.variableValue(by: "obj") as? [String: Any]
        XCTAssertNotNil(vmObj)
        XCTAssertTrue(compareDict(swObj, vmObj!))

        XCTAssertEqual(vmObj?["vm_true"] as? Bool, true)
        XCTAssertEqual(vmObj?["vm_false"] as? Bool, false)
        XCTAssertEqual(vmObj?["vm_int"] as? Int, 1)
        XCTAssertEqual(vmObj?["vm_double_01"] as? Double, 1.0)
        XCTAssertEqual(vmObj?["vm_double_02"] as? Double, 1.5)
        XCTAssertEqual(vmObj?["vm_str"] as? String, "Hello VM")
        XCTAssertEqual(vmObj?["vm_array_int"] as? [Int], [0,1,2,3,4,5,6,7,8,9])
        XCTAssertEqual(vmObj?["vm_array_dbl"] as? [Double], [0,1,2,3,4,5,6,7,8,9])
        XCTAssertEqual(vmObj?["vm_obj_int"] as? [String: Int], ["key1": 1, "key2": 2])
        XCTAssertEqual(vmObj?["vm_obj_dbl"] as? [String: Double], ["key1": 1, "key2": 2])
    }
    
    func testSetTypeCast() throws {
        let script = """
        $vm_true = $sw_true;
        $vm_false = $sw_false;
        $vm_int = $sw_int;
        $vm_double = $sw_double;
        $vm_str = $sw_str;

        $vm_array_int = $sw_array_int;
        $vm_array_dbl_01 = $sw_array_dbl_01;
        $vm_array_dbl_02 = $sw_array_dbl_02;
        $vm_array_str = $sw_array_str;

        $vm_obj_int = $sw_obj_int;
        $vm_obj_dbl_01 = $sw_obj_dbl_01;
        $vm_obj_dbl_02 = $sw_obj_dbl_02;
        $vm_obj_str = $sw_obj_str;
        """

        let sw_true   = true
        let sw_false  = false
        let sw_int    = Int.max
        let sw_double = Double.greatestFiniteMagnitude
        let sw_str    = "Hello VM"

        let vm        = try db.vm(with: script)

        try vm.setVariable(value: sw_true, by: "sw_true")
        try vm.setVariable(value: sw_false, by: "sw_false")
        try vm.setVariable(value: sw_int, by: "sw_int")
        try vm.setVariable(value: sw_double, by: "sw_double")
        try vm.setVariable(value: sw_str, by: "sw_str")

        try vm.setVariable(value: arrayInt, by: "sw_array_int")
        try vm.setVariable(value: arrayDbl01, by: "sw_array_dbl_01")
        try vm.setVariable(value: arrayDbl02, by: "sw_array_dbl_02")
        try vm.setVariable(value: arrayStr, by: "sw_array_str")

        try vm.setVariable(value: objInt, by: "sw_obj_int")
        try vm.setVariable(value: objDbl01, by: "sw_obj_dbl_01")
        try vm.setVariable(value: objDbl02, by: "sw_obj_dbl_02")
        try vm.setVariable(value: objStr, by: "sw_obj_str")

        try vm.execute()

        XCTAssertEqual(try vm.variableValue(by: "vm_true") as? Bool, sw_true)
        XCTAssertEqual(try vm.variableValue(by: "vm_false") as? Bool, sw_false)
        XCTAssertEqual(try vm.variableValue(by: "vm_int") as? Int, sw_int)
        XCTAssertEqual(try vm.variableValue(by: "vm_double") as? Double, sw_double)
        XCTAssertEqual(try vm.variableValue(by: "vm_str") as? String, sw_str)

        XCTAssertEqual(try vm.variableValue(by: "vm_array_int") as? [Int], arrayInt)
        XCTAssertEqual(try vm.variableValue(by: "vm_array_dbl_01") as? [Double], arrayDbl01)
        XCTAssertEqual(try vm.variableValue(by: "vm_array_dbl_02") as? [Double], arrayDbl02)
        XCTAssertEqual(try vm.variableValue(by: "vm_array_str") as? [String], arrayStr)

        XCTAssertEqual(try vm.variableValue(by: "vm_obj_int") as? [String: Int], objInt)
        XCTAssertEqual(try vm.variableValue(by: "vm_obj_dbl_01") as? [String: Double], objDbl01)
        XCTAssertEqual(try vm.variableValue(by: "vm_obj_dbl_02") as? [String: Double], objDbl02)
        XCTAssertEqual(try vm.variableValue(by: "vm_obj_str") as? [String: String], objStr)
    }
    
    func testSetTypeCastAsObj() throws {
        let script = """
        $obj = {
            vm_true: $sw_true,
            vm_false: $sw_false,
            vm_int: $sw_int,
            vm_double: $sw_double,
            vm_str: $sw_str,
            vm_array_int: $sw_array_int,
            vm_array_dbl_01: $sw_array_dbl_01,
            vm_array_dbl_02: $sw_array_dbl_02,
            vm_array_str: $sw_array_str,
            vm_obj_int: $sw_obj_int,
            vm_obj_dbl_01: $sw_obj_dbl_01,
            vm_obj_dbl_02: $sw_obj_dbl_02,
            vm_obj_str: $sw_obj_str,
        }
        """

        let sw_true   = true
        let sw_false  = false
        let sw_int    = Int.max
        let sw_double = Double.greatestFiniteMagnitude
        let sw_str    = "Hello VM"

        let vm = try db.vm(with: script)

        try vm.setVariable(value: sw_true, by: "sw_true")
        try vm.setVariable(value: sw_false, by: "sw_false")
        try vm.setVariable(value: sw_int, by: "sw_int")
        try vm.setVariable(value: sw_double, by: "sw_double")
        try vm.setVariable(value: sw_str, by: "sw_str")

        try vm.setVariable(value: arrayInt, by: "sw_array_int")
        try vm.setVariable(value: arrayDbl01, by: "sw_array_dbl_01")
        try vm.setVariable(value: arrayDbl02, by: "sw_array_dbl_02")
        try vm.setVariable(value: arrayStr, by: "sw_array_str")

        try vm.setVariable(value: objInt, by: "sw_obj_int")
        try vm.setVariable(value: objDbl01, by: "sw_obj_dbl_01")
        try vm.setVariable(value: objDbl02, by: "sw_obj_dbl_02")
        try vm.setVariable(value: objStr, by: "sw_obj_str")

        try vm.execute()

        let swObj: [String: Any] = [
            "vm_true": sw_true,
            "vm_false": sw_false,
            "vm_int": sw_int,
            "vm_double": sw_double,
            "vm_str": sw_str,
            "vm_array_int": arrayInt,
            "vm_array_dbl_01": arrayDbl01,
            "vm_array_dbl_02": arrayDbl02,
            "vm_array_str": arrayStr,
            "vm_obj_int": objInt,
            "vm_obj_dbl_01": objDbl01,
            "vm_obj_dbl_02": objDbl02,
            "vm_obj_str": objStr
        ]

        let vmObj = try vm.variableValue(by: "obj") as? [String: Any]

        XCTAssertNotNil(vmObj)
        XCTAssertTrue(compareDict(swObj, vmObj!))

        XCTAssertEqual(vmObj?["vm_true"] as? Bool, sw_true)
        XCTAssertEqual(vmObj?["vm_false"] as? Bool, sw_false)
        XCTAssertEqual(vmObj?["vm_int"] as? Int, sw_int)
        XCTAssertEqual(vmObj?["vm_double"] as? Double, sw_double)
        XCTAssertEqual(vmObj?["vm_str"] as? String, sw_str)

        XCTAssertEqual(vmObj?["vm_array_int"] as? [Int], arrayInt)
        XCTAssertEqual(vmObj?["vm_array_dbl_01"] as? [Double], arrayDbl01)
        XCTAssertEqual(vmObj?["vm_array_dbl_02"] as? [Double], arrayDbl02)
        XCTAssertEqual(vmObj?["vm_array_str"] as? [String], arrayStr)

        XCTAssertEqual(vmObj?["vm_obj_int"] as? [String: Int], objInt)
        XCTAssertEqual(vmObj?["vm_obj_dbl_01"] as? [String: Double], objDbl01)
        XCTAssertEqual(vmObj?["vm_obj_dbl_02"] as? [String: Double], objDbl02)
        XCTAssertEqual(vmObj?["vm_obj_str"] as? [String: String], objStr)
    }    
}
