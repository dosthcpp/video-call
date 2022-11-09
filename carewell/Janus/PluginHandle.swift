//
// Created by DOYEON BAEK on 2022/10/20.
//

import Foundation

public class PluginHandle {
    private var handleId: Decimal

    public init(handleId: Decimal) {
        self.handleId = handleId
    }

    public func getHandleId() -> Decimal {
        handleId
    }

    public func setHandleId(handleId: Decimal) {
        self.handleId = handleId
    }
}