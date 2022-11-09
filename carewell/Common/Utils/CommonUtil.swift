//
//  CommonUtil.swift
//  carewell
//
//  Created by 유영문 on 2022/05/25.
//

import UIKit

typealias Runnable = () -> ()
typealias Consumer = (Any) -> ()

public class Volatile<T> {
    private var value: T

    public init(_ defaultValue: T) {
        self.value = defaultValue
    }
}

class CommonUtil {
    public static var TAG: String = "CommonUtil"
    
    // MARK: - Show Toast Message
    func showToast(_ message: String) {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.windows.first else { return }
            
            let toastContainer = UIView(frame: CGRect())
            toastContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            toastContainer.alpha = 0.0
            toastContainer.layer.cornerRadius = 25
            toastContainer.clipsToBounds = true
            
            let toastLabel = UILabel(frame: CGRect())
            toastLabel.textColor = .white
            toastLabel.textAlignment = .center
            toastLabel.font.withSize(11.0)
            toastLabel.text = message
            toastLabel.clipsToBounds = true
            toastLabel.numberOfLines = 0
            
            toastContainer.addSubview(toastLabel)
            window.addSubview(toastContainer)
            
            toastLabel.translatesAutoresizingMaskIntoConstraints = false
            toastContainer.translatesAutoresizingMaskIntoConstraints = false
            
            let leadingConstraint1 = NSLayoutConstraint(item: toastLabel, attribute: .leading, relatedBy: .equal, toItem: toastContainer, attribute: .leading, multiplier: 1, constant: 15)
            let trailingConstraint1 = NSLayoutConstraint(item: toastLabel, attribute: .trailing, relatedBy: .equal, toItem: toastContainer, attribute: .trailing, multiplier: 1, constant: -15)
            let bottomConstraint1 = NSLayoutConstraint(item: toastLabel, attribute: .bottom, relatedBy: .equal, toItem: toastContainer, attribute: .bottom, multiplier: 1, constant: -15)
            let topConstraint1 = NSLayoutConstraint(item: toastLabel, attribute: .top, relatedBy: .equal, toItem: toastContainer, attribute: .top, multiplier: 1, constant: 15)
            
            toastContainer.addConstraints([leadingConstraint1, trailingConstraint1, bottomConstraint1, topConstraint1])
            
            let leadingConstraint2 = NSLayoutConstraint(item: toastContainer, attribute: .leading, relatedBy: .equal, toItem: window, attribute: .leading, multiplier: 1, constant: 35)
            let trailingConstraint2 = NSLayoutConstraint(item: toastContainer, attribute: .trailing, relatedBy: .equal, toItem: window, attribute: .trailing, multiplier: 1, constant: -35)
            let bottomConstraint2 = NSLayoutConstraint(item: toastContainer, attribute: .bottom, relatedBy: .equal, toItem: window, attribute: .bottom, multiplier: 1, constant: -100)
            
            window.addConstraints([leadingConstraint2, trailingConstraint2, bottomConstraint2])
            
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
                toastContainer.alpha = 1.0
            }, completion: {_ in
                UIView.animate(withDuration: 0.5, delay: 1.5, options: .curveEaseOut, animations: {
                    toastContainer.alpha = 0.0
                }, completion: {_ in
                    toastContainer.removeFromSuperview()
                })
            })
        }
    }
    
    
    
    // MARK: - Show Alert
    func alert(vc: UIViewController, title: String? = nil, message: String? = nil, confirm: String, cancel: String? = nil, confirmHandler: ((UIAlertAction) -> Void)? = nil, cancelHandler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if let cancel = cancel {
            let cancelAction = UIAlertAction(title: cancel, style: .default) { (action) in
                if let cancelHandler = cancelHandler {
                    cancelHandler(action)
                }
            }
            
            alert.addAction(cancelAction)
        }
        
        let confirmAction = UIAlertAction(title: confirm, style: .default) { (action) in
            if let confirmHandler = confirmHandler {
                confirmHandler(action)
            }
        }
        
        alert.addAction(confirmAction)
        
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    func toDateString(date: Date) -> String {
        let dateFormat = DateFormatter()
        dateFormat.locale = Locale(identifier: "ko_kr")
        dateFormat.dateStyle = .long
        return dateFormat.string(from: date)
    }
    
    func generateRandom(length: Int) -> String {
        let letters = "0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    //MARK: - Get Current App Version
    /**
     현재 앱 버전 Retrun
     - returns: 현재 앱 버전 문자열
     */
    func getCurrentVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        } else {
            return ""
        }
    }
    
    class var currentTime: UInt64 { // micro seconds
        return UInt64(NSDate().timeIntervalSince1970 * 1000)
    }
}
