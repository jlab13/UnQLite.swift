import CUnQLite


// MARK: Jx9 virtual-machine interface.

public final class VirtualMachine: ValueManager {
    private var outputCallback: ((String) -> Void)?
    internal let db: Connection
    internal var vmPtr: OpaquePointer!

    private var variableNamesRetain = [UnsafePointer<CChar>]()

    public init(db: Connection, script: String) throws {
        self.db = db
        try db.check(unqlite_compile(db.dbPtr, script, -1, &vmPtr))
    }
    
    deinit {
        unqlite_vm_release(vmPtr)
        self.variableNamesRetain.forEach { $0.deallocate() }
        self.variableNamesRetain.removeAll()
    }
    
    public subscript(name: String) -> Any? {
        get {
            return try? self.variableValue(by: name)
        }
        set {
            if let value = newValue {
                try? self.setVariable(value: value, by: name)
            }
        }
    }
    
    /// This function is used to install a VM output consumer callback.
    /// That is, an user defined closure responsible of consuming the VM output such
    /// as redirecting it (i.e. The VM output) to STDOUT or sending it back to the connected peer.
    public func setOutput(_ callback: @escaping ((String) -> Void)) throws {
        self.outputCallback = callback

        let userDataPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        try db.check(unqlite_vm_config_output(vmPtr, { pOutPut, nLen, pUserData in
            guard let pUserData = pUserData,
                let msg = String(bytesNoCopy: pOutPut!, length: Int(nLen), encoding: .utf8, freeWhenDone: false) else {
                    return UNQLITE_ABORT
            }
            let vm = Unmanaged<VirtualMachine>.fromOpaque(pUserData).takeUnretainedValue()
            vm.outputCallback?(msg)
            return UNQLITE_OK
        }, userDataPtr))
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
            self.releaseValuePtr(valPtr)
        }

        let nameUtf8 = name.utf8CString
        let namePtr = UnsafeMutablePointer<CChar>.allocate(capacity: nameUtf8.count)
        nameUtf8.withUnsafeBufferPointer { buf in
            namePtr.assign(from: buf.baseAddress!, count: nameUtf8.count)
        }

        /// Since Jx9 does not make a private copy of the name,
        /// we need to keep it alive by adding it to a retain array
        self.variableNamesRetain.append(namePtr)
        try db.check(unqlite_vm_config_create_var(vmPtr, namePtr, valPtr))
    }
    
    /// Retrieve the value of a variable after the execution of the Jx9 script.
    public func variableValue(by name: String, release: Bool = false) throws -> Any {
        var valPtr: OpaquePointer! = nil
        
        valPtr = unqlite_vm_extract_variable(vmPtr, name)
        if valPtr == nil {
            throw UnQLiteError.notFound
        }

        defer {
            if release { self.releaseValuePtr(valPtr) }
        }
        
        return try value(from: valPtr)
    }
    
    /// Retrieve and release the value of a variable after the execution of the Jx9 script.
    public func popValue(by name: String) throws -> Any {
        return try self.variableValue(by: name, release: true)
    }
    
    /// Create an `unqlite_value` corresponding to the given Swift value.
    internal func createValuePtr<T>(_ value: T) throws -> OpaquePointer {
        var ptr: OpaquePointer!

        if value is [Any] || value is [String: Any] {
            ptr = unqlite_vm_new_array(vmPtr)
        } else {
            ptr = unqlite_vm_new_scalar(vmPtr)
        }

        try self.setValue(value, to: ptr)
        return ptr
    }

    /// Release the given `unqlite_value`.
    internal func releaseValuePtr(_ ptr: OpaquePointer) {
        unqlite_vm_release_value(vmPtr, ptr)
    }

}
