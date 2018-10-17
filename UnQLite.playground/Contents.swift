import UnQLite

let script = """

vtf_this("/");

"""

do {
    let db = try Connection()
//    db.isThreadsafe

    let vm = try db.vm(with: script)
    try vm.setOutput { print(">> \($0)") }
    
    try vm.execute()
} catch {
    print(error)
}
