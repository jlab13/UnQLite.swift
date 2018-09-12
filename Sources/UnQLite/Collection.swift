import Foundation
import CUnQLite


public final class Collection {
    private let db: UnQLite
    let name: String

    /// Create the named collection if not exists.
    public init(db: UnQLite, name: String) throws {
        self.db = db
        self.name = name
        try self.execute("if (!db_exists($collection)) {db_create($collection);}")
    }
    
    /// Drop the collection and all associated records.
    public func drop() throws {
        try self.execute("if (db_exists($collection)) { db_drop_collection($collection); }")
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
