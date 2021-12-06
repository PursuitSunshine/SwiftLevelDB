//
//  LevelDB.swift
//  SwiftLevelDB
//
//  Created by Cherish on 2021/5/28.
//

import UIKit

public enum LevelDBError: Swift.Error {
    case undefinedError
    case openError(message: String)
    case readError(message: String)
    case writeError(message: String)
}

open class LevelDB {
    
    fileprivate var db: OpaquePointer?
    fileprivate var writeSync = false
    fileprivate var isUseCache = false
    fileprivate var dbPath = ""
    fileprivate var dbName = ""
   
    /// Create and open a database
    ///
    /// It is recommended to use this method to initialize a database
    ///
    /// The following example calls this method
    ///
    ///      let ldb = LevelDB.open(db: "xxx.db")
    ///
    ///
    /// - Parameters:
    ///   - path: Sandbox path where the database is stored. Default: ~/Library .
    ///   - db: database name, It is recommended to use a string ending in .db .
    /// - Returns: Return an instance of LevelDB.
    public class func open(path: String = getLibraryPath(), db: String) throws -> LevelDB {
        return try LevelDB(path: path, name: db)
    }
  
    /// Create and open a database
    ///
    /// Convenient initialization method to initialize a database instance
    ///
    /// The following example calls this method
    ///
    ///      let ldb = LevelDB(name: "xxx.db")
    ///
    ///      let ldb = LevelDB(path: "xxxx", name: "xxx.db")
    ///
    ///      //let options = [.createIfMissing]
    ///      let  options = FileOption.standard
    ///      let ldb = LevelDB(path: "xxxx", name: "xxx.db", options: options)
    ///
    ///
    /// - Parameters:
    ///   - path: Sandbox path where the database is stored. Default: ~/Library .
    ///   - name: database name, It is recommended to use a string ending in .db .
    ///   - options: Database configuration parameters, see FileOption for details, where ".createIfMissing" is necessary, default: FileOption.standard.
    /// - Returns: Return an instance of LevelDB.
    private convenience init(path: String = getLibraryPath(), name: String, options: [LevelDBOption] = LevelDBOption.standard) throws {
        self.init()
        assert(name.count != 0, "The database name cannot be empty")
        assert(options.contains(.createIfMissing), "options must contain .createIfMissing , Otherwise the database creation fails")
        
        let levelOption = LevelDBOptions(options: options)
        var error: UnsafeMutablePointer<Int8>? =  nil
        
        if options.contains(.createIfMissing) {
            if !FileManager.default.fileExists(atPath: path) {
                do {
                    let attr = [FileAttributeKey.protectionKey: FileProtectionType.none]
                    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: attr)
                } catch {
                   return
                }
            }
        }
        let dbPointer = path.utf8CString.withUnsafeBufferPointer {
            c_leveldb_open(levelOption.pointer, $0.baseAddress!, &error)
        }
        guard dbPointer != nil else {
            if error == error {
                /// 初始化失败时，查看当前路径下的所有文件名
                var allFileAttrs = [String:[FileAttributeKey : Any]]()
                let iterator = FileManager.default.enumerator(atPath: path)
                while let element = iterator?.nextObject() as? String {
                    do {
                        let attrs = try FileManager.default.attributesOfItem(atPath: path + "/" + element )
                        allFileAttrs[element] = attrs
                    } catch{
                        
                    }
                }
                throw LevelDBError.openError(message: String(cString: error!) + "allFileAttrs:\(allFileAttrs)")
            }
            throw LevelDBError.undefinedError
        }
        self.db = dbPointer
        self.dbPath = path
        self.dbName = name
    }
    
    /// Cache data to the database
    ///
    /// Just convert the data to be cached into Data type, the user can encapsulate and call it
    ///
    /// The following example calls this method
    ///
    ///      let intValue: Int = 10
    ///      let cacheData = try? JSONEncoder().encode(intValue)
    ///      ldb.put("Codable", value: cacheData)
    ///
    ///      //class Person: NSObject,NSCoding
    ///      let p = Person()
    ///      let data = NSKeyedArchiver.archivedData(withRootObject: object as Any)
    ///      ldb.put("NSCoding",value: data)
    ///
    ///
    /// - Parameters:
    ///   - key: The key corresponding to the cached data, supports two types: String and Data
    ///   - value: The cached data must be of type Data
    ///   - options: Optional parameter, default WriteOption.standard
    public func put(_ key: Slice, value: Data?, options: [WriteOption] = WriteOption.standard) {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        guard self.db != nil else {
            return
        }
        var error: UnsafeMutablePointer<Int8>?
        let writeOptions = ReadOptions(options: ReadOption.standard)
        key.slice { keyBytes, keyCount in
            if let value = value {
                value.withUnsafeBytes {
                    c_leveldb_put(self.db, writeOptions.pointer, keyBytes, keyCount, $0.baseAddress!.assumingMemoryBound(to: Int8.self), value.count, &error)
                }
            } else {
                c_leveldb_put(self.db, writeOptions.pointer, keyBytes, keyCount, nil, 0, &error)
            }
        }
    }
    
    
    /// Get cached data from the database according to the key
    ///
    /// Just convert the data to be cached into Data type, the user can encapsulate and call it
    ///
    /// The following example calls this method
    ///
    ///      if let getData = ldb.get("Codable") {
    ///        let getIntValue = try? JSONDecoder().decode(Int.self, from: getData)
    ///        print(getIntValue ?? 0)
    ///      }
    ///
    ///      if let getData = ldb.get("NSCoding") {
    ///        let getCodingValue = NSKeyedUnarchiver.unarchiveObject(with: data)
    ///        print(getIntValue ?? Person())
    ///      }
    ///
    ///
    /// - Parameters:
    ///   - key: The key corresponding to the cached data, supports two types: String and Data
    ///   - options: Optional parameter, default WriteOption.standard
    public func get(_ key: Slice, options: [ReadOption] = ReadOption.standard) -> Data? {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        guard self.db != nil else {
            return nil
        }
        var valueLength = 0
        var error: UnsafeMutablePointer<Int8>?
        var value: UnsafeMutablePointer<Int8>?

        let options = ReadOptions(options: options)
        key.slice { bytes, len in
            value = c_leveldb_get(self.db, options.pointer, bytes, len, &valueLength, &error)
        }
        
        // check fetch value lenght
        guard valueLength > 0 else {
            return nil
        }
        let target = Data(bytes: value!, count: valueLength)
        free(value)
        return  target
    }
 
    
    /// Get the collection of keys corresponding to all data in the database
    public func keys() -> [Slice] {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        guard self.db != nil else {
            return []
        }
        let readOptions = ReadOptions(options: ReadOption.standard)
        
        let iterator = c_leveldb_create_iterator(db, readOptions.pointer)
        c_leveldb_iter_seek_to_first(iterator)
        var keys = [Slice]()
        while c_leveldb_iter_valid(iterator) == 1 {
            var len = 0
            let result: UnsafePointer<Int8> = c_leveldb_iter_key(iterator, &len)
            let data = Data(bytes: result, count: len)
            keys.append(data)
            c_leveldb_iter_next(iterator)
        }
        c_leveldb_iter_destroy(iterator)
        return keys
    }
     
   
    /// Delete some data according to the key
    ///
    ///
    /// The following example calls this method
    ///
    ///     ldb.delete("Codable")
    ///
    ///
    /// - Parameters:
    ///   - key: The key corresponding to the cached data, supports two types: String and Data
    ///   - options: Optional parameter, default WriteOption.standard
    public func delete(_ key: Slice, options: [WriteOption] = WriteOption.standard) {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        guard self.db != nil else {
            return
        }
        var error: UnsafeMutablePointer<Int8>?
        let writeOptions = WriteOptions(options: options)
        key.slice { bytes, len in
            c_leveldb_delete(self.db, writeOptions.pointer, bytes, len, &error)
        }
    }
   
    /// Close the database
    public func close() {
        if db != nil {
            c_leveldb_close(db)
            db = nil
        }
    }
   
    deinit {
        close()
    }
}

