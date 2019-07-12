import Foundation
import UnQLite


struct Test: Encodable {
    let id: Int = 10
    let qty: Float = 13.23
    let price: Double = 123.13
    let text: String = "Hello"

    let ar = [1,2,3,4]
}


//let val = [1,2,3,4]
//let val = ["k1": 1, "K2": 12.3]
let val = Test()

do {
    let db = try Connection()
    let vm = try CodableVirtualMachine(db: db, script: "$vaInt = $valInt;")

    try vm.setVariable(value: val, by: "valInt")
    try vm.execute()
    print(try vm.variableValue(by: "vaInt"))

} catch {
    print(error)
}
