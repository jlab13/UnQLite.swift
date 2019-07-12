import CUnQLite


internal final class Jx9Encoder: Encoder {
    let db: Connection
    let ownerPtr: OpaquePointer
    var mainPtr: OpaquePointer!

    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]

    init(db: Connection, ownerPtr: OpaquePointer) {
        self.db = db
        self.ownerPtr = ownerPtr
    }

    deinit {
        unqlite_vm_release_value(ownerPtr, mainPtr)
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        print("KeyedEncodingContainer")
        let result = Jx9KeyedEncoding<Key>(self, ownerPtr: ownerPtr)
        self.mainPtr = result.mainPtr
        return KeyedEncodingContainer(result)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        print("UnkeyedEncodingContainer")
        let result = Jx9UnkeyedEncoding(self, ownerPtr: ownerPtr)
        self.mainPtr = result.mainPtr
        return result
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        print("SingleValueEncodingContainer")
        self.mainPtr = unqlite_vm_new_scalar(ownerPtr)
        return self
    }

}


// MARK: -

extension Jx9Encoder: SingleValueEncodingContainer {
    func encodeNil() throws {
        try db.check(unqlite_value_null(mainPtr))
    }

    func encode<T: Encodable>(_ value: T) throws {
        switch value {
        case let value as Bool:
            try db.check(unqlite_value_bool(mainPtr, value ? 1 : 0))
        case let value as String:
            try db.check(unqlite_value_string(mainPtr, value, -1))
        case let value as Double:
            try db.check(unqlite_value_double(mainPtr, value))
        case let value as Float:
            try db.check(unqlite_value_double(mainPtr, Double(value)))

        case let value as Int:
            try db.check(unqlite_value_int64(mainPtr, unqlite_int64(value)))
        case let value as Int8:
            try db.check(unqlite_value_int(mainPtr, Int32(value)))
        case let value as Int16:
            try db.check(unqlite_value_int(mainPtr, Int32(value)))
        case let value as Int32:
            try db.check(unqlite_value_int(mainPtr, value))
        case let value as Int64:
            try db.check(unqlite_value_int64(mainPtr, value))

        case let value as UInt:
            try db.check(unqlite_value_int64(mainPtr, unqlite_int64(value)))
        case let value as UInt8:
            try db.check(unqlite_value_int(mainPtr, Int32(value)))
        case let value as UInt16:
            try db.check(unqlite_value_int(mainPtr, Int32(value)))
        case let value as UInt32:
            try db.check(unqlite_value_int(mainPtr, Int32(value)))
        case let value as UInt64:
            try db.check(unqlite_value_int64(mainPtr, unqlite_int64(value)))
        default:
            fatalError()
        }
    }

}


