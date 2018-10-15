import Foundation
import CUnQLite


// MARK: - Open mode

public struct OpenMode: OptionSet {
    public let rawValue: CUnsignedInt
    
    public init(rawValue: CUnsignedInt) {
        self.rawValue = rawValue
    }
    
    public static let readOnly = OpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_READONLY))
    public static let readWrite = OpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_READWRITE))
    public static let create = OpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_CREATE))
    public static let exclusive = OpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_EXCLUSIVE))
    public static let tempDb = OpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_TEMP_DB))
    public static let noMutex = OpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_NOMUTEX))
    public static let omitJournaling = OpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_OMIT_JOURNALING))
    public static let inMemory = OpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_IN_MEMORY))
    public static let mmap = OpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_MMAP))
}


// MARK: - UnQLite DataBase

public final class Connection {
    internal var dbPtr: OpaquePointer?

    public static var version: String {
        return String(cString: unqlite_lib_version())
    }
    
    public static var signature: String {
        return String(cString: unqlite_lib_signature())
    }

    public static var ident: String {
        return String(cString: unqlite_lib_ident())
    }

    public static var copyright: String {
        return String(cString: unqlite_lib_copyright())
    }

    public static var isThreadsafe: Bool {
        return unqlite_lib_is_threadsafe() != 0
    }
    
    public init(fileName: String = ":mem:", mode: OpenMode = .inMemory) throws {
        try self.check(unqlite_open(&dbPtr, fileName, mode.rawValue))
    }
    
    deinit {
        unqlite_close(dbPtr)
        self.dbPtr = nil
    }
    
    public func vm(with script: String) throws -> VirtualMachine {
        return try VirtualMachine(db: self, script: script)
    }
    
    public func collection(with name: String) throws -> Collection {
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
    
    public func set(_ value: Data, forKey defaultName: String) throws {
        try value.withUnsafeBytes { (bufPtr) -> Void in
            try self.check(unqlite_kv_store(dbPtr, defaultName , -1, bufPtr, unqlite_int64(value.count)))
        }
    }

    public func data(forKey defaultName: String) throws -> Data {
        let ref = try self.fetch(forKey: defaultName)
        return Data(bytesNoCopy: ref.buf, count: ref.size, deallocator: .free)
    }

    public func set(_ value: String, forKey defaultName: String) throws {
        try value.utf8CString.withUnsafeBytes { (bufPtr)  -> Void in
            try self.check(unqlite_kv_store(dbPtr, defaultName , -1, bufPtr.baseAddress, unqlite_int64(bufPtr.count)))
        }
    }

    public func string(forKey defaultName: String) throws -> String {
        let ref = try self.fetch(forKey: defaultName)
        return String(bytesNoCopy: ref.buf, length: ref.size - 1, encoding: .utf8, freeWhenDone: true)!
    }
    
    public func set(_ value: Int, forKey defaultName: String) throws {
        try setNumeric(value, forKey: defaultName)
    }
    
    public func integer(forKey defaultName: String) throws -> Int {
        return try self.numeric(forKey: defaultName)
    }

    public func set(_ value: Float, forKey defaultName: String) throws {
        try setNumeric(value, forKey: defaultName)
    }
    
    public func float(forKey defaultName: String) throws -> Float {
        return try self.numeric(forKey: defaultName)
    }

    public func set(_ value: Double, forKey defaultName: String) throws {
        try setNumeric(value, forKey: defaultName)
    }
    
    public func double(forKey defaultName: String) throws -> Double {
        return try self.numeric(forKey: defaultName)
    }

    public func setNumeric<T: Numeric>(_ value: T, forKey defaultName: String) throws {
        var value = value
        let size = unqlite_int64(MemoryLayout.size(ofValue: value))
        try self.check(unqlite_kv_store(dbPtr, defaultName , -1, &value, size))
    }
    
    public func numeric<T: Numeric>(forKey defaultName: String) throws -> T {
        let ref = try self.fetch(forKey: defaultName)
        guard ref.size == MemoryLayout<T>.size else {
            ref.buf.deallocate()
            throw UnQLiteError.typeCastError
        }
        return ref.buf.bindMemory(to: T.self, capacity: 1).pointee
    }
    
    public func removeObject(forKey defaultName: String) throws {
        try self.check(unqlite_kv_delete(dbPtr, defaultName, -1))
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

    
    // MARK: - Secondary functions
    
    @inline(__always)
    internal func check(_ resultCode: CInt, file: String = #file, line: Int = #line) throws {
        guard resultCode != UNQLITE_OK else {
            return
        }
        print("EROR: \(file):\(line)")
        throw UnQLiteError(resultCode: resultCode, db: self)
    }

    private func fetch(forKey defaultName: String) throws -> (buf: UnsafeMutableRawPointer, size: Int) {
        var bufSize: unqlite_int64 = 0
        var buf: UnsafeMutableRawPointer!
        
        try self.check(unqlite_kv_fetch(dbPtr, defaultName, -1, buf, &bufSize))
        
        buf = UnsafeMutableRawPointer.allocate(byteCount: Int(bufSize), alignment: 1)
        do {
            try self.check(unqlite_kv_fetch(dbPtr, defaultName, -1, buf, &bufSize))
        } catch {
            buf.deallocate()
            throw error
        }
        return (buf, Int(bufSize))
    }

}
