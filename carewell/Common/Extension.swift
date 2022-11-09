//
// Created by DOYEON BAEK on 2022/10/12.
//

import Foundation

extension Int {
    func zeroPadding() -> String {
        String(format: "%02d", self)
    }
}