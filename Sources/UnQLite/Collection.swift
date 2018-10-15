import Foundation
import CUnQLite


public typealias FilterCallback = ([String: Any]) -> Bool


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
    public func append(_ record: [ExpressionType: Any]) throws -> Int {
        let record = record.compactMap { (tuple: (key: ExpressionType, value: Any)) -> (String, Any)? in
            guard let key = tuple.key.field else { return nil }
            return (key, tuple.value)
        }
        return try self.append(Dictionary(uniqueKeysWithValues: record))
    }

    @discardableResult
    public func append(_ records: [[String: Any]]) throws -> Bool {
        let script = "$result = db_store($collection, $records);"
        return try self.execute(script, variables: ["records": records])
    }

    @discardableResult
    public func append(_ records: [[ExpressionType: Any]]) throws -> Bool {
        let records = records.compactMap { (item: [ExpressionType: Any]) -> [String: Any]? in
            let result = item.compactMap { (tuple: (key: ExpressionType, value: Any)) -> (String, Any)? in
                guard let key = tuple.key.field else { return nil }
                return (key, tuple.value)
            }
            return Dictionary(uniqueKeysWithValues: result)
        }
        return try self.append(records)
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
        let script = "$result = db_fetch_all($collection);"
        return try self.execute(script)
    }

    public func filter(_ expression: Expressible) throws -> [[String: Any]] {
        let script = "$result = db_fetch_all($collection, function($rec) { return \(expression.raw); })"
        return try self.execute(script)
    }
    
    public func filter(_ isIncluded: @escaping FilterCallback) throws -> [[String: Any]] {
        let fnName = "_filter_fn"
        let script = "$result = db_fetch_all($collection, _filter_fn)"
        let vm = try db.vm(with: script)

        let context = Context(db: db, callback: isIncluded)
        let userDataPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(context).toOpaque())

        try db.check(unqlite_create_function(vm.vmPtr, fnName, { (ctxPtr, nargs, values) in
            guard nargs == 1 else {
                return UNQLITE_ABORT
            }

            let pUserData = unqlite_context_user_data(ctxPtr)
            let context = Unmanaged<Context>.fromOpaque(pUserData!).takeUnretainedValue()
            context.ctxPtr = ctxPtr

            do {
                guard let item = try context.value(from: values!.advanced(by: Int(0)).pointee!) as? [String: Any] else {
                    return UNQLITE_ABORT
                }
                try context.setResult(value: context.callback(item))
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
        let vm = try db.vm(with: script)
        try vm.setVariable(value: self.name, by: "collection")
        try variables?.forEach { (name, value) in
            try vm.setVariable(value: value, by: name)
        }
        try vm.execute()
        
        guard let result = try vm.variableValue(by: "result", release: true) as? T else {
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


internal final class Context: ValueManager {
    let db: Connection
    let callback: FilterCallback
    var ctxPtr: OpaquePointer!

    init(db: Connection, callback: @escaping FilterCallback) {
        self.db = db
        self.callback = callback
    }

    func setResult<T>(value: T) throws {
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
