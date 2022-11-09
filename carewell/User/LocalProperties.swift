//
// Created by DOYEON BAEK on 2022/10/21.
//

import Foundation

public class LocalProperties {
    private static var mPropertyFile = File()

    public func close() {
        print("SystemSettingRepository Closed")
    }

    private init() {
    }


    public static func set(_ key: String, _ value: Bool) {
        set(key, String(value))
    }

    public static func set(_ key: String, _ value: Int) {
        var val: String = String(format: "%d", value)
        set(key, val)
    }

    public static func set(_ key: String, _ value: String) {
        var mProperty: Properties = Properties()
        if !mPropertyFile.exists() {
            mPropertyFile.createNewFile()
        } else {
            mProperty.load(mPropertyFile)
        }

        mProperty.setProperty(key, value)
        mProperty.store(mPropertyFile)
    }

    public static func get(_ key: String, _ defaultVal: Bool) -> Bool {
        var strResult: String
        strResult = get(key, defaultVal.description) ?? "false"
        guard let result = Bool(strResult.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            print("Error: \(strResult) is not a valid Bool")
            return false
        }
        return result
    }

    public static func get(_ key: String, _ defaultVal: Int) -> Int {
        var strResult: String, defVal: String
        defVal = String(format: "%d", defaultVal)
        return (Int(get(key, defVal))!)
    }

    public static func get(_ key: String, _ defaultVal: String) -> String {
        var mProperty: Properties
        var value: String? = defaultVal

        mProperty = Properties()
        if !mPropertyFile.exists() {
            mPropertyFile.createNewFile()
        } else {
            mProperty.load(mPropertyFile)
        }

        value = mProperty.getProperty(key)?.replacingOccurrences(of: "\\n", with: "") ?? nil

        if nil == value {
            value = defaultVal
        }

        return value!

    }

}
