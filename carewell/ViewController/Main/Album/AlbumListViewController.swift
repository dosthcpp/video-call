//
//  AlbumListViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/27.
//

import UIKit
import Photos
import CommonCrypto
import MultipartForm

@available(iOS 13.0, *)
class AlbumListViewController: BaseViewController {
    private enum Const {
        static let numberOfColumns = 3.0
        static let cellSpace = 0.0
        static let length = (UIScreen.main.bounds.size.width - cellSpace * (numberOfColumns - 1)) / numberOfColumns
        static let cellSize = CGSize(width: length, height: length)
        static let scale = 1.0 // UIScreen.main.scale
    }

    private let collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = Const.cellSpace
        layout.minimumInteritemSpacing = Const.cellSpace
        layout.itemSize = Const.cellSize
        return layout
    }()

    @IBOutlet var collectionView: UICollectionView! = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.isScrollEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = true
        view.contentInset = .zero
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var checkedIndexes: [Bool] = [Bool]()
    private var tapManually: [Bool] = [Bool]()
    let imageCheckerGroup = DispatchGroup()
    var downloadedPaths: [String: Bool] = [:]
    var count = 0
    var rendered = false

    private var albums: [AlbumInfo] = []
//    private var metaData: [URL: Data] = [URL: Data]()
    private var currentAlbumIndex = 0 {
        didSet {
            PhotoService.shared.getPHAssets(album: self.albums[self.currentAlbumIndex].album) { [weak self] phAssets in
                self?.phAssets = phAssets
            }
        }
    }
    private var currentAlbum: PHFetchResult<PHAsset>? {
        guard self.currentAlbumIndex <= self.albums.count - 1 else {
            return nil
        }
        return self.albums[self.currentAlbumIndex].album
    }
    private var phAssets = [PHAsset]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    @IBOutlet var tableView: UITableView!

    @IBOutlet var countView: UIView!
    @IBOutlet var countLabel: UILabel!

    fileprivate let SHOW_NOTICE_PAGE = "show_notice_page"
    fileprivate let SHOW_SETTING_PAGE = "show_setting_page"

    func requestAlbumAuthorization(_ completion: @escaping (Bool) -> Void) {
        if #available(iOS 14.0, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                completion([.authorized, .limited].contains(where: { $0 == status }))
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                completion(status == .authorized)
            }
        }
    }

    // MARK: - override

    override func viewDidLoad() {
        super.viewDidLoad()

        initialize()
        initData()
    }

    // MARK: - IBAction

    @IBAction func onTouchButton(_ sender: UIButton) {
        guard preventButtonClick, let tag = sender.viewTag else {
            return
        }

        switch tag {
        case .header_notice_button:
            performSegue(withIdentifier: SHOW_NOTICE_PAGE, sender: nil)

        case .header_setting_button:
            performSegue(withIdentifier: SHOW_SETTING_PAGE, sender: nil)

        case .album_list_setting_button:
            break

        case .album_list_send_button:
            // print a selected index
            // get the index of the selected cell from isSelected
            Task {
                // selected must conform to AsyncSequence
                let selected = await self.checkedIndexes.enumerated().filter {
                            $0.element
                        }
                        .map {
                            $0.offset
                        }
                let session = URLSession.shared
                let boundary = UUID().uuidString
                var forms: [MultipartForm.Part] = []
                var metas: [String: Any] = [:]
                var returned = true
                let group = DispatchGroup()
                for el in selected {
                    let options = PHContentEditingInputRequestOptions()
                    options.isNetworkAccessAllowed = true
                    group.enter()
                    self.phAssets[el].requestContentEditingInput(with: options) { [self] (input, _) in
                        if input == nil {
                            returned = false
                        }
                        if let path = input?.fullSizeImageURL {
                            let fileName = "photo\(el).jpg"
                            var meta = [String]()
                            let data = try? Data(contentsOf: path)
                            meta.append(path.absoluteString)
                            if let data = data {
                                guard let stringData = String(data: data, encoding: .ascii) else {
                                    return
                                }
                                meta.append(MD5(string: stringData).base64EncodedString())
                                metas[fileName] = meta

                                forms.append(MultipartForm.Part(name: "photo", data: data, filename: fileName, contentType: "image/jpeg"))
                            }
                        }
                        group.leave()
                    }
                }
                group.notify(queue: DispatchQueue.main) { [self] in
                    if returned {
                        let url = URLComponents(scheme: "https", host: "api-test.carewellplus.co.kr", path: "/api_cc/v1/upload_album", queryItems: [
                            URLQueryItem(name: "metadata", value: json(from: metas))
                        ]).url!
                        var urlRequest = URLRequest(url: url)
                        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                        urlRequest.httpMethod = "POST"
                        let form: MultipartForm = MultipartForm(parts: forms + [
                            MultipartForm.Part(name: "guardian_id", value: Global.shared.getPhoneNumber()),
                        ], boundary: boundary)
                        // Send a POST request to the URL, with the data we created earlier
                        session.uploadTask(with: urlRequest, from: form.bodyData, completionHandler: { responseData, response, error in
                                    if error == nil {
                                        let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
                                        if let json = jsonData as? [String: Any] {
                                            print(json)
                                        }
                                    } else {
                                        print(error)
                                    }
                                })
                                .resume()
//                        // reset ischecked array
//                        checkedIndexesForUpload = [Bool](repeating: false, count: self.phAssets.count)
//                        // loop through the collection view
//                        collectionView.visibleCells.forEach { cell in
//                            guard let circleView: UIView = (cell as? PhotoCell)?.circleView else {
//                                return
//                            }
//                            circleView.subviews.forEach({ $0.removeFromSuperview() })
//                            circleView.layer.borderWidth = 1
//                        }
//                        countView.isHidden = true
                        showConfirmPopup()
                    } else {
                        print("error")
                    }
                }
            }
            break
        default:
            break
        }
    }

    func showConfirmPopup() {
        if let confirmPopup = UINib(nibName: "ConfirmPopup", bundle: nil).instantiate(withOwner: self, options: nil).first as? ConfirmPopup {
            guard let bounds = UIApplication.shared.windows.first?.bounds else {
                return
            }
            confirmPopup.delegate = self
            confirmPopup.frame = bounds
            confirmPopup.initView("업로드가 완료되었습니다.")
            UIApplication.shared.windows.first?.addSubview(confirmPopup)
        }
    }

    // MARK: - function

    func initialize() {
        self.requestAlbumAuthorization({ isAuthorized in
            if isAuthorized {
                PhotoService.shared.getAlbums(mediaType: .image, completion: { [self] albums in
                    DispatchQueue.main.async {
                        self.albums = albums
                        self.modalPresentationStyle = .fullScreen
                        self.view.backgroundColor = .white

                        PhotoService.shared.delegate = self
                        self.collectionView.dataSource = self

                        self.collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.id)
                        self.collectionView.collectionViewLayout = self.collectionViewFlowLayout // 안해주면 원하는대로 안됨

                        self.view.addSubview(self.collectionView)

                        PhotoService.shared.getPHAssets(album: self.albums[self.currentAlbumIndex].album) { [weak self] phAssets in
                            self?.phAssets = phAssets
                        }

                        self.checkedIndexes = (0..<self.phAssets.count).map { _ in
                            false
                        }
                        self.tapManually = (0..<self.phAssets.count).map { _ in
                            false
                        }
//                        initData()
                    }
                })
            } else {

            }
        })
    }

    public func initData() {
        // reset ischecked array
        var returned = true
        let url = URL(string: "\(Consts.baseUrl)/api_cc/v1/download_album")!
        imageCheckerGroup.enter()
        InfomarkClient().post(param: [
            "req_type": "guardian",
            "guardian_id": Global.shared.getPhoneNumber()
        ], url: url, runnable: { [self] obj in
            if obj == nil {
                returned = false
            }
            let jsonObject = obj as! NSDictionary
            if jsonObject["list"] != nil {
                let objCArray = NSMutableArray(object: jsonObject["list"]!)
                if let swiftArray = objCArray as NSArray? as? [Any] {
                    for i in 0...swiftArray.count - 1 {
                        if let albumArray = swiftArray[i] as? [[String: Any]] {
                            for j in 0...albumArray.count - 1 {
                                let album = albumArray[j]
                                if let original_path = album["original_path"] as? String {
                                    downloadedPaths[original_path] = false
                                }
                            }
                            count = albumArray.count
                        }
                    }
                }
            }
            imageCheckerGroup.leave()
        })
    }
}

