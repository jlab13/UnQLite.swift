import Foundation
import UnQLite


do {
    let db = try Connection()
    let vm = try db.vm(script: "$vaInt = $valInt;")

    try vm.setVariable(value: 10, by: "valInt")
    try vm.execute()
    print(try vm.variableValue(by: "vaInt"))

} catch {
    print(error)
}

