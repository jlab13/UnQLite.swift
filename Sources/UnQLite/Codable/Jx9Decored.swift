import CUnQLite


func log(function: String = #function, line: Int = #line, val: Any? = nil) {
    if let val = val {
        print("\(function):\(line)\t\(val)")
    } else {
        print("\(function):\(line)")
    }
}


internal final class Jx9Decored: Decoder {
    let codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey: Any] = [:]

    let count: Int? = nil
    var currentIndex: Int = 0

    let db: Connection
    let vmPtr: OpaquePointer

    var ptrs = [OpaquePointer]()
    var ptr: OpaquePointer! { ptrs.last }

    init(db: Connection, vmPtr: OpaquePointer) {
        self.db = db
        self.vmPtr = vmPtr
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        guard unqlite_value_is_scalar(ptr) != 0 else { throw UnQLiteError.typeCastError }
        log()
        return self
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard unqlite_value_is_json_array(ptr) != 0 else { throw UnQLiteError.typeCastError }
        self.currentIndex = 0
        log()

        print(unqlite_array_count(ptr))
        let val = unqlite_array_fetch(ptr, "0", 1)
        print(val as Any)

//        unqlite_array_walk(ptr, {_, valPtr, _ in
//            print(valPtr)
//            return UNQLITE_OK
//        }, nil)

        return self
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        fatalError()
    }

    @inline(__always)
    func releaseLastPtr() {
        if let ptr = self.ptrs.popLast() { unqlite_vm_release_value(vmPtr, ptr) }
    }
}


// MARK: -

extension Jx9Decored: SingleValueDecodingContainer {
    func decodeNil() -> Bool { unqlite_value_is_null(ptr) != 0 }

    func decode(_ type: Bool.Type) throws -> Bool {
        defer { releaseLastPtr() }
        guard unqlite_value_is_bool(ptr) != 0 else { throw UnQLiteError.typeCastError }
        return unqlite_value_to_bool(ptr) != 0
    }

    func decode(_ type: String.Type) throws -> String {
        defer { releaseLastPtr() }
        guard unqlite_value_is_string(ptr) != 0 else { throw UnQLiteError.typeCastError }
        return String(cString: unqlite_value_to_string(ptr, nil))
    }

    func decode(_ type: Double.Type) throws -> Double {
        defer { releaseLastPtr() }
        guard unqlite_value_is_float(ptr) != 0 else { throw UnQLiteError.typeCastError }
        return unqlite_value_to_double(ptr)
    }

    func decode(_ type: Float.Type) throws -> Float {
        defer { releaseLastPtr() }
        guard unqlite_value_is_float(ptr) != 0 else { throw UnQLiteError.typeCastError }
        return type.init(unqlite_value_to_double(ptr))
    }

    func decode(_ type: Int.Type) throws -> Int {
        defer { releaseLastPtr() }
        guard unqlite_value_is_int(ptr) != 0 else { throw UnQLiteError.typeCastError }
        return type.init(unqlite_value_to_int64(ptr))
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        defer { releaseLastPtr() }
        guard unqlite_value_is_int(ptr) != 0 else { throw UnQLiteError.typeCastError }
        return type.init(unqlite_value_to_int(ptr))
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        defer { releaseLastPtr() }
        guard unqlite_value_is_int(ptr) != 0 else { throw UnQLiteError.typeCastError }
        return type.init(unqlite_value_to_int(ptr))
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        defer { releaseLastPtr() }
        guard unqlite_value_is_int(ptr) != 0 else { throw UnQLiteError.typeCastError }
        return unqlite_value_to_int(ptr)
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        defer { releaseLastPtr() }
        guard unqlite_value_is_int(ptr) != 0 else { throw UnQLiteError.typeCastError }
        return unqlite_value_to_int64(ptr)
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        defer { releaseLastPtr() }
        guard unqlite_value_is_int(ptr) != 0 else { throw UnQLiteError.typeCastError }
        return type.init(unqlite_value_to_int(ptr))
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        defer { releaseLastPtr() }
        guard unqlite_value_is_int(ptr) != 0 else { throw UnQLiteError.typeCastError }
        return type.init(unqlite_value_to_int(ptr))
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        defer { releaseLastPtr() }
        guard unqlite_value_is_int(ptr) != 0 else { throw UnQLiteError.typeCastError }
        return type.init(unqlite_value_to_int(ptr))
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        defer { releaseLastPtr() }
        guard unqlite_value_is_int(ptr) != 0 else { throw UnQLiteError.typeCastError }
        return type.init(unqlite_value_to_int64(ptr))
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        defer { releaseLastPtr() }
        guard unqlite_value_is_int(ptr) != 0 else { throw UnQLiteError.typeCastError }
        return type.init(unqlite_value_to_int64(ptr))
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        try type.init(from: self)
    }
}


// MARK: -
extension Jx9Decored: UnkeyedDecodingContainer {
    var isAtEnd: Bool {
        let ptr = unqlite_array_fetch(self.ptr, "\(currentIndex)", -1)
        log(val: ptr)

        guard ptr != nil else { return true }

//        guard let ptr = unqlite_array_fetch(self.ptr, "\(currentIndex)", -1) else { return true }
        self.ptrs.append(ptr!)
        self.currentIndex += 1
        log()
        return false
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError()
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError()
    }

    func superDecoder() throws -> Decoder {
        fatalError()
    }
}
