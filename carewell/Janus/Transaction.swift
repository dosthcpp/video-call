//
// Created by DOYEON BAEK on 2022/10/20.
//

import Foundation

@available(iOS 13.0, *)
public class Transaction {
    private var context: JanusClient
    private var tid: String
    private var feedId: Decimal?

    public init(tid: String, feedId: Decimal?, context: JanusClient) {
        self.context = context
        self.tid = tid
        if let feedId = feedId {
            self.feedId = feedId
        }
    }

    public func onError() {

    }

    public func onSuccess(data: Any) throws {
    }

    public func onSuccess(data: Any, feed: Decimal) throws {

    }

    public func getTid() -> String {
        return tid
    }

    public func getFeedId() -> Decimal? {
        return feedId
    }

    public func setFeedId(feedId: Decimal) {
        self.feedId = feedId
    }
}