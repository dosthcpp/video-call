//
//  JoinViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/26.
//

import UIKit

class JoinViewController: BaseViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var phoneTextField: UITextField!
    
    @IBOutlet var nameLineView: UIView!
    @IBOutlet var emailLineView: UIView!
    @IBOutlet var phoneLineView: UIView!
    
    @IBOutlet var nameLineViewHeight: NSLayoutConstraint!
    @IBOutlet var emailLineViewHeight: NSLayoutConstraint!
    @IBOutlet var phoneLineViewHeight: NSLayoutConstraint!
    
    @IBOutlet var nextButton: UIButton!
    
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
        case .join_back_button:
            self.navigationController?.popViewController(animated: true)
            
        case .join_next_button:
            // TODO: request api
            showConfirmPopup()
            
        default:
            break
        }
    }
    
    // MARK: - function
    func initView() {
        nameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        emailTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        phoneTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        updateTextFieldUI(textField, true)
        updateNextButtonUI()
    }
    
    func updateTextFieldUI(_ textField: UITextField, _ isSelected: Bool) {
        switch textField {
        case nameTextField:
            nameLineViewHeight.constant = isSelected ? 2 : 1
            nameLineView.backgroundColor = isSelected ? #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1) : #colorLiteral(red: 0.7254901961, green: 0.7254901961, blue: 0.7254901961, alpha: 1)
            
        case emailTextField:
            emailLineViewHeight.constant = isSelected ? 2 : 1
            emailLineView.backgroundColor = isSelected ? #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1) : #colorLiteral(red: 0.7254901961, green: 0.7254901961, blue: 0.7254901961, alpha: 1)
            
        case phoneTextField:
            phoneLineViewHeight.constant = isSelected ? 2 : 1
            phoneLineView.backgroundColor = isSelected ? #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1) : #colorLiteral(red: 0.7254901961, green: 0.7254901961, blue: 0.7254901961, alpha: 1)
            
        default:
            break
        }
    }
    
    func updateNextButtonUI() {
        guard let name = nameTextField.text,
              let email = emailTextField.text,
              let phone = phoneTextField.text
        else { return }
        
        if name.isEmpty || email.isEmpty || phone.isEmpty {
            nextButton.isEnabled = false
            nextButton.backgroundColor = #colorLiteral(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
            return
        }
        
        nextButton.isEnabled = true
        nextButton.backgroundColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
    }
    
    func showConfirmPopup() {
        if let confirmPopup = UINib(nibName: "ConfirmPopup", bundle: nil).instantiate(withOwner: self, options: nil).first as? ConfirmPopup {
            guard let bounds = UIApplication.shared.windows.first?.bounds else { return }
            confirmPopup.delegate = self
            confirmPopup.frame = bounds
            confirmPopup.initView("등록되지 않은 사용자입니다.\n담당자에게 문의하세요")
            UIApplication.shared.windows.first?.addSubview(confirmPopup)
        }
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
        nameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        phoneTextField.resignFirstResponder()
    }
}

// MARK: - Extension UITextFieldDelegate
extension JoinViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateTextFieldUI(textField, true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateTextFieldUI(textField, false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameTextField:
            emailTextField.becomeFirstResponder()
            
        case emailTextField:
            phoneTextField.becomeFirstResponder()
            
        case phoneTextField:
            resignAllResponder()
            
        default:
            break
        }
        
        return true
    }
}

// MARK: - Extension ConfirmPopupDelegate
extension JoinViewController: ConfirmPopupDelegate {
    func didCompleted() {
        // TODO: 팝업 닫고 후처리
    }
}
