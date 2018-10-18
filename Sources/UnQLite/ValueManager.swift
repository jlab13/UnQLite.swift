import Foundation
import CUnQLite


internal protocol ValueManager: class {
    var db: Connection { get }

    func createValuePtr<T>(_ value: T) throws -> OpaquePointer
    func releaseValuePtr(_ ptr: OpaquePointer)

    func setValue<T>(_ value: T, to ptr: OpaquePointer) throws
    func value(from ptr: OpaquePointer) throws -> Any
}


internal extension ValueManager {

    func setValue<T>(_ value: T, to ptr: OpaquePointer) throws {
        switch value {
        case let value as [Any]:
            for item in value {
                let itemPtr = try self.createValuePtr(item)
                try db.check(unqlite_array_add_elem(ptr, nil, itemPtr))
                self.releaseValuePtr(itemPtr)
            }
        case let value as [String: Any]:
            for (key, value) in value {
                let itemPtr = try self.createValuePtr(value)
                try db.check(unqlite_array_add_strkey_elem(ptr, key, itemPtr))
                self.releaseValuePtr(itemPtr)
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

    func value(from ptr: OpaquePointer) throws -> Any {
        if unqlite_value_is_json_object(ptr) != 0 {
            let userData = DictionaryUserData(self, [:])
            let userDataPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(userData).toOpaque())
            try db.check(unqlite_array_walk(ptr, { (keyPtr, valPtr, userDataPtr) in
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
            try db.check(unqlite_array_walk(ptr, { (_, valPtr, userDataPtr) in
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
    let vm: ValueManager
    var instance: T

    init(_ vm: ValueManager, _ instance: T) {
        self.vm = vm
        self.instance = instance
    }
}
