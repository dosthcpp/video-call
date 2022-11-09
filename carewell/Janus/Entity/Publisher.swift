//
// Created by DOYEON BAEK on 2022/10/21.
//

import Foundation


public class Publisher {
    private var id: Decimal?
    private var display: String?

    private var handleId: Decimal?

    public init() {}

    public init(id: Decimal, display: String) {
        self.id = id
        self.display = display
    }

    public init(display: String) {
        self.display = display
    }

    public func getId() -> Decimal? {
        return id
    }

    public func getName() -> String? {
        return display
    }

    public func setId(id: Decimal) {
        self.id = id
    }

    public func getDisplay() -> String? {
        return display
    }

    public func setDisplay(display: String) {
        self.display = display
    }

    public func getHandleId() -> Decimal? {
        return handleId
    }

    public func setHandleId(handleId: Decimal) {
        self.handleId = handleId
    }

    public func toString() -> String {
        return "Publisher(id: \(id), display: \(display), handleId: \(handleId))"
    }
}