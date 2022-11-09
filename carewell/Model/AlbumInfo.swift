//
// Created by DOYEON BAEK on 2022/10/19.
//

import Photos
import UIKit

struct AlbumInfo: Identifiable {
    let id: String?
    let name: String
    let count: Int
    let album: PHFetchResult<PHAsset>
}