//
// Created by DOYEON BAEK on 2022/10/21.
//

import Foundation

extension String {

    func replaceCharacters(characters: String, toSeparator: String) -> String {
        let characterSet = CharacterSet(charactersIn: characters)
        let components = components(separatedBy: characterSet)
        let result = components.joined(separator: toSeparator)
        return result
    }

    func wipeCharacters(characters: String) -> String {
        return self.replaceCharacters(characters: characters, toSeparator: "")
    }
}

extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: fileURL, options: .atomic)
        }
    }
}

class File {
    var uniqueMap: [String: Any] = [:]
    var path: String
    let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    init() {
        self.path = documentsUrl.appendingPathComponent("healthcare").appendingPathExtension("properties").path
    }

    func clear() {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: path)
        } catch {
            print("Error while removing file at path: \(path)")
        }
    }

    func exists() -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }

    func createNewFile() {
        FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
    }

    func readDataToEndOfFile() -> Data {
        return FileManager.default.contents(atPath: path)!
    }

    func write(string: String) {
        do {
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let PROPERTY_FILE = documentsUrl.appendingPathComponent("healthcare").appendingPathExtension("properties")
            let dataToWrite = string.components(separatedBy: "=")
            uniqueMap[dataToWrite[0]] = dataToWrite[1]
            var data = ""
            uniqueMap.enumerated().forEach({ (index, element) in
                data += "\(element.key)=\(element.value)"
                if index != uniqueMap.count - 1 {
                    data += "\n"
                }
            })
            if #available(iOS 13.0, *) {
                if let stripped = data.data(using: .utf8) {
                    try stripped.write(to: PROPERTY_FILE, options: .atomic)
                }
            }
        } catch {
            print(error, "error ocurred")
        }
    }

    func close() {

    }
}
