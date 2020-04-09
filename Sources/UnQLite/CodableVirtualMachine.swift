import CUnQLite


public final class CodableVirtualMachine {
    private var variableNamesRetain = [UnsafePointer<CChar>]()
    internal let db: Connection
    internal var vmPtr: OpaquePointer!

    public init(db: Connection, script: String) throws {
        self.db = db
        try db.check(unqlite_compile(db.dbPtr, script, -1, &vmPtr))
    }

    deinit {
        unqlite_vm_release(vmPtr)
        self.variableNamesRetain.forEach { $0.deallocate() }
        self.variableNamesRetain.removeAll()
    }

    public func execute() throws {
        try db.check(unqlite_vm_exec(vmPtr))
    }

    public func setVariable<T: Encodable>(value: T, by name: String) throws {
        let encoder = Jx9Encoder(db: db, vmPtr: vmPtr)
        defer {
            encoder.ptrs.forEach(self.releaseValuePtr)
            encoder.ptrs.removeAll()
        }

        try value.encode(to: encoder)

        let nameUtf8 = name.utf8CString
        let namePtr = UnsafeMutablePointer<CChar>.allocate(capacity: nameUtf8.count)
        nameUtf8.withUnsafeBufferPointer { buf in
            namePtr.assign(from: buf.baseAddress!, count: nameUtf8.count)
        }

        self.variableNamesRetain.append(namePtr)
        try db.check(unqlite_vm_config_create_var(vmPtr, namePtr, encoder.ptrs.first))
    }


    // ------------------------------------------------------------------------------

    public func variableValue<T: Decodable>(by name: String, type: T.Type) throws -> T {
        let valPtr = unqlite_vm_extract_variable(vmPtr, name)
        if valPtr == nil { throw UnQLiteError.notFound }

        let decoder = Jx9Decored(db: self.db, vmPtr: self.vmPtr)
        decoder.ptrs.append(valPtr!)

        defer {
            decoder.ptrs.forEach(self.releaseValuePtr)
            decoder.ptrs.removeAll()
        }

        return try type.init(from: decoder)
    }

    public func variableValue(by name: String, release: Bool = false) throws -> Any {
        var valPtr: OpaquePointer! = nil

        valPtr = unqlite_vm_extract_variable(vmPtr, name)
        if valPtr == nil { throw UnQLiteError.notFound }

        defer {
            if release { self.releaseValuePtr(valPtr) }
        }

        return try self.value(from: valPtr)
    }

    internal func releaseValuePtr(_ ptr: OpaquePointer) {
        unqlite_vm_release_value(vmPtr, ptr)
    }


    func value(from ptr: OpaquePointer) throws -> Any {
        if unqlite_value_is_json_object(ptr) != 0 {
            let userData = DictionaryUserData(self, [:])
            let userDataPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(userData).toOpaque())
            try db.check(unqlite_array_walk(ptr, { keyPtr, valPtr, userDataPtr in
                guard let keyPtr = keyPtr, let valPtr = valPtr, let userDataPtr = userDataPtr else {
                    return UNQLITE_ABORT
                }
                let userData = Unmanaged<DictionaryUserData>.fromOpaque(userDataPtr).takeUnretainedValue()
                do {
                    if let key = try userData.vm.value(from: keyPtr) as? String {
                        let val = try userData.vm.value(from: valPtr)
                        userData.instance[key] = val
                        return UNQLITE_OK
                    }
                } catch {}
                return UNQLITE_ABORT
            }, userDataPtr))
            return userData.instance
        }

        if unqlite_value_is_json_array(ptr) != 0 {
            let userData = ArrayUserData(self, [])
            let userDataPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(userData).toOpaque())
            try db.check(unqlite_array_walk(ptr, { _, valPtr, userDataPtr in
                guard let valPtr = valPtr, let userDataPtr = userDataPtr else {
                    return UNQLITE_ABORT
                }
                let userData = Unmanaged<ArrayUserData>.fromOpaque(userDataPtr).takeUnretainedValue()
                do {
                    let val = try userData.vm.value(from: valPtr)
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


private typealias DictionaryUserData = CallbackUserData<[String: Any]>
private typealias ArrayUserData = CallbackUserData<[Any]>

private final class CallbackUserData<T> {
    let vm: CodableVirtualMachine
    var instance: T

    init(_ vm: CodableVirtualMachine, _ instance: T) {
        self.vm = vm
        self.instance = instance
    }
}
