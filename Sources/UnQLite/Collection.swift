import Foundation
import CUnQLite


public final class Collection {
    private let db: Connection
    let name: String

    public init(db: Connection, name: String, create: Bool = true) throws {
        self.db = db
        self.name = name

        if create {
            try self.create()
        }
    }
    
    /// Create the named collection if not exists.
    public func create() throws {
        let script = "if (!db_exists($collection)) { db_create($collection); }"
        try self.execute(script)
    }

    /// Drop the collection and all associated records.
    public func drop() throws {
        let script = "if (db_exists($collection)) { db_drop_collection($collection); }"
        try self.execute(script)
    }
    
    public func lastId() throws -> Int {
        let script = "$result = db_last_record_id($collection);"
        return try self.execute(script)
    }
    
    public func recordCount() throws -> Int {
        return try self.execute("$result = db_total_records($collection);")
    }

    public func fetch(by recordId: Int) throws -> [String: Any] {
        let script = "$result = db_fetch_by_id($collection, $record_id);"
        return try self.execute(script, variables: ["record_id": recordId])
    }

    public func fetchAll() throws -> [[String: Any]] {
        return try self.execute("$result = db_fetch_all($collection);")
    }

    @discardableResult
    public func append(_ record: [String: Any]) throws -> Int {
        let script = "if (db_store($collection, $record)) { $result = db_last_record_id($collection); }"
        return try self.execute(script, variables: ["record": record])
    }

    @discardableResult
    public func append(_ records: [[String: Any]]) throws -> Bool {
        let script = "$result = db_store($collection, $records);"
        return try self.execute(script, variables: ["records": records])
    }
    
    @discardableResult
    public func update(record: [String: Any], by recordId: Int) throws -> Bool {
        let script = "$result = db_update_record($collection, $record_id, $record);"
        return try self.execute(script, variables: ["record_id": recordId, "record": record])
    }

    @discardableResult
    public func delete(by recordId: Int) throws -> Bool {
        let script = "$result = db_drop_record($collection, $record_id);"
        return try self.execute(script, variables: ["record_id": recordId])
    }
    
    public func filter(_ isIncluded: ([String: Any]) throws -> Bool) throws -> [[String: Any]] {
        let fnName = "_filter_fn"
        let script = "$result = db_fetch_all($collection, _filter_fn)"
        let vm = try db.vm(with: script)
        
        unqlite_create_function(vm.vmPtr, fnName, { (context, nargs, values) in
            let context = Context(ctxPtr: context!)
            let values = (0..<nargs).map {
                context.value(from: values!.advanced(by: Int($0)).pointee!)
            }
            print(values)
            return UNQLITE_OK
        }, nil)

        
        try vm.setVariable(value: self.name, by: "collection")
        try vm.execute()
        unqlite_delete_function(vm.vmPtr, fnName)

        guard let result = try vm.value(by: "result", release: true) as? [[String: Any]] else {
            throw UnQLiteError.typeCastError
        }
        return result
    }
    
    private func execute<T>(_ script: String, variables: [String: Any]? = nil) throws -> T {
        let vm = try db.vm(with: script)
        try vm.setVariable(value: self.name, by: "collection")
        try variables?.forEach { (name, value) in
            try vm.setVariable(value: value, by: name)
        }
        try vm.execute()
        
        guard let result = try vm.value(by: "result", release: true) as? T else {
            throw UnQLiteError.typeCastError
        }
        return result
    }
    
    private func execute(_ script: String, variables: [String: Any]? = nil) throws {
        let vm = try db.vm(with: script)
        try vm.setVariable(value: self.name, by: "collection")
        try variables?.forEach { (name, value) in
            try vm.setVariable(value: value, by: name)
        }
        try vm.execute()
    }
}


private typealias CtxDictionaryUserData = CallbackUserData<Context, [String: Any]>
private typealias CtxArrayUserData = CallbackUserData<Context, [Any]>


private final class Context {
    let ctxPtr: OpaquePointer
    
    init(ctxPtr: OpaquePointer) {
        self.ctxPtr = ctxPtr
    }
    
    func value(from ptr: OpaquePointer) -> Any {
        if unqlite_value_is_json_object(ptr) != 0 {
            let userData = CtxDictionaryUserData(self, [:])
            let userDataPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(userData).toOpaque())
            unqlite_array_walk(ptr, { (keyPtr, valPtr, userDataPtr) in
                guard let keyPtr = keyPtr, let valPtr = valPtr, let userDataPtr = userDataPtr else {
                    return UNQLITE_ABORT
                }
                let userData = Unmanaged<CtxDictionaryUserData>.fromOpaque(userDataPtr).takeUnretainedValue()
                if let key = userData.ptr.value(from: keyPtr) as? String {
                    let val = userData.ptr.value(from: valPtr)
                    userData.instance[key] = val
                    return UNQLITE_OK
                }
                return UNQLITE_ABORT
            }, userDataPtr)
            return userData.instance
        }
        
        if unqlite_value_is_json_array(ptr) != 0 {
            let userData = CtxArrayUserData(self, [])
            let userDataPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(userData).toOpaque())
            unqlite_array_walk(ptr, { (_, valPtr, userDataPtr) in
                guard let valPtr = valPtr, let userDataPtr = userDataPtr else {
                    return UNQLITE_ABORT
                }
                let userData = Unmanaged<CtxArrayUserData>.fromOpaque(userDataPtr).takeUnretainedValue()
                let val = userData.ptr.value(from: valPtr)
                userData.instance.append(val)
                return UNQLITE_OK
            }, userDataPtr)
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
        
        return NSNull()
    }

}
