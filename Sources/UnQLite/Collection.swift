import Foundation
import CUnQLite


public final class Collection {
    private let db: Connection
    let name: String

    public init(db: Connection, name: String, isAutoCreate: Bool = true) throws {
        self.db = db
        self.name = name

        if isAutoCreate {
            try self.create()
        }
    }
    
//    public var count: Int {
//        return (try? self.recordCount()) ?? 0
//    }
    
//    public subscript(recordId: Int) -> [String: Any]? {
//        return try? self.fetch(by: recordId)
//    }
    
    /// Create the named collection if not exists.
    public func create() throws {
        try self.execute("if (!db_exists($collection)) { db_create($collection); }")
    }

    /// Drop the collection and all associated records.
    public func drop() throws {
        try self.execute("if (db_exists($collection)) { db_drop_collection($collection); }")
    }
    
    public func lastId() throws -> Int {
        return try self.execute("$result = db_last_record_id($collection);")
    }
    
    public func recordCount() throws -> Int {
        return try self.execute("$result = db_total_records($collection);")
    }

    public func fetch(by recordId: Int) throws -> [String: Any] {
        let script = "$result = db_fetch_by_id($collection, $record_id);"
        return try self.execute(script, variables: ["record_id": recordId])
    }

//    public func currentId() throws -> Int {
//        return try self.execute("$result = db_current_record_id($collection);")
//    }
    
//    public func resetCursor() throws {
//        try self.execute("db_reset_record_cursor($collection);")
//    }

//    public func fetch() throws -> [String: Any] {
//        let script = "$result = db_fetch($collection);"
//        return try self.execute(script)
//    }

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
    
//    public func errorLog() throws -> String {
//        return try self.execute("$result = db_errlog();")
//    }

    private func execute<T>(_ script: String, variables: [String: Any]? = nil) throws -> T {
        let vm = try db.vm(with: script)
        try vm.setVariable(value: self.name, by: "collection")
        try variables?.forEach { (name, value) in
            try vm.setVariable(value: value, by: name)
        }
        try vm.execute()
        
        guard let result = try vm.value(by: "result", release: true) as? T else {
            throw Result.typeCastError
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
