import Foundation
import UnQLite


struct Test: Codable {
    let ival = 1
    let dval = 1.1
    let sval = "One"
    let bval = true
//    let arval = [1, 2, 3, 4]
//    let keyval = ["k1": 1, "k2": 2]
}

struct TestCmp: Codable {
    let ival = 1
    let t1 = Test()
    let t2 = Test()
//    let arrayobj = [Test(), Test(), Test()]
}


let val = TestCmp()

do {
    let db = try Connection()
    let vm = try CodableVirtualMachine(db: db, script: "$result = $val;")

    try vm.setVariable(value: val, by: "val")
    try vm.execute()

//    print(try vm.variableValue(by: "result"))
    let result = try vm.variableValue(by: "result", type: TestCmp.self)
    print(result)
} catch {
    print(error)
}
