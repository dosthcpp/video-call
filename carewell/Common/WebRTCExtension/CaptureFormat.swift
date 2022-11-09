//
// Created by DOYEON BAEK on 2022/10/21.
//

import Foundation

class CaptureFormat {
    var width: Int
    var height: Int
    var fps: Int
    var maxFps: Int
    var minFps: Int
    var pixelFormat: Int

    init(width: Int, height: Int, fps: Int, maxFps: Int, minFps: Int, pixelFormat: Int) {
        self.width = width
        self.height = height
        self.fps = fps
        self.maxFps = maxFps
        self.minFps = minFps
        self.pixelFormat = pixelFormat
    }
}
