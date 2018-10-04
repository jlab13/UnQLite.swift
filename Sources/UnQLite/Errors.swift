import CUnQLite


public enum UnQLiteError: Error {
    case notFound
    case typeCastError
    case unqlite(code: Int, message: String?)
    
    init(resultCode: CInt, db: Connection) {
        if resultCode == UNQLITE_NOTFOUND {
            self = .notFound
        } else {
            var buf: UnsafeMutablePointer<CChar>?
            var len: CInt = 0
            let flag = resultCode == UNQLITE_COMPILE_ERR ? UNQLITE_CONFIG_JX9_ERR_LOG : UNQLITE_CONFIG_ERR_LOG
            let msg = unqlite_config_err_log(db.dbPtr, flag, &buf, &len) == UNQLITE_OK && len > 0
                ? String(bytesNoCopy: buf!, length: Int(len), encoding: .utf8, freeWhenDone: false) : nil
            self = .unqlite(code: Int(resultCode), message: msg)
        }
    }
}
