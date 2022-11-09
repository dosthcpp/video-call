//
// Created by DOYEON BAEK on 2022/10/20.
//

import Foundation

class ConcurrentHashMap {
    private var map: [String: Any] = [:]
    private let queue = DispatchQueue(label: "com.concurrentHashmap", attributes: .concurrent)

    func put(key: String, value: Any) {
        queue.async(flags: .barrier) {
            self.map[key] = value
        }
    }

    func get(key: String) -> Any? {
        var result: Any?
        queue.sync {
            result = self.map[key]
        }
        return result
    }

    func remove(key: String) {
        queue.async(flags: .barrier) {
            self.map.removeValue(forKey: key)
        }
    }

    func clear() {
        queue.async(flags: .barrier) {
            self.map.removeAll()
        }
    }

    func contains(key: String) -> Bool {
        var result: Bool = false
        queue.sync {
            result = self.map[key] != nil
        }
        return result
    }

    func size() -> Int {
        var result: Int = 0
        queue.sync {
            result = self.map.count
        }
        return result
    }

    func isEmpty() -> Bool {
        var result: Bool = false
        queue.sync {
            result = self.map.isEmpty
        }
        return result
    }

    func keys() -> [String] {
        var result: [String] = []
        queue.sync {
            result = Array(self.map.keys)
        }
        return result
    }

    func values() -> [Any] {
        var result: [Any] = []
        queue.sync {
            result = Array(self.map.values)
        }
        return result
    }
}