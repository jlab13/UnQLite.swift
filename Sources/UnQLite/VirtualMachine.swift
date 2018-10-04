import Foundation
import CUnQLite
import Darwin


// MARK: Jx9 virtual-machine interface.

public final class VirtualMachine {
    private let db: Connection
    private var variableNamesRetain = [UnsafePointer<CChar>]()
    internal var vmPtr: OpaquePointer?

    
    public init(db: Connection, script: String) throws {
        self.db = db
        try db.check(unqlite_compile(db.dbPtr, script, -1, &vmPtr))
    }
    
    deinit {
        unqlite_vm_release(vmPtr)
        self.variableNamesRetain.forEach { $0.deallocate() }
        self.variableNamesRetain.removeAll()
    }
    
    subscript(name: String) -> Any? {
        get {
            return try? self.value(by: name)
        }
        set {
            if let value = newValue {
                try? self.setVariable(value: value, by: name)
            }
        }
    }
    
    public func execute() throws {
        try db.check(unqlite_vm_exec(vmPtr))
    }
    
    /// Set the value of a variable in the Jx9 script.
    public func setVariable<T>(value: T, by name: String) throws {
        let valPtr = try self.createValuePtr(value)
        
        /// Since Jx9 makes a private copy of the value,
        /// we do not need to keep the value alive
        defer {
            try? self.releaseValuePtr(valPtr)
        }

        let nameUtf8 = name.utf8CString
        let namePtr = UnsafeMutablePointer<CChar>.allocate(capacity: nameUtf8.count)
        nameUtf8.withUnsafeBufferPointer { buf in
            namePtr.assign(from: buf.baseAddress!, count: nameUtf8.count)
        }

        //        /// Since Jx9 does not make a private copy of the name,
        //        /// we need to keep it alive by adding it to a retain array
        self.variableNamesRetain.append(namePtr)
        try db.check(unqlite_vm_config_create_var(vmPtr, namePtr, valPtr))
    }
    
    /// Retrieve the value of a variable after the execution of the Jx9 script.
    public func value(by name: String, release: Bool = false) throws -> Any {
        var valPtr: OpaquePointer! = nil
        
        valPtr = unqlite_vm_extract_variable(vmPtr, name)
        if valPtr == nil {
            throw UnQLiteError.notFound
        }

        defer {
            if release { try? self.releaseValuePtr(valPtr) }
        }
        
        return try value(from: valPtr)
    }
    
    /// Retrieve and release the value of a variable after the execution of the Jx9 script.
    public func popValue(by name: String) throws -> Any {
        return try self.value(by: name, release: true)
    }

    
    /// Create an `unqlite_value` corresponding to the given Swift value.
    private func createValuePtr<T>(_ value: T) throws -> OpaquePointer {
        var ptr: OpaquePointer!
        
        if value is [Any] || value is [String: Any] {
            ptr = unqlite_vm_new_array(vmPtr)
        } else {
            ptr = unqlite_vm_new_scalar(vmPtr)
        }
        
        try self.set(value: value, to: ptr)
        return ptr
    }

    /// Release the given `unqlite_value`.
    private func releaseValuePtr(_ ptr: OpaquePointer) throws {
        try db.check(unqlite_vm_release_value(vmPtr, ptr))
    }
    
    private func set<T>(value: T, to ptr: OpaquePointer) throws {
        switch value {
        case let value as [Any]:
            for item in value {
                let itemPtr = try self.createValuePtr(item)
                try db.check(unqlite_array_add_elem(ptr, nil, itemPtr))
                try self.releaseValuePtr(itemPtr)
            }
        case let value as [String: Any]:
            for (key, value) in value {
                let itemPtr = try self.createValuePtr(value)
                try db.check(unqlite_array_add_strkey_elem(ptr, key, itemPtr))
                try self.releaseValuePtr(itemPtr)
            }
        case let value as String:
            try db.check(unqlite_value_string(ptr, value, -1))
        case let value as Int:
            try db.check(unqlite_value_int64(ptr, unqlite_int64(value)))
        case let value as Double:
            try db.check(unqlite_value_double(ptr, value))
        case let value as Bool:
            try db.check(unqlite_value_bool(ptr, value ? 1 : 0))
        default:
            try db.check(unqlite_value_null(ptr))
        }
    }
    
    private func value(from ptr: OpaquePointer) throws -> Any {
        if unqlite_value_is_json_object(ptr) != 0 {
            let userData = VmDictionaryUserData(self, [:])
            let userDataPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(userData).toOpaque())
            try db.check(unqlite_array_walk(ptr, { (keyPtr, valPtr, userDataPtr) in
                guard let keyPtr = keyPtr, let valPtr = valPtr, let userDataPtr = userDataPtr else {
                    return UNQLITE_ABORT
                }
                let userData = Unmanaged<VmDictionaryUserData>.fromOpaque(userDataPtr).takeUnretainedValue()
                do {
                    if let key = try userData.ptr.value(from: keyPtr) as? String {
                        let val = try userData.ptr.value(from: valPtr)
                        userData.instance[key] = val
                        return UNQLITE_OK
                    }
                } catch {}
                return UNQLITE_ABORT
            }, userDataPtr))
            return userData.instance
        }
        
        if unqlite_value_is_json_array(ptr) != 0 {
            let userData = VmArrayUserData(self, [])
            let userDataPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(userData).toOpaque())
            try db.check(unqlite_array_walk(ptr, { (_, valPtr, userDataPtr) in
                guard let valPtr = valPtr, let userDataPtr = userDataPtr else {
                    return UNQLITE_ABORT
                }
                let userData = Unmanaged<VmArrayUserData>.fromOpaque(userDataPtr).takeUnretainedValue()
                do {
                    let val = try userData.ptr.value(from: valPtr)
                    userData.instance.append(val)
                    return UNQLITE_OK
                } catch {}
                return UNQLITE_ABORT
            }, userDataPtr))
            return userData.instance
        }
        
        if unqlite_value_is_string(ptr) != 0 {
            return String(cString: unqlite_value_to_string(ptr, nil))
        }
        
        if unqlite_value_is_float(ptr) != 0 {
            return unqlite_value_to_double(ptr)
        }
        
        if unqlite_value_is_int(ptr) != 0 {
            return Int(unqlite_value_to_int64(ptr))
        }
        
        if unqlite_value_is_bool(ptr) != 0 {
            return unqlite_value_to_bool(ptr) != 0
        }
        
        if unqlite_value_is_null(ptr) != 0 {
            return NSNull()
        }

        throw UnQLiteError.typeCastError
    }
}


// MARK: -
// Class for passing parameters in to C callback function.

private typealias VmDictionaryUserData = CallbackUserData<VirtualMachine, [String: Any]>
private typealias VmArrayUserData = CallbackUserData<VirtualMachine, [Any]>

internal final class CallbackUserData<T, V> {
    let ptr: T
    var instance: V
    
    init(_ vm: T, _ instance: V) {
        self.ptr = vm
        self.instance = instance
    }
}
