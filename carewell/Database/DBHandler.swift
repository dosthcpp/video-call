//
// Created by DOYEON BAEK on 2022/10/22.
//

import Foundation
import SQLite3

class DBHandler {
    private static var mDbOpenHelper: DbOpenHelper?

    public init() {
        DBHandler.mDbOpenHelper = DbOpenHelper()
    }

    public static func initialize() {
        if let mDbOpenHelper = mDbOpenHelper {
            mDbOpenHelper.openDatabase()
            mDbOpenHelper.createTable()
        }
    }

    public static func deinitialize() {
        DBHandler.mDbOpenHelper?.close()
    }

    public static func insertColumn(_ name: String, _ number: String, _ status: CallStatusType) -> UInt64 {
        if let mDbOpenHelper = mDbOpenHelper {
            mDbOpenHelper.openDatabase()
            mDbOpenHelper.insert(name: name, number: number, status: status, time: UInt64(Date().timeIntervalSince1970) * 1000)
            mDbOpenHelper.deleteOverRows()
            return 0
        }
        return 1
    }

    public static func sortColumn(_ sortType: SortType) -> [User] {
        if let mDbOpenHelper = mDbOpenHelper {
            mDbOpenHelper.openDatabase()
            return mDbOpenHelper.sortByColumn(sortType)
        }
        return []
    }

    public static func deleteAll() {
        if let mDbOpenHelper = mDbOpenHelper {
            mDbOpenHelper.openDatabase()
            mDbOpenHelper.deleteAll()
        }
    }
}
