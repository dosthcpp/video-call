//
//  UIExtension.swift
//  carewell
//
//  Created by 유영문 on 2022/05/25.
//

import Foundation
import UIKit

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localizedWithComment(_ comment:String) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: comment)
    }
    
    func removeWhiteSpaces() -> String {
        return components(separatedBy: .whitespacesAndNewlines).joined()
    }
    
    var isValidEmail: Bool {
        get {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with:self)
        }
    }
    
    var isValidPassword: Bool {
        get {
            let pwRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9]).{8,}$"
            return NSPredicate(format: "SELF MATCHES %@", pwRegex).evaluate(with:self)
        }
    }
}

extension UIView {
    @IBInspectable var borderWitdh: CGFloat {
        get {
            return 0.0
        }
        set {
            layer.borderWidth = newValue
        }
    }
    @IBInspectable var borderColor: UIColor {
        get {
            return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        }
        set {
            layer.borderColor = newValue.cgColor
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return 0.0
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    
    var viewTag: ViewTag? {
        return ViewTag(rawValue: self.tag)
    }
    
    func viewWithViewTag(_ tag: ViewTag) -> UIView? {
        return self.viewWithTag(tag.rawValue)
    }
}

extension UILabel {
    @IBInspectable var localizedKey: String? {
        get {
            return nil
        }
        set {
            text = newValue?.localized
        }
    }
}

extension UIButton {
    @IBInspectable var localizedKey: String? {
        get {
            return nil
        }
        
        set {
            setTitle(newValue?.localized, for: .normal)
            setTitle(newValue?.localized, for: .highlighted)
            setTitle(newValue?.localized, for: .selected)
        }
    }
    
    func roundCorners(corners: UIRectCorner, radius: CGFloat, btnColor: CGColor) {
        let borderLayer = CAShapeLayer()
        borderLayer.frame = self.layer.bounds
        borderLayer.fillColor = btnColor
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        borderLayer.path = path.cgPath
        self.layer.addSublayer(borderLayer)
    }
    
    func setBackgroundColor(color: UIColor, forState: UIControl.State) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()?.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: forState)
    }
}

@IBDesignable
extension UITextField {
    
    @IBInspectable var localizedKey: String? {
        get {
            return nil
        }
        set {
            placeholder = newValue?.localized
        }
    }
    
    @IBInspectable var paddingLeftCustom: CGFloat {
        get {
            return leftView!.frame.size.width
        }
        set {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: newValue, height: frame.size.height))
            leftView = paddingView
            leftViewMode = .always
        }
    }
    
    @IBInspectable var paddingRightCustom: CGFloat {
        get {
            return rightView!.frame.size.width
        }
        set {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: newValue, height: frame.size.height))
            rightView = paddingView
            rightViewMode = .always
        }
    }
}

extension UINavigationController {
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        self.navigationBar.setValue(true, forKey: "hidesShadow")
    }
    
    open override var shouldAutorotate: Bool {
        return false
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
