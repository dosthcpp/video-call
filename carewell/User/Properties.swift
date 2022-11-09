//
// Created by DOYEON BAEK on 2022/10/21.
//

import Foundation

import Foundation

public class LineReader {
    public let path: String

    fileprivate let file: UnsafeMutablePointer<FILE>!

    init?(path: String) {
        self.path = path
        file = fopen(path, "r")
        guard file != nil else { return nil }
    }

    public var nextLine: String? {
        var line:UnsafeMutablePointer<CChar>? = nil
        var linecap:Int = 0
        defer { free(line) }
        return getline(&line, &linecap, file) > 0 ? String(cString: line!) : nil
    }

    deinit {
        fclose(file)
    }
}

extension LineReader: Sequence {
    public func makeIterator() -> AnyIterator<String> {
        return AnyIterator<String> {
            return self.nextLine
        }
    }
}

// implemented from java.util.properties
class Properties: HashTable {
    private var map: [String: Any] = [:]
    private let queue = DispatchQueue(label: "com.peroperties", attributes: .concurrent)

    private func load0(_ reader: LineReader) {
        var line: String?
        while (true) {
            line = reader.nextLine
            if (line == nil) {
                break
            }
            if (line!.isEmpty) {
                continue
            }
            if (line!.first == "#") {
                continue
            }
            let index = line!.firstIndex(of: "=")
            if (index == nil) {
                continue
            }
            let key = String(line![line!.startIndex..<index!])
            let value = String(line![line!.index(after: index!)..<line!.endIndex])
            put(key: key, value: value)
        }
    }

    public func getProperty(_ key: String) -> String? {
        var result: String?
        queue.sync {
            result = self.map[key] as? String
        }
        return result
    }

    public func setProperty(_ key: String, _ value: String) {
        queue.sync(flags: .barrier) {
            self.map[key] = value
        }
    }

    public func load(_ file: File) {
        load0(LineReader(path: file.path)!)
    }

    public func store(_ file: File) {
        queue.sync(flags: .barrier) {[self] in
            for (key, value) in map {
                file.write(string: "\(key)=\(value)")
            }
        }
    }

    override func put(key: String, value: Any) {
        queue.async(flags: .barrier) {
            self.map[key] = value
        }
    }

    override func get(key: String) -> Any? {
        var result: Any?
        queue.sync {
            result = self.map[key]
        }
        return result
    }

    override func remove(key: String) {
        queue.async(flags: .barrier) {
            self.map.removeValue(forKey: key)
        }
    }

    override func clear() {
        queue.async(flags: .barrier) {
            self.map.removeAll()
        }
    }

    override func contains(key: String) -> Bool {
        var result: Bool = false
        queue.sync {
            result = self.map[key] != nil
        }
        return result
    }

    override func size() -> Int {
        var result: Int = 0
        queue.sync {
            result = self.map.count
        }
        return result
    }

    override func isEmpty() -> Bool {
        var result: Bool = false
        queue.sync {
            result = self.map.isEmpty
        }
        return result
    }
}
