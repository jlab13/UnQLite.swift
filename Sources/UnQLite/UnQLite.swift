import Foundation
import CUnQLite


// MARK: - Error


public struct UnQLiteError: Error, CustomDebugStringConvertible {
    let code: Int32
    let message: String?

    public var debugDescription: String {
        if let message = self.message {
            return "UnQLiteError: \(message) (\(code))"
        }
        return "UnQLiteError: (\(code))"
    }
}


// MARK: - Open mode

public struct UnQLiteOpenMode: OptionSet {
    public let rawValue: CUnsignedInt
    
    public init(rawValue: CUnsignedInt) {
        self.rawValue = rawValue
    }
    
    public static let readOnly = UnQLiteOpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_READONLY))
    public static let readWrite = UnQLiteOpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_READWRITE))
    public static let create = UnQLiteOpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_CREATE))
    public static let exclusive = UnQLiteOpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_EXCLUSIVE))
    public static let tempDb = UnQLiteOpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_TEMP_DB))
    public static let noMutex = UnQLiteOpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_NOMUTEX))
    public static let omitJournaling = UnQLiteOpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_OMIT_JOURNALING))
    public static let inMemory = UnQLiteOpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_IN_MEMORY))
    public static let mmap = UnQLiteOpenMode(rawValue: CUnsignedInt(UNQLITE_OPEN_MMAP))
}


// MARK: - UnQLite DataBase

public class UnQLite {
    internal var dbPtr: OpaquePointer?

    public var version: String {
        return String(cString: unqlite_lib_version())
    }
    
    public init(fileName: String = ":mem:", mode: UnQLiteOpenMode = .inMemory) throws {
        try self.checkCall {
            unqlite_open(&dbPtr, fileName, mode.rawValue)
        }
    }
    
    deinit {
        unqlite_close(dbPtr)
        self.dbPtr = nil
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
        try value.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) in
            try self.checkCall {
                unqlite_kv_store(dbPtr, defaultName , -1, ptr, unqlite_int64(value.count))
            }
        }
    }

    public func data(forKey defaultName: String) throws -> Data {
        let ref = try self.fetch(forKey: defaultName)
        return Data(bytesNoCopy: ref.buf, count: ref.size, deallocator: .free)
    }

    public func encode<T: Encodable>(_ value: T, forKey defaultName: String) throws {
        let data = try JSONEncoder().encode(value)
        try self.set(data, forKey: defaultName)
    }
    
    public func decode<T: Decodable>(_ type: T.Type, forKey defaultName: String) throws -> T {
        let data = try self.data(forKey: defaultName)
        return try JSONDecoder().decode(type, from: data)
    }

    public func set(_ value: String, forKey defaultName: String) throws {
        try value.utf8CString.withUnsafeBytes { bufPtr in
            try self.checkCall {
                unqlite_kv_store(dbPtr, defaultName , -1, bufPtr.baseAddress, unqlite_int64(bufPtr.count))
            }
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
        let size = unqlite_int64(MemoryLayout.size(ofValue: value))
        var ptr = UnsafeMutablePointer<T>.allocate(capacity: 1)
        ptr.initialize(to: value)
        
        defer {
            ptr.deallocate()
        }
        
        try self.checkCall {
            unqlite_kv_store(dbPtr, defaultName , -1, ptr, size)
        }
    }
    
    public func numeric<T: Numeric>(forKey defaultName: String) throws -> T {
        let ref = try self.fetch(forKey: defaultName)
        return ref.buf.load(as: T.self)
    }
    
    public func removeObject(forKey defaultName: String) throws {
        try self.checkCall {
            unqlite_kv_delete(dbPtr, defaultName, -1)
        }
    }

    public func contains(key: String) throws -> Bool {
        var bufSize: unqlite_int64 = 0

        let resultCode = unqlite_kv_fetch(dbPtr, key, -1, nil, &bufSize)
        switch resultCode {
        case UNQLITE_OK:
            return true
        case UNQLITE_NOTFOUND:
            return false
        default:
            throw self.errorMessage(with: resultCode)
        }
    }
    

    // MARK: - Transaction

    public func begin() throws {
        try self.checkCall {
            unqlite_begin(dbPtr)
        }
    }

    public func commit() throws {
        try self.checkCall {
            unqlite_commit(dbPtr)
        }
    }

    public func rollback() throws {
        try self.checkCall {
            unqlite_rollback(dbPtr)
        }
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
    
    public func vm(with script: String) throws -> VirtualMachine {
        return try VirtualMachine(db: self, script: script)
    }
    

    // MARK: - call & check unqlite response code

    internal func checkCall(file: String = #file, line: Int = #line, _ handler: () -> CInt) throws {
        let resultCode = handler()
        guard resultCode == UNQLITE_OK else {
            print("\(file):\(line) code: \(resultCode)")
            throw self.errorMessage(with: resultCode)
        }
    }
    
    // MARK: - Secondary functions

    internal func errorMessage(with resultCode: CInt) -> Error {
        if resultCode == UNQLITE_NOTFOUND {
            return UnQLiteError(code: resultCode, message: "Key not found")
        }
        
        var buf: UnsafeMutablePointer<CChar>?
        var len: CInt = 0
        let msg = unqlite_config_err_log(dbPtr, &buf, &len) == UNQLITE_OK && len > 0
            ? String(bytesNoCopy: buf!, length: Int(len), encoding: .utf8, freeWhenDone: false) : nil
        
        return UnQLiteError(code: resultCode, message: msg)
    }

    private func fetch(forKey defaultName: String) throws -> (buf: UnsafeMutableRawPointer, size: Int) {
        var bufSize: unqlite_int64 = 0
        var buf: UnsafeMutableRawPointer!
        
        try self.checkCall {
            unqlite_kv_fetch(dbPtr, defaultName, -1, buf, &bufSize)
        }
        
        buf = UnsafeMutableRawPointer.allocate(byteCount: Int(bufSize), alignment: 0)
        do {
            try self.checkCall {
                unqlite_kv_fetch(dbPtr, defaultName, -1, buf, &bufSize)
            }
        } catch {
            buf.deallocate()
            throw error
        }
        return (buf, Int(bufSize))
    }

}
