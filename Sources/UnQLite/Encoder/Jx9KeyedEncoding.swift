import CUnQLite


internal final class Jx9KeyedEncoding<K: CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = K

    let encoder: Jx9Encoder
    let ownerPtr: OpaquePointer
    lazy var mainPtr: OpaquePointer = unqlite_vm_new_array(ownerPtr)

    var codingPath: [CodingKey] = []

    init(_ encoder: Jx9Encoder, ownerPtr: OpaquePointer) {
        self.encoder = encoder
        self.ownerPtr = ownerPtr
    }

    func encodeNil(forKey key: K) throws {
        let itemPtr = unqlite_vm_new_scalar(ownerPtr)
        defer { unqlite_vm_release_value(ownerPtr, itemPtr) }
        try encoder.db.check(unqlite_value_null(itemPtr))

    }

    func encode<T: Encodable>(_ value: T, forKey key: K) throws {
        let itemPtr = unqlite_vm_new_scalar(ownerPtr)!
        defer { unqlite_vm_release_value(ownerPtr, itemPtr) }

        switch value {
        case let value as Bool:
            try encoder.db.check(unqlite_value_bool(itemPtr, value ? 1 : 0))
        case let value as String:
            try encoder.db.check(unqlite_value_string(itemPtr, value, -1))
        case let value as Double:
            try encoder.db.check(unqlite_value_double(itemPtr, value))
        case let value as Float:
            try encoder.db.check(unqlite_value_double(itemPtr, Double(value)))

        case let value as Int:
            try encoder.db.check(unqlite_value_int64(itemPtr, unqlite_int64(value)))
        case let value as Int8:
            try encoder.db.check(unqlite_value_int(itemPtr, Int32(value)))
        case let value as Int16:
            try encoder.db.check(unqlite_value_int(itemPtr, Int32(value)))
        case let value as Int32:
            try encoder.db.check(unqlite_value_int(itemPtr, value))
        case let value as Int64:
            try encoder.db.check(unqlite_value_int64(itemPtr, value))

        case let value as UInt:
            try encoder.db.check(unqlite_value_int64(itemPtr, unqlite_int64(value)))
        case let value as UInt8:
            try encoder.db.check(unqlite_value_int(itemPtr, Int32(value)))
        case let value as UInt16:
            try encoder.db.check(unqlite_value_int(itemPtr, Int32(value)))
        case let value as UInt32:
            try encoder.db.check(unqlite_value_int(itemPtr, Int32(value)))
        case let value as UInt64:
            try encoder.db.check(unqlite_value_int64(itemPtr, unqlite_int64(value)))
        default:
            try value.encode(to: Jx9Encoder(db: encoder.db, ownerPtr: itemPtr))
        }

        try encoder.db.check(unqlite_array_add_strkey_elem(mainPtr, key.stringValue, itemPtr))
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> {
        return self.encoder.container(keyedBy: keyType)
    }

    func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        return self.encoder.unkeyedContainer()
    }

    func superEncoder() -> Encoder {
        return self.encoder
    }

    func superEncoder(forKey key: K) -> Encoder {
        return self.encoder
    }

}

