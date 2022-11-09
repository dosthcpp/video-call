//
//  ConfirmPopup.swift
//  carewell
//
//  Created by 유영문 on 2022/05/26.
//

import UIKit

protocol ConfirmPopupDelegate: class {
    func didCompleted()
}

class ConfirmPopup: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var contentLabel: UILabel!
    
    weak var delegate: ConfirmPopupDelegate?
    
    // MARK: - IBAction
    @IBAction func onTouchConfirm(_ sender: UIButton) {
        delegate?.didCompleted()
        self.removeFromSuperview()
    }
    
    // MARK: - function
    func initView(_ content: String) {
        contentLabel.text = content
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    }
}
