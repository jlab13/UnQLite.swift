import Foundation
import UnQLite


struct Test: Encodable {
    let ival = 1
    let dval = 1.1
    let sval = "One"
    let bval = true
    let arval = [1, 2, 3, 4]
    let keyval = ["k1": 1, "k2": 2]
}

struct TestCmp: Encodable {
//    let ival = 1
//    let t1 = Test()
//    let t2 = Test()
    let arrayobj = [Test(), Test(), Test()]
}


let val = [1, 2, 3]

do {
    let db = try Connection()
    let vm = try CodableVirtualMachine(db: db, script: "$result = $val;")

    try vm.setVariable(value: val, by: "val")
    try vm.execute()

//    print(try vm.variableValue(by: "result"))
    print(try vm.variableValue(by: "result", type: [Int].self))
} catch {
    print(error)
}
