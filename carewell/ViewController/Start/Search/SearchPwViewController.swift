//
//  SearchPwViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/26.
//

import UIKit

class SearchPwViewController: BaseViewController {
    
    @IBOutlet var idContainerView: UIView!
    @IBOutlet var resetContainerView: UIView!
    
    @IBOutlet var idTextField: UITextField!
    @IBOutlet var pwTextField: UITextField!
    @IBOutlet var pwConfirmTextField: UITextField!
    
    @IBOutlet var idLineView: UIView!
    @IBOutlet var pwLineView: UIView!
    @IBOutlet var pwConfirmLineView: UIView!
    
    @IBOutlet var idLineViewHeight: NSLayoutConstraint!
    @IBOutlet var pwLineViewHeight: NSLayoutConstraint!
    @IBOutlet var pwConfirmLineViewHeight: NSLayoutConstraint!
    
    @IBOutlet var pwCheckImageView: UIImageView!
    @IBOutlet var pwConfirmCheckImageView: UIImageView!
    
    @IBOutlet var resetButton: UIButton!
    
    private var popupType: PopupType = .CLOSE
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    // MARK: - IBAction
    @IBAction func onTouchConfirm(_ sender: UIButton) {
        guard preventButtonClick else { return }
        
        let id = idTextField.text ?? ""
        
        if id.isEmpty || !id.isValidEmail{
            popupType = .CLOSE
            showConfirmPopup("잘못된 아이디(이메일)입니다.")
            return
        }
        resignAllResponder()
        idContainerView.isHidden = true
        resetContainerView.isHidden = false
    }
    
    @IBAction func onTouchReset(_ sender: UIButton) {
        resignAllResponder()
        popupType = .COMPLETE
        showConfirmPopup("변경이 완료되었습니다.\n로그인 화면으로 이동합니다.")
    }
    
    // MARK: - function
    func initView() {
        idTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        pwTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        pwConfirmTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
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
            updateResetButtonUI()
            
            guard let pw = pwTextField.text else { return }
            pwCheckImageView.isHidden = !pw.isValidPassword
            pwLineView.backgroundColor = pw.isValidPassword ? #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1) : pwLineView.backgroundColor
            
        case pwConfirmTextField:
            pwConfirmLineViewHeight.constant = isSelected ? 2 : 1
            pwConfirmLineView.backgroundColor = isSelected ? #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1) : #colorLiteral(red: 0.7254901961, green: 0.7254901961, blue: 0.7254901961, alpha: 1)
            updateResetButtonUI()
            
            guard let pwConfirm = pwConfirmTextField.text else { return }
            pwConfirmCheckImageView.isHidden = !pwConfirm.isValidPassword
            pwConfirmLineView.backgroundColor = pwConfirm.isValidPassword ? #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1) : pwConfirmLineView.backgroundColor
            
        default:
            break
        }
    }
    
    func updateResetButtonUI() {
        guard let pw = pwTextField.text,
              let pwConfirm = pwConfirmTextField.text
        else { return }
        
        if pw.isEmpty || pwConfirm.isEmpty {
            resetButton.isEnabled = false
            resetButton.backgroundColor = #colorLiteral(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
            return
        }
        
        if !pw.isValidPassword || pw != pwConfirm{
            resetButton.isEnabled = false
            resetButton.backgroundColor = #colorLiteral(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
            return
        }
        
        resetButton.isEnabled = true
        resetButton.backgroundColor = #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1)
    }
    
    func resignAllResponder() {
        idTextField.resignFirstResponder()
        pwTextField.resignFirstResponder()
        pwConfirmTextField.resignFirstResponder()
    }
    
    func showConfirmPopup(_ text: String) {
        if let confirmPopup = UINib(nibName: "ConfirmPopup", bundle: nil).instantiate(withOwner: self, options: nil).first as? ConfirmPopup {
            guard let bounds = UIApplication.shared.windows.first?.bounds else { return }
            confirmPopup.frame = bounds
            confirmPopup.delegate = self
            confirmPopup.initView(text)
            UIApplication.shared.windows.first?.addSubview(confirmPopup)
        }
    }
}

// MARK: - Extension UITextFieldDelegate
extension SearchPwViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateTextFieldUI(textField, true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateTextFieldUI(textField, false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case idTextField:
            resignAllResponder()
            
        case pwTextField:
            pwConfirmTextField.becomeFirstResponder()
            
        case pwConfirmTextField:
            resignAllResponder()
            
        default:
            break
        }
        
        return true
    }
}

// MARK: - Extension ConfirmPopupDelegate
extension SearchPwViewController: ConfirmPopupDelegate {
    func didCompleted() {
        if popupType == .COMPLETE {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
