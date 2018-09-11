import Foundation
import CUnQLite

// MARK: Jx9 virtual-machine interface.

public class VirtualMachine {
    private var keys = [UnsafeMutablePointer<Int8>]()
    private var vmPtr: OpaquePointer?
    internal let db: UnQLite

    public init(db: UnQLite, script: String) throws {
        self.db = db
        try db.checkCall {
            unqlite_compile(db.dbPtr, script, -1, &vmPtr)
        }
    }
    
    deinit {
        unqlite_vm_release(vmPtr)
        self.keys.forEach { $0.deallocate() }
        self.keys.removeAll()
    }
    
    public func execute() throws {
        try db.checkCall {
            unqlite_vm_exec(vmPtr)
        }
    }
    
    /// Set the value of a variable in the Jx9 script.
    public func setValue(_ value: Any, forKey key: String) throws {
        let valPtr = try self.createValuePtr(value)
        
        /// Since Jx9 makes a private copy of the value,
        /// we do not need to keep the value alive
        defer {
            try? self.releaseValuePtr(valPtr)
        }
        
        let keyLength = key.utf8.count
        let keyPtr = UnsafeMutablePointer<Int8>.allocate(capacity: keyLength)
        keyPtr.assign(from: key, count: keyLength)
        
        /// Since Jx9 does not make a private copy of the name,
        /// we need to keep it alive by adding it to a array
        self.keys.append(keyPtr)

        try db.checkCall {
            unqlite_vm_config_create_var(vmPtr, keyPtr, valPtr)
        }
    }
    
    /// Retrieve the value of a variable after the execution of the Jx9 script.
    public func value(forKey key: String) throws -> Any {
        var valPtr: OpaquePointer! = nil
        
        valPtr = unqlite_vm_extract_variable(vmPtr, key)
        if valPtr == nil {
            throw db.errorMessage(with: UNQLITE_NOTFOUND)
        }
        
        defer {
            try? self.releaseValuePtr(valPtr)
        }
        return try unqLiteValueToSwift(self, valPtr)
    }
    
    /// Create an `unqlite_value` corresponding to the given Python value.
    internal func createValuePtr(_ value: Any) throws -> OpaquePointer {
        var ptr: OpaquePointer!
        
        if value is [Any] || value is [String: Any] {
            ptr = unqlite_vm_new_array(vmPtr)
            print("unqlite_vm_new_array: \(ptr)")
        } else {
            ptr = unqlite_vm_new_scalar(vmPtr)
            print("unqlite_vm_new_scalar: \(ptr)")
        }
        try swiftToUnqLiteValue(self, value: value, ptr: ptr)
        return ptr
    }

    /// Release the given `unqlite_value`.
    internal func releaseValuePtr(_ ptr: OpaquePointer) throws {
        print("unqlite_vm_release_value: \(ptr)")
        try db.checkCall {
            unqlite_vm_release_value(vmPtr, ptr)
        }
    }
    
    internal func checkCall(file: String = #file, line: Int = #line, _ handler: () -> CInt) throws {
        try self.db.checkCall(file: file, line: line, handler)
    }

}

private final class CallbackUserData {
    let vm: VirtualMachine
    var array: [Any]!
    var dict:  [String: Any]!

    init(_ vm: VirtualMachine, isArray: Bool) {
        self.vm = vm
        if isArray {
            self.array = []
        } else {
            self.dict = [:]
        }
    }
}

func swiftToUnqLiteValue(_ vm: VirtualMachine, value: Any, ptr: OpaquePointer) throws {
    switch value {
    case let value as Bool:
        unqlite_value_bool(ptr, CInt(value.hashValue))
        print("unqlite_value_bool: \(ptr)")
    case let value as Int:
        unqlite_value_int64(ptr, unqlite_int64(value))
        print("unqlite_value_int64: \(ptr)")
    case let value as Double:
        unqlite_value_double(ptr, value)
        print("unqlite_value_double: \(ptr)")
    case let value as String:
        unqlite_value_string(ptr, value, -1)
        print("unqlite_value_string: \(ptr)")
    case let value as [Any]:
        for item in value {
            let itemPtr = try vm.createValuePtr(item)
            try vm.db.checkCall { unqlite_array_add_elem(ptr, nil, itemPtr) }
            try vm.releaseValuePtr(itemPtr)
        }
    case let value as [String: Any]:
        for (key, value) in value {
            let itemPtr = try vm.createValuePtr(value)
            try vm.db.checkCall { unqlite_array_add_strkey_elem(ptr, key, itemPtr) }
            try vm.releaseValuePtr(itemPtr)
        }
    default:
        unqlite_value_null(ptr)
        print("unqlite_value_null: \(ptr)")
    }
}


private func unqLiteValueToSwift(_ vm: VirtualMachine, _ ptr: OpaquePointer) throws -> Any {
    if unqlite_value_is_json_object(ptr) != 0 {
        let userData = CallbackUserData(vm, isArray: false)
        let userDataPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(userData).toOpaque())
        try vm.checkCall {
            unqlite_array_walk(ptr, { (keyPtr, valPtr, userDataPtr) in
                guard let keyPtr = keyPtr, let valPtr = valPtr, let userDataPtr = userDataPtr else {
                    return UNQLITE_ABORT
                }
                let userData = Unmanaged<CallbackUserData>.fromOpaque(userDataPtr).takeUnretainedValue()
                do {
                    if let key = try unqLiteValueToSwift(userData.vm, keyPtr) as? String {
                        let val = try unqLiteValueToSwift(userData.vm, valPtr)
                        userData.dict[key] = val
                        return UNQLITE_OK
                    }
                } catch {}
                return UNQLITE_ABORT
            }, userDataPtr)
        }
        return userData.dict!
    }

    if unqlite_value_is_json_array(ptr) != 0 {
        let userData = CallbackUserData(vm, isArray: true)
        let userDataPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(userData).toOpaque())
        try vm.checkCall {
            unqlite_array_walk(ptr, { (_, valPtr, userDataPtr) in
                guard let valPtr = valPtr, let userDataPtr = userDataPtr else {
                    return UNQLITE_ABORT
                }
                let userData = Unmanaged<CallbackUserData>.fromOpaque(userDataPtr).takeUnretainedValue()
                do {
                    let val = try unqLiteValueToSwift(userData.vm, valPtr)
                    userData.array.append(val)
                    return UNQLITE_OK
                } catch {}
                return UNQLITE_ABORT
            }, userDataPtr)
        }
        return userData.array!
    }
    
    if unqlite_value_is_string(ptr) != 0 {
        return String(cString: unqlite_value_to_string(ptr, nil))
    }
    
    if unqlite_value_is_int(ptr) != 0 {
        return Int(unqlite_value_to_int64(ptr))
    }
    
    if unqlite_value_is_float(ptr) != 0 {
        return unqlite_value_to_double(ptr)
    }
    
    if unqlite_value_is_bool(ptr) != 0 {
        return unqlite_value_to_bool(ptr) != 0
    }
    
    if unqlite_value_is_null(ptr) != 0 {
        return NSNull()
    }

    // TODO: throw exception
    return NSNull()
}