@available(iOS 13.0, *)
extension AlbumListViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("change!")
    }
}

@available(iOS 13.0, *)
extension AlbumListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.phAssets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell: PhotoCell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.id, for: indexPath) as? PhotoCell else {
            fatalError()
        }

        PhotoService.shared.fetchImage(
                asset: self.phAssets[indexPath.item],
                size: .init(width: Const.length * Const.scale, height: Const.length * Const.scale),
                contentMode: .aspectFill
        ) { [weak cell] image in
            self.imageCheckerGroup.notify(queue: .main) { [self] in
                cell?.prepare(image: image)
                cell?.tag = indexPath.item
                // set tapgesture recognizer to the cell
                cell?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:))))
                if !tapManually[indexPath.item] {
                    phAssets[indexPath.item].requestContentEditingInput(with: PHContentEditingInputRequestOptions(), completionHandler: { [self] (input, _) in
                        if let path = input?.fullSizeImageURL {
                            // select the cell programatically
                            var i = 0
                            while i < downloadedPaths.keys.count {
                                let index = downloadedPaths.index(downloadedPaths.startIndex, offsetBy: i)
                                if downloadedPaths.keys[index] == path.absoluteString {
                                    break
                                }
                                i += 1
                            }
                            if i < downloadedPaths.keys.count {
                                cell?.isChecked = true
                                checkedIndexes[indexPath.item] = true
                            } else {
                                cell?.isChecked = false
                                checkedIndexes[indexPath.item] = false
                            }
                        }
                    })
                } else {
                    if checkedIndexes[indexPath.item] && cell?.isChecked == false {
                        cell?.isChecked = true
                    } else if !checkedIndexes[indexPath.item] && cell?.isChecked == true {
                        cell?.isChecked = false
                    }
                }


                view.bringSubviewToFront(countView)
                countLabel.text = "\(count)"
                if count != 0 {
                    countView.isHidden = false
                }

                // swap cell to the first index
