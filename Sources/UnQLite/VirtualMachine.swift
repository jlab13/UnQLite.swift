import Foundation
import CUnQLite

// MARK: Jx9 virtual-machine interface.

public class VirtualMachine {
    private let db: UnQLite
    private var keys: Set<String>
    private var vmPtr: OpaquePointer?

    public init(db: UnQLite, script: String) throws {
        self.db = db
        self.keys = Set<String>()
        try db.checkCall {
            unqlite_compile(db.dbPtr, script, -1, &vmPtr)
        }
    }
    
    deinit {
        self.keys.removeAll()
        unqlite_vm_release(vmPtr)
    }
    
    public func execute() throws {
        try db.checkCall {
            unqlite_vm_exec(vmPtr)
        }
    }
    
    /// Set the value of a variable in the Jx9 script.
    public func setValue(_ value: Any, forKey key: String) throws {
        /// Since Jx9 does not make a private copy of the name,
        /// we need to keep it alive by adding it to a Set
        self.keys.insert(key)
        
        let ptr = try self.createValuePtr(value)
        try  db.checkCall {
            unqlite_vm_config_create_var(vmPtr, key, ptr)
        }

        /// Since Jx9 makes a private copy of the value,
        /// we do not need to keep the value alive
        try self.releaseValuePtr(ptr)
    }
    
    /// Retrieve the value of a variable after the execution of the Jx9 script.
    public func value(forKey key: String) throws -> Any {
        var ptr: OpaquePointer! = nil
        ptr = unqlite_vm_extract_variable(vmPtr, key)

        if ptr == nil {
            throw db.error(for: UNQLITE_NOTFOUND)
        }
        
        defer {
            do { try self.releaseValuePtr(ptr) } catch {}
        }
        
        return unqLiteValueToSwift(ptr)
    }
    
    /// Create an `unqlite_value` corresponding to the given Python value.
    internal func createValuePtr(_ value: Any) throws -> OpaquePointer {
        var ptr: OpaquePointer!
        
        if value is Array<Any>, value is Dictionary<String, Any> {
            ptr = unqlite_vm_new_array(vmPtr)
        } else {
            ptr = unqlite_vm_new_scalar(vmPtr)
        }
        try swiftToUnqLiteValue(self, value: value, ptr: ptr)
        return ptr
    }

    /// Release the given `unqlite_value`.
    internal func releaseValuePtr(_ ptr: OpaquePointer) throws {
        try db.checkCall {
            unqlite_vm_release_value(vmPtr, ptr)
        }
    }

}

private class ArrayWrapper {
    var array = [Any]()
}

private class DictWrapper {
    var dict = [String: Any]()
}


func swiftToUnqLiteValue(_ vm: VirtualMachine, value: Any, ptr: OpaquePointer) throws {
    switch value {
    case let value as Bool:
        unqlite_value_bool(ptr, CInt(value.hashValue))
    case let value as Int:
        unqlite_value_int64(ptr, unqlite_int64(value))
    case let value as Double:
        unqlite_value_double(ptr, value)
    case let value as String:
        unqlite_value_string(ptr, value, -1)
    case let value as Array<Any>:
        for item in value {
            let itemPtr = try vm.createValuePtr(item)
            unqlite_array_add_elem(ptr, nil, itemPtr)
            try vm.releaseValuePtr(itemPtr)
        }
    case let value as Dictionary<String, Any>:
        for (key, value) in value {
            let itemPtr = try vm.createValuePtr(value)
            unqlite_array_add_strkey_elem(ptr, key, itemPtr)
            try vm.releaseValuePtr(itemPtr)
        }
    default:
        unqlite_value_null(ptr)
    }
    try vm.releaseValuePtr(ptr)
}


private func unqLiteValueToSwift(_ ptr: OpaquePointer) -> Any {
    if unqlite_value_is_bool(ptr) != 0 {
        return unqlite_value_to_bool(ptr) != 0
    }
    if unqlite_value_is_int(ptr) != 0 {
        return Int(unqlite_value_to_int64(ptr))
    }
    if unqlite_value_is_float(ptr) != 0 {
        return unqlite_value_to_double(ptr)
    }
    if unqlite_value_is_string(ptr) != 0 {
        return String(cString: unqlite_value_to_string(ptr, nil))
    }
    if unqlite_value_is_json_object(ptr) != 0 {
        var info = DictWrapper()
        unqlite_array_walk(ptr, { (keyPtr, valPtr, info) in
            let info = Unmanaged<DictWrapper>.fromOpaque(info!).takeUnretainedValue()
            if let key = unqLiteValueToSwift(keyPtr!) as? String {
                let val = unqLiteValueToSwift(valPtr!)
                info.dict[key] = val
            }
            return UNQLITE_OK
        }, &info)
    }
    if unqlite_value_is_json_array(ptr) != 0 {
        var info = ArrayWrapper()
        unqlite_array_walk(ptr, { (_, valPtr, info) in
            let info = Unmanaged<ArrayWrapper>.fromOpaque(info!).takeUnretainedValue()
            let val = unqLiteValueToSwift(valPtr!)
            info.array.append(val)
            return UNQLITE_OK
        }, &info)
    }

    return 0
}

