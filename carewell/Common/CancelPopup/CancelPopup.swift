//
//  CancelPopup.swift
//  carewell
//
//  Created by 유영문 on 2022/06/07.
//

import UIKit

protocol CancelPopupDelegate: class {
    func didCompleted()
}

class CancelPopup: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var contentLabel: UILabel!
    
    weak var delegate: CancelPopupDelegate?
    
    // MARK: - IBAction
    @IBAction func onTouchCancel(_ sender: UIButton) {
        self.removeFromSuperview()
    }
    
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
