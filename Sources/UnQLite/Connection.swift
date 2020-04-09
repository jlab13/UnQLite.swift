import CUnQLite


// MARK: UnQLite DataBase

public final class Connection {

    public enum ReadonlyMode {
        case no
        case yes

        /// Obtain a read-only memory view of the whole database. You will get significant performance improvements.
        case mmap

        fileprivate var flags: CUnsignedInt {
            switch self {
            case .no:
                return CUnsignedInt(UNQLITE_OPEN_CREATE)
            case .yes:
                return CUnsignedInt(UNQLITE_OPEN_READONLY)
            case .mmap:
                return CUnsignedInt(UNQLITE_OPEN_READONLY | UNQLITE_OPEN_MMAP)
            }
        }
    }

    public enum Location {
        /// A private, in-memory database will be created. The in-memory database will vanish when the database
        /// connection is closed. (equivalent to `.uri(":mem:")`).
        case inMemory

        /// A private, temporary on-disk database will be created. This private database will be automatically
        /// deleted as soon as the database connection is closed.
        case temporary

        /// A database located at the given URI filename (or path).
        /// - Parameter filename: A URI filename
        case uri(String)

        fileprivate func flags(_ uriDefaultFlags: CUnsignedInt) -> CUnsignedInt {
            switch self {
            case .inMemory:
                return CUnsignedInt(UNQLITE_OPEN_IN_MEMORY)
            case .temporary:
                return CUnsignedInt(UNQLITE_OPEN_TEMP_DB)
            default:
                return uriDefaultFlags
            }
        }

        fileprivate var filename: String? {
            switch self {
            case .inMemory:
                return ":mem:"
            case let .uri(uri):
                return uri
            default:
                return nil
            }
        }
    }

    internal var dbPtr: OpaquePointer? = nil

    public var version: String {
        return String(cString: unqlite_lib_version())
    }
    
    public var signature: String {
        return String(cString: unqlite_lib_signature())
    }

    public var ident: String {
        return String(cString: unqlite_lib_ident())
    }

    public var copyright: String {
        return String(cString: unqlite_lib_copyright())
    }

    public var isThreadsafe: Bool {
        return unqlite_lib_is_threadsafe() != 0
    }

    public init(_ location: Location = .inMemory, readonly: ReadonlyMode = .no) throws {
        try self.check(unqlite_open(&dbPtr, location.filename, location.flags(readonly.flags)))
    }

    public convenience init(_ filename: String, readonly: ReadonlyMode = .no) throws {
        try self.init(.uri(filename), readonly: readonly)
    }

    deinit {
        unqlite_close(dbPtr)
        self.dbPtr = nil
    }
    
    public func vm(script: String) throws -> VirtualMachine {
        return try VirtualMachine(db: self, script: script)
    }
    
    public func collection(name: String) throws -> Collection {
        return try Collection(db: self, name: name)
    }

    public subscript<T: Numeric>(key: String) -> T? {
        get {
            return try? self.numeric(forKey: key)
        }
        set {
            if let val = newValue {
                try? self.setNumeric(val, forKey: key)
            } else {
                try? self.removeObject(forKey: key)
            }
        }
    }

    public subscript(key: String) -> String? {
        get {
            return try? self.string(forKey: key)
        }
        set {
            if let val = newValue {
                try? self.set(val, forKey: key)
            } else {
                try? self.removeObject(forKey: key)
            }
        }
    }
    
    public subscript(key: String) -> Data? {
        get {
            return try? self.data(forKey: key)
        }
        set {
            if let val = newValue {
                try? self.set(val, forKey: key)
            } else {
                try? self.removeObject(forKey: key)
            }
        }
    }
    
    public func set(_ value: Data, forKey name: String) throws {
        try value.withUnsafeBytes { (bufPtr: UnsafeRawBufferPointer) -> Void in
            try self.check(unqlite_kv_store(dbPtr, name , -1, bufPtr.baseAddress, unqlite_int64(value.count)))
        }
    }

