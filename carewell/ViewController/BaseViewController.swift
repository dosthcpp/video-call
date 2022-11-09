//
//  BaseViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/25.
//

import UIKit

typealias CallBackClosure = ((Any?) -> ())

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

class BaseViewController: UIViewController {
    var preparedData: [String : Any]?
    var nextPrepareData: [String : Any]?
    var callbackDataClosure: CallBackClosure? = nil
    var nextCallbackDataClosure: CallBackClosure? = nil
    
    fileprivate var timeStamp: UInt64 = 0
    var preventButtonClick: Bool {
        guard (CommonUtil.currentTime - timeStamp) > 500 else { return false }
        timeStamp = CommonUtil.currentTime
        return true
    }
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? BaseViewController {
            if let next = nextPrepareData {
                destination.preparedData = next
                nextPrepareData = nil
            }
            if let callback = nextCallbackDataClosure {
                destination.callbackDataClosure = callback
                nextCallbackDataClosure = nil
            }
        }
        super.prepare(for: segue, sender: sender)
    }
}

// MARK: - Extension UINavigationControllerDelegate, UIGestureRecognizerDelegate
extension BaseViewController: UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if self.navigationController?.viewControllers.count ?? 0 > 1 {
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        } else {
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
    }
}
