import CUnQLite


public typealias FilterCallback = ([String: Any]) -> Bool
internal let rec = "$rec"


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
    
    @discardableResult
    public func append(_ record: [String: Any]) throws -> Int {
        let script = "if (db_store($collection, $record)) { $result = db_last_record_id($collection); }"
        return try self.execute(script, variables: ["record": record])
    }

    @discardableResult
    public func store(_ values: ExpressionValuePair ...) throws -> Int {
        let record = Dictionary(uniqueKeysWithValues: values.compactMap { item -> (String, Any)? in
            guard let keyPath = item.key.keyPath else { return nil }
            return (keyPath, item.value)
        })
        return try self.append(record)
    }

    @discardableResult
    public func store(_ records: [[String: Any]]) throws -> Bool {
        let script = "$result = db_store($collection, $records);"
        return try self.execute(script, variables: ["records": records])
    }

    @discardableResult
    public func update(recordId: Int, _ record: [String: Any]) throws -> Bool {
        let script = "$result = db_update_record($collection, $record_id, $record);"
        return try self.execute(script, variables: ["record_id": recordId, "record": record])
    }

    @discardableResult
    public func update(recordId: Int, _ values: ExpressionValuePair ...) throws -> Bool {
        let record = Dictionary(uniqueKeysWithValues: values.compactMap { item -> (String, Any)? in
            guard let keyPath = item.key.keyPath else { return nil }
            return (keyPath, item.value)
        })
        return try self.update(recordId: recordId, record)
    }

    @discardableResult
    public func delete(recordId: Int) throws -> Bool {
        let script = "$result = db_drop_record($collection, $record_id);"
        return try self.execute(script, variables: ["record_id": recordId])
    }

    public func lastId() throws -> Int {
        let script = "$result = db_last_record_id($collection);"
        return try self.execute(script)
    }
    
    public func count() throws -> Int {
        return try self.execute("$result = db_total_records($collection);")
    }
    
    public func fetchAll() throws -> [[String: Any]] {
        let script = "$result = db_fetch_all($collection);"
        return try self.execute(script)
    }

    public func fetch(recordId: Int) throws -> [String: Any] {
        let script = "$result = db_fetch_by_id($collection, $record_id);"
        return try self.execute(script, variables: ["record_id": recordId])
    }

    public func fetch(_ filter: Expressible) throws -> [[String: Any]] {
        let script = "$result = db_fetch_all($collection, function(\(rec)) { return \(filter.raw); })"
        return try self.execute(script)
    }
    
    public func fetch(_ filter: @escaping FilterCallback) throws -> [[String: Any]] {
        let fnName = "_filter_fn"
        let script = "$result = db_fetch_all($collection, _filter_fn)"
        let vm = try db.vm(script: script)

        let context = Context(db: db, callback: filter)
        let userDataPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(context).toOpaque())

        try db.check(unqlite_create_function(vm.vmPtr, fnName, { ctxPtr, nargs, values in
            guard nargs == 1 else { return UNQLITE_ABORT }

            let pUserData = unqlite_context_user_data(ctxPtr)
            let context = Unmanaged<Context>.fromOpaque(pUserData!).takeUnretainedValue()
            context.ctxPtr = ctxPtr

            do {
                guard let item = try context.value(from: values!.advanced(by: Int(0)).pointee!) as? [String: Any] else {
                    return UNQLITE_ABORT
                }
                try context.setCallbackResult(value: context.callback(item))
            } catch {
                return UNQLITE_ABORT
            }

            return UNQLITE_OK
        }, userDataPtr))


        try vm.setVariable(value: self.name, by: "collection")
        try vm.execute()
        unqlite_delete_function(vm.vmPtr, fnName)

        guard let result = try vm.variableValue(by: "result", release: true) as? [[String: Any]] else {
            throw UnQLiteError.typeCastError
        }
        return result
    }

    private func execute<T>(_ script: String, variables: [String: Any]? = nil) throws -> T {
        let vm = try db.vm(script: script)
        try vm.setVariable(value: self.name, by: "collection")
        try variables?.forEach { name, value in
            try vm.setVariable(value: value, by: name)
        }
        try vm.execute()
        
        guard let result = try vm.variableValue(by: "result", release: true) as? T else {
            throw UnQLiteError.typeCastError
        }
        return result
    }
    
    private func execute(_ script: String, variables: [String: Any]? = nil) throws {
        let vm = try db.vm(script: script)
        try vm.setVariable(value: self.name, by: "collection")
        try variables?.forEach { name, value in
            try vm.setVariable(value: value, by: name)
        }
        try vm.execute()
    }
}


internal final class Context: ValueManager {
    let db: Connection
    let callback: FilterCallback
    var ctxPtr: OpaquePointer!

    init(db: Connection, callback: @escaping FilterCallback) {
        self.db = db
        self.callback = callback
    }

    func setCallbackResult<T>(value: T) throws {
        let valPtr = try self.createValuePtr(value)
        try db.check(unqlite_result_value(ctxPtr, valPtr))
        self.releaseValuePtr(valPtr)
    }

    /// Create an `unqlite_value` corresponding to the given Swift value.
    internal func createValuePtr<T>(_ value: T) throws -> OpaquePointer {
        var ptr: OpaquePointer!

        if value is [Any] || value is [String: Any] {
            ptr = unqlite_context_new_array(ctxPtr)
        } else {
            ptr = unqlite_context_new_scalar(ctxPtr)
        }

        try self.setValue(value, to: ptr)
        return ptr
    }

    /// Release the given `unqlite_value`.
    internal func releaseValuePtr(_ ptr: OpaquePointer) {
        unqlite_context_release_value(ctxPtr, ptr)
    }

}
