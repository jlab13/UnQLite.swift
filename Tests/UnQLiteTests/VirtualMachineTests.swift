import XCTest
@testable import UnQLite


final class VirtualMachineTests: XCTestCase {
    
    static var allTests = [
        ("vm", testVM),
    ]
    
    func testVM() throws {
        let script =
        """
db_create("users");
db_store("users", $list_of_users);
$users_from_db = db_fetch_all('users');
"""
        let list_of_users = [
            ["username": "Huey", "age": 3],
            ["username": "Mickey", "age": 5],
            ]
        
        let vm = try UnQLite().vm(with: script)
        vm["list_of_users"] = list_of_users
        try vm.execute()
        
        print("-------------------")
        print(vm["users_from_db"] ?? "")
        print("-------------------")
    }
}
