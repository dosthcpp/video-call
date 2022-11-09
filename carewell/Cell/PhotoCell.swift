//
// Created by DOYEON BAEK on 2022/10/19.
//

import UIKit

final class PhotoCell: UICollectionViewCell {
    static let id = "PhotoCell"
    var stringTag: String?

    // MARK: UI
    @IBOutlet var imageView: UIImageView! = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFill
        return view
    }()

    var isRendered = false

    var isChecked: Bool? {
        didSet {
            if isChecked == true {
                // remove the border
                circleView.layer.borderWidth = 0
                // get an asset named ic_big_check_selected
                let imageView = createCheckCircle()
                imageView.layer.cornerRadius = 15
                imageView.layer.masksToBounds = true
                // set the image to the circleView
                circleView.subviews.first?.removeFromSuperview()
                circleView.addSubview(imageView)
            } else {
                circleView.subviews.forEach({ $0.removeFromSuperview() })
                circleView.layer.borderWidth = 1
            }
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

    // create a circle view with radius 10
    @IBOutlet public var circleView: UIView! = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // uicolor with black, opacity 0.3
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        view.layer.cornerRadius = 15
        // set the border color to white
        view.layer.borderColor = UIColor.white.cgColor
        // border with 1 px
        view.layer.borderWidth = 1
        view.clipsToBounds = true
        return view
    }()

    // MARK: Initializer
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.masksToBounds = true // 주의: 이값을 안주면 이미지가 셀의 다른 영역을 침범하는 영향을 주는것
        self.contentView.addSubview(self.imageView)

        NSLayoutConstraint.activate([
            self.imageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.imageView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            self.imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
        ])

        self.contentView.addSubview(circleView)
        // align it to the top right corner with margin 10
        NSLayoutConstraint.activate([
            circleView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -10),
            circleView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10),
            circleView.widthAnchor.constraint(equalToConstant: 30),
            circleView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.prepare(image: nil)
    }

    func prepare(image: UIImage?) {
        self.imageView.image = image
    }

    func setStringTag(stringTag: String) {
        self.stringTag = stringTag
    }
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
}