// MARK: Compatible with Objective-Leveldb,Glue interface provided externally

extension LevelDB {

    public class func getLibraryPath() -> String {
        let paths: [String] = NSSearchPathForDirectoriesInDomains(.documentationDirectory, .userDomainMask, true)
        return paths.first ?? ""
    }
    
    public var safe: Bool {
        get {
            writeSync
        }
        set {
            writeSync = newValue
            c_leveldb_writeoptions_set_sync(c_leveldb_writeoptions_create(), newValue ? 1 : 0)
        }
    }
    
    public var useCache: Bool {
        get {
            isUseCache
        }
        set {
            isUseCache = newValue
            c_leveldb_readoptions_set_fill_cache(c_leveldb_readoptions_create(), newValue ? 1 : 0)
        }
    }
    
    public func path() -> String {
        return dbPath
    }
    
    public func name() -> String {
        return dbName
    }
    
    
    /// setObject OC KeyedArchiver
    /// - Parameters:
    ///   - object: 需要实现NSCoding 协议
    ///   - key: key Slice
    public func setObject(_ object: Any?, forKey key: Slice){
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        assert(key is String || key is Data, "key must be String type or Data type")
        assert(object != nil, "Stored value cannot be empty")
        assert(object is NSCoding, "value must implemented NSCoding protocol!")
        assert(object is NSSecureCoding,"value must implemented NSSecureCoding protocol!")
        
        var data: Data?
        if #available(iOS 11, *) {
            data = try? NSKeyedArchiver.archivedData(withRootObject: object!, requiringSecureCoding: true)
        } else {
            data = NSKeyedArchiver.archivedData(withRootObject: object as Any)
        }
        put(key, value: data)
    }
    
    
    /// 同 setObject
    /// - Parameters:
    ///   - value: 需要实现NSCoding 协议
    ///   - key: key Slice
    public func setValue(_ value: Any?, forKey key: Slice){
        setObject(value, forKey: key)
    }
    
    
    /// 同 object(forKey）
    /// - Parameter key: key
    /// - Returns:NSKeyedUnarchiver.unarchiveObject
    public func value(forKey key: String) -> Any?{
        return object(forKey: key)
    }
    
    /// 获取结果
    /// - Parameter key: key
    /// - Returns:NSKeyedUnarchiver.unarchiveObject
    public func object(forKey key: Slice) -> Any? {
        guard let data = get(key) else {
            return nil
        }
        return NSKeyedUnarchiver.unarchiveObject(with: data)
    }
    
    
    
    /// 获取结果
    /// - Returns: NSKeyedUnarchiver.unarchiveObject(ofClass,from)
    public func object<T>(forKey key: Slice, cls: T.Type) -> Any? where T : NSObject, T : NSCoding {
        guard let data = get(key) else {
            return nil
        }
        if #available(iOS 11, *) {
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: cls, from: data)
        } else {
            return NSKeyedUnarchiver.unarchiveObject(with: data)
        }
    }
    
    public func allKeys() -> [Slice] {
        return keys()
    }
    
    public func removeObject(forKey key: Slice) {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        delete(key)
    }
    
    public func removeObjects(forKeys keyArray: [Slice]) {
        for (_, key) in keyArray.enumerated() {
            removeObject(forKey: key)
        }
    }
     
    public func removeAllObjects() {
        let keys = allKeys()
        if keys.count > 0 {
            for (_, item) in keys.enumerated() {
                removeObject(forKey: item)
            }
        }
    }
    
    public func deleteDatabaseFromDisk() {
        if self.db != nil {
            close()
            try? FileManager.default.removeItem(atPath: self.dbPath)
        }
    }
    
    public func objectExists(forKey: Slice) -> Bool {
        assert(db != nil, "Database reference is not existent (it has probably been closed)")
        return get(forKey) != nil
    }
    
    public func closed() -> Bool {
        return db == nil
    }
}