    public func data(forKey name: String) throws -> Data {
        let ref = try self.fetch(forKey: name)
        return Data(bytesNoCopy: ref.buf, count: ref.size, deallocator: .free)
    }

    public func set(_ value: String, forKey name: String) throws {
        try value.utf8CString.withUnsafeBytes { (bufPtr) -> Void in
            try self.check(unqlite_kv_store(dbPtr, name , -1, bufPtr.baseAddress, unqlite_int64(bufPtr.count)))
        }
    }

    public func string(forKey name: String) throws -> String {
        let ref = try self.fetch(forKey: name)
        return String(bytesNoCopy: ref.buf, length: ref.size - 1, encoding: .utf8, freeWhenDone: true)!
    }
    
    public func set(_ value: Int, forKey name: String) throws {
        try setNumeric(value, forKey: name)
    }
    
    public func integer(forKey name: String) throws -> Int {
        return try self.numeric(forKey: name)
    }

    public func set(_ value: Float, forKey name: String) throws {
        try setNumeric(value, forKey: name)
    }
    
    public func float(forKey name: String) throws -> Float {
        return try self.numeric(forKey: name)
    }

    public func set(_ value: Double, forKey name: String) throws {
        try setNumeric(value, forKey: name)
    }
    
    public func double(forKey name: String) throws -> Double {
        return try self.numeric(forKey: name)
    }

    public func setNumeric<T: Numeric>(_ value: T, forKey name: String) throws {
        var value = value
        let size = unqlite_int64(MemoryLayout.size(ofValue: value))
        try self.check(unqlite_kv_store(dbPtr, name , -1, &value, size))
    }
    
    public func numeric<T: Numeric>(forKey name: String) throws -> T {
        let ref = try self.fetch(forKey: name)
        guard ref.size == MemoryLayout<T>.size else {
            ref.buf.deallocate()
            throw UnQLiteError.typeCastError
        }
        return ref.buf.bindMemory(to: T.self, capacity: 1).pointee
    }
    
    public func removeObject(forKey name: String) throws {
        try self.check(unqlite_kv_delete(dbPtr, name, -1))
    }

    public func contains(key: String) throws -> Bool {
        do {
            var bufSize: unqlite_int64 = 0
            try self.check(unqlite_kv_fetch(dbPtr, key, -1, nil, &bufSize))
            return true
        } catch UnQLiteError.notFound {
            return false
        } catch {
            throw error
        }
    }
    

    // MARK: - Transaction

    public func begin() throws {
        try self.check(unqlite_begin(dbPtr))
    }

    public func commit() throws {
        try self.check(unqlite_commit(dbPtr))
    }

    public func rollback() throws {
        try self.check(unqlite_rollback(dbPtr))
    }
    
    public func transaction(_ block: () throws -> Void) throws {
        try self.begin()
        do {
            try block()
            try self.commit()
        } catch {
            try self.rollback()
            throw error
        }
    }

    // MARK: - Internal functions
    
    @inline(__always)
    internal func check(_ resultCode: CInt, file: String = #file, line: Int = #line) throws {
        guard resultCode != UNQLITE_OK else { return }
        print("EROR: \(file):\(line)")
        throw UnQLiteError(resultCode: resultCode, db: self)
    }

    private func fetch(forKey name: String) throws -> (buf: UnsafeMutableRawPointer, size: Int) {
        var bufSize: unqlite_int64 = 0
        var buf: UnsafeMutableRawPointer!
        
        try self.check(unqlite_kv_fetch(dbPtr, name, -1, buf, &bufSize))
        
        buf = UnsafeMutableRawPointer.allocate(byteCount: Int(bufSize), alignment: 1)
        do {
            try self.check(unqlite_kv_fetch(dbPtr, name, -1, buf, &bufSize))
        } catch {
            buf.deallocate()
            throw error
        }
        return (buf, Int(bufSize))
    }

}
