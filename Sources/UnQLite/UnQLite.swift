import Foundation
import CUnQLite


// MARK: - Error

public struct UnQLiteError: Error, CustomDebugStringConvertible {
    let code: Int32
    let message: String?

    public var debugDescription: String {
        return "UnQLiteError (\(code)): " + (self.message ?? "Unknown")
    }
}


// MARK: - Enum open mode

public enum UnQLiteOpenMode {
    case readOnly
    case readWrite
    case create
    case exclusive
    case tempDb
    case noMutex
    case omitJournaling
    case inMemory
    case mmap
    
    fileprivate var rawMode: UInt32 {
        switch self {
        case .readOnly:
            return UInt32(UNQLITE_OPEN_READONLY)
        case .readWrite:
            return UInt32(UNQLITE_OPEN_READWRITE)
        case .create:
            return UInt32(UNQLITE_OPEN_CREATE)
        case .exclusive:
            return UInt32(UNQLITE_OPEN_EXCLUSIVE)
        case .tempDb:
            return UInt32(UNQLITE_OPEN_TEMP_DB)
        case .noMutex:
            return UInt32(UNQLITE_OPEN_NOMUTEX)
        case .omitJournaling:
            return UInt32(UNQLITE_OPEN_OMIT_JOURNALING)
        case .inMemory:
            return UInt32(UNQLITE_OPEN_IN_MEMORY)
        case .mmap:
            return UInt32(UNQLITE_OPEN_MMAP)
        }
    }
}


// MARK: - UnQLite DataBase

public class UnQLite {
    private var dbRef: OpaquePointer?
    
    public init(fileName: String, mode: UnQLiteOpenMode = .create) throws {
        try self.checkCall {
            unqlite_open(&dbRef, fileName, mode.rawMode)
        }
    }
    
    deinit {
        unqlite_close(dbRef)
        self.dbRef = nil
    }
    
    
    // MARK: - Key Value storage

    public subscript<T: Numeric>(key: String) -> T? {
        get {
            do {
                return try self.numeric(forKey: key)
            } catch {
                return nil
            }
        }
        set {
            do {
                if let val = newValue {
                    try self.setNumeric(val, forKey: key)
                } else {
                    try self.removeObject(forKey: key)
                }
            } catch {}
        }
    }

    public subscript(key: String) -> String? {
        get {
            do {
                return try self.string(forKey: key)
            } catch {
                return nil
            }
        }
        set {
            do {
                if let val = newValue {
                    try self.set(val, forKey: key)
                } else {
                    try self.removeObject(forKey: key)
                }
            } catch {}

        }
    }
    
    public subscript(key: String) -> Data? {
        get {
            do {
                return try self.data(forKey: key)
            } catch {
                return nil
            }
        }
        set {
            do {
                if let val = newValue {
                    try self.set(val, forKey: key)
                } else {
                    try self.removeObject(forKey: key)
                }
            } catch {}
            
        }
    }
    
    public func set(_ value: Data, forKey defaultName: String) throws {
        try value.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) in
            try self.checkCall {
                unqlite_kv_store(dbRef, defaultName , -1, ptr, unqlite_int64(value.count))
            }
        }
    }
    
    public func data(forKey defaultName: String) throws -> Data {
        let ref = try self.fetch(forKey: defaultName)
        return Data(bytesNoCopy: ref.buf, count: ref.size, deallocator: .free)
    }

    public func set(_ value: String, forKey defaultName: String) throws {
        try value.utf8CString.withUnsafeBytes { bufPtr in
            try self.checkCall {
                unqlite_kv_store(dbRef, defaultName , -1, bufPtr.baseAddress, unqlite_int64(bufPtr.count))
            }
        }
    }

    public func string(forKey defaultName: String) throws -> String {
        let ref = try self.fetch(forKey: defaultName)
        return String(bytesNoCopy: ref.buf, length: ref.size, encoding: .utf8, freeWhenDone: true)!
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
            unqlite_kv_store(dbRef, defaultName , -1, ptr, size)
        }
    }
    
    public func numeric<T: Numeric>(forKey defaultName: String) throws -> T {
        let ref = try self.fetch(forKey: defaultName)
        return ref.buf.load(as: T.self)
    }
    
    public func removeObject(forKey defaultName: String) throws {
        try self.checkCall {
            unqlite_kv_delete(dbRef, defaultName, -1)
        }
    }

    public func contains(key: String) throws -> Bool {
        var bufSize: unqlite_int64 = 0
        let buf: UnsafeMutableRawPointer! = nil

        let resultCode = unqlite_kv_fetch(dbRef, key, -1, buf, &bufSize)
        switch resultCode {
        case UNQLITE_OK:
            return true
        case UNQLITE_NOTFOUND:
            return false
        default:
            throw self.error(by: resultCode)
        }
    }
    
    
    // MARK: - Secondary functions
    
    private func fetch(forKey defaultName: String) throws -> (buf: UnsafeMutableRawPointer, size: Int) {
        var bufSize: unqlite_int64 = 0
        var buf: UnsafeMutableRawPointer!
        
        try self.checkCall {
            unqlite_kv_fetch(dbRef, defaultName, -1, buf, &bufSize)
        }
        
        buf = UnsafeMutableRawPointer.allocate(byteCount: Int(bufSize), alignment: 0)
        do {
            try self.checkCall {
                unqlite_kv_fetch(dbRef, defaultName, -1, buf, &bufSize)
            }
        } catch {
            buf.deallocate()
            throw error
        }
        return (buf, Int(bufSize))
    }
    
    private func checkCall(_ handler: () -> Int32) throws {
        let resultCode = handler()
        guard resultCode == UNQLITE_OK else {
            throw self.error(by: resultCode)
        }
    }
    
    private func error(by resultCode: CInt) -> Error {
        if resultCode == UNQLITE_NOTFOUND {
            return UnQLiteError(code: resultCode, message: "Key not found")
        }
        
        var buf: UnsafeMutablePointer<CChar>?
        var len: CInt = 0
        let msg = unqlite_last_error(dbRef, &buf, &len) == UNQLITE_OK && len > 0
            ? String(bytesNoCopy: buf!, length: Int(len), encoding: .ascii, freeWhenDone: false) : nil

        return UnQLiteError(code: resultCode, message: msg)
    }
}
