import Foundation
import CUnQLite


public struct TmpError: Error {
    let message: String
}


public final class Collection {
    private let db: Connection
    let name: String

    /// Drop the collection and all associated records.
    public static func drop(db: Connection, name: String) throws {
        try self.init(db: db, name: name).drop()
    }
    
    /// Create the named collection if not exists.
    public init(db: Connection, name: String) throws {
        self.db = db
        self.name = name
        try self.execute("if (!db_exists($collection)) {db_create($collection);}")
    }
    
    public func lastRecordId() throws -> Int {
        return try self.execute("$result = db_last_record_id($collection);")
    }

    public func currentRecordId() throws -> Int {
        return try self.execute("$result = db_current_record_id($collection);")
    }
    
    public func resetCursor() throws {
        try self.execute("db_reset_record_cursor($collection);")
    }
    
    public func count() throws -> Int {
        return try self.execute("$result = db_total_records($collection);")
    }
    
    public func fetch(by recordId: Int) throws -> [String: Any] {
        let script = "$result = db_fetch_by_id($collection, $record_id);"
        return try self.execute(script, variables: ["record_id": recordId])
    }
    
    public func fetch() throws -> [String: Any] {
        return try self.execute("$result = db_fetch($collection);")
    }
    
    @discardableResult
    public func append(_ record: [String: Any]) throws -> [String: Any] {
        return try self.execute("$result = db_store($collection, $record);")
    }

    @discardableResult
    public func append(_ record: [String: Any]) throws -> Int {
        return try self.execute("if (db_store($collection, $record)) { $result = db_last_record_id($collection); }")
    }
    
    public func update(record: [String: Any], by recordId: Int) throws {
        let script = "$result = db_update_record($collection, $record_id, $record);"
        return try self.execute(script, variables: ["record_id": recordId, "record": record])
    }

    public func delete(by recordId: Int) throws {
        let script = "$result = db_drop_record($collection, $record_id);"
        try self.execute(script, variables: ["record_id": recordId])
    }
    
    public func errorLog() throws -> String {
        return try self.execute("$result = db_errlog();")
    }

    private func drop() throws {
        try self.execute("if (db_exists($collection)) { db_drop_collection($collection); }")
    }

    private func execute<T>(_ script: String, variables: [String: Any]? = nil) throws -> T {
        let vm = try db.vm(with: script)
        try vm.setVariable(value: self.name, by: "collection")
        try variables?.forEach { (name, value) in
            try vm.setVariable(value: value, by: name)
        }
        try vm.execute()
        
        guard let result = try vm.value(by: "result") as? T else {
            throw TmpError(message: "Cast type result error")
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