//                if let cell = (collectionView.cellForItem(at: myIndex) as? PhotoCell) {
//                    collectionView.moveItem(at: myIndex, to: IndexPath(item: i, section: 0))
//                }

            }
        }

        return cell
    }

    func MD5(string: String) -> Data {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = string.data(using: .utf8)!
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData
    }

    func json(from object: Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard let cell = sender.view as? PhotoCell else {
            return
        }
        guard let circleView: UIView = (sender.view as? PhotoCell)?.circleView else {
            return
        }
        if let index: Int = sender.view?.tag {
            tapManually[index] = true
            if checkedIndexes[index] {
                circleView.subviews.forEach({ $0.removeFromSuperview() })
                circleView.layer.borderWidth = 1
                cell.isChecked = false
                count -= 1
            } else {
                // remove the border
                circleView.layer.borderWidth = 0
                // get an asset named ic_big_check_selected
                let imageView = createCheckCircle()
                imageView.layer.cornerRadius = 15
                imageView.layer.masksToBounds = true
                // set the image to the circleView
                circleView.subviews.first?.removeFromSuperview()
                circleView.addSubview(imageView)
                cell.isChecked = true
                count += 1
            }
            checkedIndexes[index] = !checkedIndexes[index]
        }
        // get the count of true in isChecked
        let count = checkedIndexes.filter({ $0 }).count
        if count > 0 {
            view.bringSubviewToFront(countView)
            countLabel.text = "\(count)"
            countView.isHidden = false
        } else {
            countView.isHidden = true
        }
    }

    func createCheckCircle() -> UIImageView {
        let image = UIImage(named: "ic_big_check_selected")
        // set the image size to 15x15
        let size = CGSize(width: 30, height: 30)
        let rect = CGRect(origin: .zero, size: size)
        // create a new image with the size
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image?.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let imageView = UIImageView(image: newImage)
        return imageView
    }
}

extension URLComponents {
    init(scheme: String = "https",
         host: String = "www.google.com",
         path: String = "/search",
         queryItems: [URLQueryItem]) {
        self.init()
        self.scheme = scheme
        self.host = host
        self.path = path
        self.queryItems = queryItems
    }
}

@available(iOS 13.0, *)
extension AlbumListViewController: ConfirmPopupDelegate {
    func didCompleted() {
        // TODO: 팝업 닫고 후처리
    }
}
