//
// Created by DOYEON BAEK on 2022/10/22.
//

import Foundation
import SQLite3

class DbOpenHelper {
    private var db: OpaquePointer?
    private var dbPath: String = "InnerDatabase(SQLite).db"
    private var dbVersion: Int = 1

    init() {
        db = openDatabase()
        createTable()
    }

    func openDatabase() -> OpaquePointer? {
        var db: OpaquePointer? = nil
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(dbPath)
        if sqlite3_open_v2(fileURL.path, &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil) == SQLITE_OK {
            print("Successfully opened connection to database at \(fileURL.path)")
            return db
        } else {
            print("Unable to open database.")
            return nil
        }
    }

    func sortByColumn(_ sortType: SortType) -> [User] {
        var users: [User] = []
        var queryStatementString: String = ""
        switch sortType {
        case .NAME:
            queryStatementString = "SELECT * FROM User ORDER BY name ASC;"
        case .NUMBER:
            queryStatementString = "SELECT * FROM User ORDER BY number ASC;"
        case .STATUS:
            queryStatementString = "SELECT * FROM User ORDER BY status ASC;"
        case .TIME:
            queryStatementString = "SELECT * FROM User ORDER BY time ASC;"
        }
        var queryStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = sqlite3_column_int(queryStatement, 0)
                let name = String(cString: sqlite3_column_text(queryStatement, 1))
                let number = String(cString: sqlite3_column_text(queryStatement, 2))
                let status = Int(sqlite3_column_int(queryStatement, 3))
                let time = sqlite3_column_int64(queryStatement, 4)
                users.append(User(name: name, number: number, status: status, time: UInt64(time)))
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
        return users
    }

func deleteOverRows() {
    let deleteStatementString = "DELETE FROM User WHERE id NOT IN (SELECT name FROM User ORDER BY id DESC LIMIT 1000);"
    var deleteStatement: OpaquePointer? = nil
    if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
        if sqlite3_step(deleteStatement) == SQLITE_DONE {
            print("Successfully deleted row.")
        } else {
            print("Could not delete row.")
        }
    } else {
        print("DELETE statement could not be prepared")
    }
    sqlite3_finalize(deleteStatement)
}

func createTable() {
    let createTableString = "CREATE TABLE IF NOT EXISTS User(name TEXT PRIMARY KEY, number TEXT, status INTEGER, time BIGINT);"
    var createTableStatement: OpaquePointer? = nil
    if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
        if sqlite3_step(createTableStatement) == SQLITE_DONE {
            print("User table created.")
        } else {
            print("User table could not be created.")
        }
    } else {
        print("CREATE TABLE statement could not be prepared.")
    }
    sqlite3_finalize(createTableStatement)
}

func insert(name: String, number: String, status: CallStatusType, time: UInt64) {
    let insertStatementString = "INSERT INTO User (name, number, status, time) VALUES (?, ?, ?, ?);"
    var insertStatement: OpaquePointer? = nil
    if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
        sqlite3_bind_text(insertStatement, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 2, (number as NSString).utf8String, -1, nil)
        sqlite3_bind_int(insertStatement, 3, Int32(status.rawValue))
        sqlite3_bind_int64(insertStatement, 4, sqlite3_int64(truncating: (time) as NSNumber))
        if sqlite3_step(insertStatement) == SQLITE_DONE {
            print("Successfully inserted row.")
        } else {
            print("Could not insert row.")
        }
    } else {
        print("INSERT statement could not be prepared.")
    }
    sqlite3_finalize(insertStatement)
}

func read() -> [User] {
    let queryStatementString = "SELECT * FROM User;"
    var queryStatement: OpaquePointer? = nil
    var psns: [User] = []
    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
        while sqlite3_step(queryStatement) == SQLITE_ROW {
            let name = String(describing: sqlite3_column_text(queryStatement, 1))
            let number = String(cString: sqlite3_column_text(queryStatement, 2))
            let status = Int(sqlite3_column_int(queryStatement, 3))
            let time = UInt64(sqlite3_column_int64(queryStatement, 4))
            psns.append(User(name: name, number: number, status: status, time: time))
            print("Query Result:")
            print("\(name) | \(number) | \(status) | \(time)")
        }
    } else {
        print("SELECT statement could not be prepared")
    }
    sqlite3_finalize(queryStatement)
    return psns
}

func update(name: String, number: String, status: CallStatusType, time: UInt64) {
    let updateStatementString = "UPDATE User SET number = ?, status = ?, time = ? WHERE name = ?;"
    var updateStatement: OpaquePointer? = nil
    if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
        sqlite3_bind_text(updateStatement, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(updateStatement, 2, (number as NSString).utf8String, -1, nil)
        sqlite3_bind_int(updateStatement, 3, Int32(status.rawValue))
        sqlite3_bind_int64(updateStatement, 4, sqlite3_int64(truncating: (time) as NSNumber))
        if sqlite3_step(updateStatement) == SQLITE_DONE {
            print("Successfully updated row.")
        } else {
            print("Could not update row.")
        }
    } else {
        print("UPDATE statement could not be prepared")
    }
    sqlite3_finalize(updateStatement)
}

func delete(name: String) {
    let deleteStatementStirng = "DELETE FROM User WHERE name = ?;"
    var deleteStatement: OpaquePointer? = nil
    if sqlite3_prepare_v2(db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
        sqlite3_bind_text(deleteStatement, 1, (name as NSString).utf8String, -1, nil)
        if sqlite3_step(deleteStatement) == SQLITE_DONE {
            print("Successfully deleted row.")
        } else {
            print("Could not delete row.")
        }
    } else {
        print("DELETE statement could not be prepared")
    }
    sqlite3_finalize(deleteStatement)
}

func dropTable() {
    let dropTableString = "DROP TABLE User;"
    var dropTableStatement: OpaquePointer? = nil
    if sqlite3_prepare_v2(db, dropTableString, -1, &dropTableStatement, nil) == SQLITE_OK {
        if sqlite3_step(dropTableStatement) == SQLITE_DONE {
            print("User table dropped.")
        } else {
            print("User table could not be dropped.")
        }
    } else {
        print("DROP TABLE statement could not be prepared")
    }
    sqlite3_finalize(dropTableStatement)
}

func close() {
    sqlite3_close(db)
}

func deleteDatabase() {
    let fileManager = FileManager.default
    let fileURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("User.sqlite")
    do {
        try fileManager.removeItem(at: fileURL)
        print("Database deleted.")
    } catch {
        print("Could not delete database.")
    }
}

func deleteAll() {
    let deleteStatementStirng = "DELETE FROM User;"
    var deleteStatement: OpaquePointer? = nil
    if sqlite3_prepare_v2(db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
        if sqlite3_step(deleteStatement) == SQLITE_DONE {
            print("Successfully deleted all rows.")
        } else {
            print("Could not delete all rows.")
        }
    } else {
        print("DELETE statement could not be prepared")
    }
    sqlite3_finalize(deleteStatement)
}

func count() -> Int {
    let queryStatementString = "SELECT COUNT(*) FROM User;"
    var queryStatement: OpaquePointer? = nil
    var count = 0
    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
        if sqlite3_step(queryStatement) == SQLITE_ROW {
            count = Int(sqlite3_column_int(queryStatement, 0))
        } else {
            print("Could not fetch row.")
        }
    } else {
        print("SELECT statement could not be prepared")
    }
    sqlite3_finalize(queryStatement)
    return count
}

}
