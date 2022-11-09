//
//  ModifyPwViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/30.
//

import UIKit

class ModifyPwViewController: BaseViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var idTextField: UITextField!
    @IBOutlet var currentPwTextField: UITextField!
    @IBOutlet var newPwTextField: UITextField!
    @IBOutlet var newConfirmPwTextField: UITextField!
    
    @IBOutlet var idLineView: UIView!
    @IBOutlet var currentPwLineView: UIView!
    @IBOutlet var newPwLineView: UIView!
    @IBOutlet var newConfirmPwLineView: UIView!
    
    @IBOutlet var idLineViewHeight: NSLayoutConstraint!
    @IBOutlet var currentPwLineViewHeight: NSLayoutConstraint!
    @IBOutlet var newPwLineViewHeight: NSLayoutConstraint!
    @IBOutlet var newConfirmPwLineViewHeight: NSLayoutConstraint!
    
    @IBOutlet var confirmButton: UIButton!
    
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
        case .modify_pw_back_button:
            self.navigationController?.popViewController(animated: true)
            
        case .modify_pw_confirm_button:
            break
            
        default:
            break
        }
    }
    
    // MARK: - function
    func initView() {
        idTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        currentPwTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        newPwTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        newConfirmPwTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        updateTextFieldUI(textField, true)
        updateConfirmButtonUI()
    }
    
    func updateTextFieldUI(_ textField: UITextField, _ isSelected: Bool) {
        switch textField {
        case idTextField:
            idLineViewHeight.constant = isSelected ? 2 : 1
            idLineView.backgroundColor = isSelected ? #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1) : #colorLiteral(red: 0.7254901961, green: 0.7254901961, blue: 0.7254901961, alpha: 1)
            
        case currentPwTextField:
            currentPwLineViewHeight.constant = isSelected ? 2 : 1
            currentPwLineView.backgroundColor = isSelected ? #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1) : #colorLiteral(red: 0.7254901961, green: 0.7254901961, blue: 0.7254901961, alpha: 1)
            
        case newPwTextField:
            newPwLineViewHeight.constant = isSelected ? 2 : 1
            newPwLineView.backgroundColor = isSelected ? #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1) : #colorLiteral(red: 0.7254901961, green: 0.7254901961, blue: 0.7254901961, alpha: 1)
            
        case newConfirmPwTextField:
            newConfirmPwLineViewHeight.constant = isSelected ? 2 : 1
            newConfirmPwLineView.backgroundColor = isSelected ? #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1) : #colorLiteral(red: 0.7254901961, green: 0.7254901961, blue: 0.7254901961, alpha: 1)
            
        default:
            break
        }
    }
    
    func updateConfirmButtonUI() {
        guard let id = idTextField.text,
              let currentPw = currentPwTextField.text,
              let newPw = newPwTextField.text,
              let newConfirmPw = newConfirmPwTextField.text
        else { return }
        
        if id.isEmpty || currentPw.isEmpty || newPw.isEmpty || newConfirmPw.isEmpty {
            confirmButton.isEnabled = false
            confirmButton.backgroundColor = #colorLiteral(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
            return
        }
        
        confirmButton.isEnabled = true
        confirmButton.backgroundColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
    }
    
    func resignAllResponder() {
        idTextField.resignFirstResponder()
        currentPwTextField.resignFirstResponder()
        newPwTextField.resignFirstResponder()
        newConfirmPwTextField.resignFirstResponder()
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
}

// MARK: - Extension UITextFieldDelegate
extension ModifyPwViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateTextFieldUI(textField, true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateTextFieldUI(textField, false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case idTextField:
            currentPwTextField.becomeFirstResponder()
            
        case currentPwTextField:
            newPwTextField.becomeFirstResponder()
            
        case newPwTextField:
            newConfirmPwTextField.becomeFirstResponder()
            
        case newConfirmPwTextField:
            resignAllResponder()
            
        default:
            break
        }
        
        return true
    }
}
