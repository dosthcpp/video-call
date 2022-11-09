//
// Created by DOYEON BAEK on 2022/10/21.
//

import Foundation

class HashTable {
    private var table: [String: Any] = [:]
    private let queue = DispatchQueue(label: "com.concurrentHashmap", attributes: .concurrent)

    func put(key: String, value: Any) {
        queue.async(flags: .barrier) {
            self.table[key] = value
        }
    }

    func get(key: String) -> Any? {
        var result: Any?
        queue.sync {
            result = self.table[key]
        }
        return result
    }

    func remove(key: String) {
        queue.async(flags: .barrier) {
            self.table.removeValue(forKey: key)
        }
    }

    func clear() {
        queue.async(flags: .barrier) {
            self.table.removeAll()
        }
    }

    func contains(key: String) -> Bool {
        var result: Bool = false
        queue.sync {
            result = self.table[key] != nil
        }
        return result
    }

    func size() -> Int {
        var result: Int = 0
        queue.sync {
            result = self.table.count
        }
        return result
    }

    func isEmpty() -> Bool {
        var result: Bool = false
        queue.sync {
            result = self.table.isEmpty
        }
        return result
    }

}