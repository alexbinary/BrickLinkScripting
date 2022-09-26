
import Foundation
import SQLite3



class DatabaseConnection {
    
    
    private var databasePath: String
    
    private var databaseUrl: URL { URL(fileURLWithPath: databasePath) }
    private var backupDatabaseUrl: URL { URL(fileURLWithPath: databasePath.replacingOccurrences(of: ".db", with: "-\(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium).replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")).db")) }
    
    private var connectionPointer: OpaquePointer!
    
    
    init(databasePath: String, onCreate: (DatabaseConnection) -> Void) {
        
        self.databasePath = databasePath
        
        print("[Database] Initializing connection to \(databasePath)")
        
        let dbExists = FileManager.default.fileExists(atPath: databasePath)
        if (dbExists) {
            print("[Database] Backing up database to \(backupDatabaseUrl)...")
            try? Data(contentsOf: databaseUrl).write(to: backupDatabaseUrl)
            print("[Database] Database backed up")
        } else {
            print("[Database] Database does not exist, skipping backup")
        }
        
        self.connect()
        if (!dbExists) {
            print("[Database] Database does not exist, running init queries...")
            onCreate(self)
            print("[Database] Init queries done")
        }
    }
    
    
    deinit {
        self.close()
    }


    private func connect() {
    
        print("[Database] Connecting to \(databasePath)")
        
        guard sqlite3_open(databasePath, &connectionPointer) == SQLITE_OK else {
            
            fatalError("[Database] sqlite3_open() failed. Opening database: \(databasePath). SQLite error: \(errorMessage(from: connectionPointer) ?? "")")
        }
        print("[Database] Connected")
    }
    
    
    private func close() {
        
        print("[Database] Closing connection")
        sqlite3_close(connectionPointer)
    }
    
    
    func runForMultiRowResult(_ query: String, with params: [String: String] = [:]) -> TableValues {
        
        var statementPointer: OpaquePointer!
        
        print("[Database] Running query: \(query) with parameters: \(params)")
        
        guard sqlite3_prepare_v2(connectionPointer, query, -1, &statementPointer, nil) == SQLITE_OK else {

            fatalError("[Database] sqlite3_prepare_v2() failed. Compiling query: \(query). SQLite error: \(errorMessage(from: connectionPointer) ?? "")")
        }
        
        sqlite3_reset(statementPointer)
        
        params.forEach { name, value in
            
            let parameterName = ":"+name
            let stringValue = value

            let index = sqlite3_bind_parameter_index(statementPointer, parameterName)
            let rawValue = NSString(string: stringValue).utf8String

            sqlite3_bind_text(statementPointer, index, rawValue, -1, nil)
        }
        
        var tableValues = TableValues()
        
        while true {
        
            let stepResult = sqlite3_step(statementPointer)
            
            guard [SQLITE_ROW, SQLITE_DONE].contains(stepResult) else {
                
                fatalError("[Database] sqlite3_step() returned \(stepResult) for query: \(query). SQLite error: \(errorMessage(from: connectionPointer) ?? "")")
            }
            
            if stepResult == SQLITE_DONE {
                
                print("[Database] Done reading query result")
                break
            }
            
            if stepResult == SQLITE_ROW {
                
                var rowValues = RowValues()
            
                (0..<sqlite3_column_count(statementPointer)).forEach { index in
                
                    let rawColumnName = sqlite3_column_name(statementPointer, index)!
                    let rawValue = sqlite3_column_text(statementPointer, index)
                    
                    let columnName = String(cString: rawColumnName)
                    let value: ColumnValue = rawValue != nil ? .value(String(cString: rawValue!)) : .null
                    
                    print("[Database] \(columnName): \(value)")
                    
                    rowValues.set(value: value, forColumn: columnName)
                }
                
                tableValues.add(rowValues: rowValues)
            }
        }
        
        return tableValues
    }
    
    
    func runInsertInto(tableName: String, rawValues: [String: Any?]) {
        
        let finalValues = rawValues
            
            .compactMapValues { $0 }
            .mapValues { "\($0)" }
        
        self.runInsertInto(tableName: "order", values: finalValues)
    }
    
    
    func runInsertInto(tableName: String, values: [String: String]) {
        
        self.runIgnoringResult("""
            INSERT INTO \"\(tableName)\" (
                \(values.keys.joined(separator: ","))
            ) VALUES (
                \(values.keys.map { ":\($0)" } .joined(separator: ","))
            )
            """,
            with: values
        )
    }
    
    
    func runForSingleRowResult(_ query: String, with params: [String: String] = [:]) -> RowValues? {
    
        return runForMultiRowResult(query, with: params).firstRow
    }
    
    
    func runForSingleValueResult(_ query: String, with params: [String: String] = [:]) -> ColumnValue? {
    
        return runForSingleRowResult(query, with: params)?.firstColumnValue
    }
    
    
    func runIgnoringResult(_ query: String, with params: [String: String] = [:]) {
        
        _ = runForMultiRowResult(query, with: params)
    }
    
    
    private func errorMessage(from pointer: OpaquePointer) -> String? {
            
        if let raw = sqlite3_errmsg(pointer) {
            return String(cString: raw)
        } else {
            return nil
        }
    }
}



enum ColumnValue {
    case null
    case value(String)
}
typealias RowValues = [String: ColumnValue]
typealias TableValues = [RowValues]


extension TableValues {
    
    var firstRow: RowValues? { self.first }
    
    mutating func add(rowValues: RowValues) {
        
        self.append(rowValues)
    }
}


extension RowValues {
    
    var firstColumnValue: ColumnValue? { self.values.first }
    
    func value(forColumn columnName: String) -> ColumnValue? {
        
        return self[columnName]
    }
    
    mutating func set(value: ColumnValue, forColumn columnName: String) {
        
        self[columnName] = value
    }
}