// MARK: Cache and get objects that implement the Codable protocol,Glue interface provided externally

extension LevelDB {
    /// iOS 13 Int 和 Bool 类型，JSONEncoder encode 失败， 报top-level Int encoded as number JSON fragment. 错误，这里包装一层
    /// @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    /// extension JSONDecoder : TopLevelDecoder { }
    struct CoableBox<T: Codable>: Codable {
        var value: T
        
        init?(_ value: T?) {
            if value == nil { return nil }
            self.value = value!
        }
        
        static var isNeedBoxType: Bool {
            let type = T.self
            if type == Bool.self ||
                type == Float.self ||
                type == Double.self ||
                type == Decimal.self ||
                type == Int.self ||
                type == Int8.self ||
                type == Int16.self ||
                type == Int64.self ||
                type == UInt.self ||
                type == UInt8.self ||
                type == UInt16.self ||
                type == UInt64.self ||
                type == String.self ||
                type == URL.self ||
                type == Data.self
                {
                return true
            }
            
            return false
        }
        
        static var isNeedBox: Bool {
            if #available(iOS 13, *) {
                return false
            }
            return isNeedBoxType
        }
    }
    
    
    ///  iOS 13 中 Int 和 Bool 类型 会使用 CoableBox 包装
    /// - Parameters:
    ///   - value: 实现Codable协议
    ///   - key: 实现Slice协议
    public func putCodable<T>(_ value: T?, forKey key: Slice) where T: Codable {
        if value == nil {
            put(key, value: nil)
            return
        }
        
        /// iOS 13 Int 和 Bool 类型，JSONEncoder encode 失败， 报op-level Int encoded as number JSON fragment. 错误，这里包装一层
        var data: Data? = nil
        if CoableBox<T>.isNeedBox {
            let nValue = CoableBox<T>(value)
            data = try? JSONEncoder().encode(nValue)
        } else {
            data =  try? JSONEncoder().encode(value)
        }

        assert(data != nil, "JSONEncoder faild!")
        put(key, value: data)
    }

    public func getCodable<T>(forKey: Slice) -> T? where T: Codable {
        guard let data: Data = get(forKey) else { return nil }
        
        if CoableBox<T>.isNeedBox {
            let box = try? JSONDecoder().decode(CoableBox<T>.self, from: data)
            return box?.value
        }
        
        var value = try? JSONDecoder().decode(T.self, from: data)
        if value == nil && CoableBox<T>.isNeedBoxType {
            let box = try? JSONDecoder().decode(CoableBox<T>.self, from: data)
            value = box?.value
        }
        return value
    }

    public func getCodable<T>(forKey: Slice, type: T.Type) -> T? where T: Codable {
        let value: T? = getCodable(forKey: forKey)
        return value
    }
}

