//
// Created by DOYEON BAEK on 2022/10/21.
//

import Foundation

public class Room {
    private var id: UInt64

    public init(id: UInt64) {
        self.id = id
    }

    private var publishers: [Publisher] = []

    public func getId() -> UInt64 {
        return id
    }

    public func setId(id: UInt64) {
        self.id = id
    }

    public func addPublisher(publisher: Publisher) {
        if publishers.contains(where: {publisher in publisher.getId() == publisher.getId()}) {
            return
        }
        publishers.append(publisher)
    }

    public func findPublisherById(id: Decimal) -> Publisher? {
        return publishers.first(where: {publisher in publisher.getId() == id})
    }

    public func findPublisherByUserId(userId: String) -> Publisher? {
        return publishers.first(where: {publisher in publisher.getName() == userId})
    }

    public func removePublisherById(_ id: Decimal) {
        publishers.removeAll(where: {publisher in publisher.getId() == id})
    }
}