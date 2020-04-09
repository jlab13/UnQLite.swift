import CUnQLite


internal final class Jx9Encoder: Encoder {
    let userInfo: [CodingUserInfoKey: Any] = [:]
    let codingPath: [CodingKey] = []
    let count: Int = 0

    let db: Connection
    let vmPtr: OpaquePointer

    var ptrs = [OpaquePointer]()
    var ptr: OpaquePointer! { ptrs.last }

    init(db: Connection, vmPtr: OpaquePointer) {
        self.db = db
        self.vmPtr = vmPtr
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        self.ptrs.append(unqlite_vm_new_scalar(vmPtr))
        return self
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        self.ptrs.append(unqlite_vm_new_array(vmPtr))
        return self
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        self.ptrs.append(unqlite_vm_new_array(vmPtr))
        return KeyedEncodingContainer(Jx9KeyedEncoding<Key>(self))
    }
}


// MASK: -

extension Jx9Encoder: SingleValueEncodingContainer {
    func encodeNil() throws {
        try db.check(unqlite_value_null(ptr))
    }

    func encode(_ value: Bool) throws {
        try db.check(unqlite_value_bool(ptr, value ? 1 : 0))
    }

    func encode(_ value: String) throws {
        try db.check(unqlite_value_string(ptr, value, -1))
    }

    func encode(_ value: Double) throws {
        try db.check(unqlite_value_double(ptr, value))
    }

    func encode(_ value: Float) throws {
        try db.check(unqlite_value_double(ptr, Double(value)))
    }

    func encode(_ value: Int) throws {
        try db.check(unqlite_value_int64(ptr, unqlite_int64(value)))
    }

    func encode(_ value: Int8) throws {
        try db.check(unqlite_value_int(ptr, Int32(value)))
    }

    func encode(_ value: Int16) throws {
        try db.check(unqlite_value_int(ptr, Int32(value)))
    }

    func encode(_ value: Int32) throws {
        try db.check(unqlite_value_int(ptr, value))
    }

    func encode(_ value: Int64) throws {
        try db.check(unqlite_value_int64(ptr, unqlite_int64(value)))
    }

    func encode(_ value: UInt) throws {
        try db.check(unqlite_value_int64(ptr, unqlite_int64(value)))
    }

    func encode(_ value: UInt8) throws {
        try db.check(unqlite_value_int(ptr, Int32(value)))
    }

    func encode(_ value: UInt16) throws {
        try db.check(unqlite_value_int(ptr, Int32(value)))
    }

    func encode(_ value: UInt32) throws {
        try db.check(unqlite_value_int64(ptr, unqlite_int64(value)))
    }

    func encode(_ value: UInt64) throws {
        if value > Int64.max { throw UnQLiteError.typeCastError }
        try db.check(unqlite_value_int64(ptr, unqlite_int64(value)))
    }

    func encode<T: Encodable>(_ value: T) throws {
        try value.encode(to: self)
        let valPtr = self.ptrs.popLast()
        try self.db.check(unqlite_array_add_elem(self.ptr, nil, valPtr))
        unqlite_vm_release_value(vmPtr, valPtr)
    }
}


// MASK: -

extension Jx9Encoder: UnkeyedEncodingContainer {
    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        fatalError()
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }

    func superEncoder() -> Encoder {
        fatalError()
    }
}


// MASK: -

internal struct Jx9KeyedEncoding<K: CodingKey>: KeyedEncodingContainerProtocol {
    let codingPath: [CodingKey] = []
    let encoder: Jx9Encoder

    init(_ encoder: Jx9Encoder) {
        self.encoder = encoder
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: K)
            -> KeyedEncodingContainer<NestedKey> { fatalError() }

    func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer { fatalError() }

    func superEncoder() -> Encoder { fatalError()
    }

    func superEncoder(forKey key: K) -> Encoder { fatalError() }

    func encodeNil(forKey key: K) throws {}

    func encode<T: Encodable>(_ value: T, forKey key: K) throws {
        try value.encode(to: self.encoder)
        let valPtr = self.encoder.ptrs.popLast()
        try self.encoder.db.check(unqlite_array_add_strkey_elem(encoder.ptrs.last, key.stringValue, valPtr))
        unqlite_vm_release_value(self.encoder.vmPtr, valPtr)
    }
}
