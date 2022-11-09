//
//  ViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/25.
//

import UIKit

class LoginViewController: BaseViewController {

    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var idTextField: UITextField!
    @IBOutlet var pwTextField: UITextField!
    
    @IBOutlet var idLineView: UIView!
    @IBOutlet var pwLineView: UIView!
    
    @IBOutlet var idLineViewHeight: NSLayoutConstraint!
    @IBOutlet var pwLineViewHeight: NSLayoutConstraint!
    
    @IBOutlet var errorLabel: UILabel!
    
    fileprivate let SHOW_AGREE_PAGE = "show_agree_page"
    fileprivate let SHOW_SEARCH_PAGE = "show_search_page"
    fileprivate let SHOW_MAIN_PAGE = "show_main_page"
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObserver()
    }
    
    // MARK: - IBAction
    @IBAction func onTouchBackground(_ sender: UIControl) {
        resignAllResponder()
    }
    
    @IBAction func onTouchButton(_ sender: UIButton) {
        guard preventButtonClick, let tag = sender.viewTag else { return }
        
        switch tag {
        case .login_button:
            let id = idTextField.text ?? ""
            let pw = pwTextField.text ?? ""
            
            if id.isEmpty {
                CommonUtil().showToast("아이디를 입력해주세요.")
                return
            }
            if pw.isEmpty {
                CommonUtil().showToast("비밀번호를 입력해주세요.")
                return
            }
//            showError("아이디가 없거나 또는 비밀번호가 일치하지 않습니다.")
            performSegue(withIdentifier: SHOW_MAIN_PAGE, sender: nil)
            break
            
        case .login_search_button:
            performSegue(withIdentifier: SHOW_SEARCH_PAGE, sender: nil)
            
        case .login_join_button:
            performSegue(withIdentifier: SHOW_AGREE_PAGE, sender: nil)
            
        default:
            break
        }
    }
    
    // MARK: - function
    func initView() {
        idTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        pwTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        updateTextFieldUI(textField, true)
    }
    
    func updateTextFieldUI(_ textField: UITextField, _ isSelected: Bool) {
        switch textField {
        case idTextField:
            idLineViewHeight.constant = isSelected ? 2 : 1
            idLineView.backgroundColor = isSelected ? #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1) : #colorLiteral(red: 0.7254901961, green: 0.7254901961, blue: 0.7254901961, alpha: 1)
            
        case pwTextField:
            pwLineViewHeight.constant = isSelected ? 2 : 1
            pwLineView.backgroundColor = isSelected ? #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1) : #colorLiteral(red: 0.7254901961, green: 0.7254901961, blue: 0.7254901961, alpha: 1)
            
        default:
            break
        }
        
        hideError()
    }
    
    func showError(_ text: String) {
        errorLabel.isHidden = false
        errorLabel.text = text
    }
    
    func hideError() {
        errorLabel.isHidden = true
    }
    
    // MARK: Notification observer for scrollview
    func addObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil){
            notification in
            self.keyboardWillShow(notification : notification)
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil){
            notification in
            self.keyboardWillHide(notification : notification)
        }
    }
    
    func removeObserver(){
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardWillShow(notification : Notification){
        guard let userInfo = notification.userInfo,
            let frame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
        }
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: frame.height, right: 0)
        scrollView.contentInset = contentInset
    }
    
    func keyboardWillHide(notification : Notification){
        scrollView.contentInset = UIEdgeInsets.zero
    }
    
    func resignAllResponder() {
        idTextField.resignFirstResponder()
        pwTextField.resignFirstResponder()
    }
}

// MARK: - Extension UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateTextFieldUI(textField, true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateTextFieldUI(textField, false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case idTextField:
            pwTextField.becomeFirstResponder()
            
        case pwTextField:
            resignAllResponder()
            
        default:
            break
        }
        
        return true
    }
}
