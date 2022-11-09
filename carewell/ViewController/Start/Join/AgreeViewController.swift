//
//  AgreeViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/26.
//

import UIKit

class AgreeViewController: BaseViewController {
    
    @IBOutlet var nameLabel: UILabel!
    
    @IBOutlet var agreeAllButton: UIButton!
    @IBOutlet var agreeButtons: [UIButton]!
    
    @IBOutlet var confirmButton: UIButton!
    @IBOutlet var bottomView: UIView!
    
    fileprivate let SHOW_JOIN_PAGE = "show_join_page"
    private var isAgree: Bool = false
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    // MARK: - IBAction
    @IBAction func onTouchButton(_ sender: UIButton) {
        guard preventButtonClick, let tag = sender.viewTag else { return }
        
        switch tag {
        case .agree_all_button:
            agreeAllButton.isSelected = !agreeAllButton.isSelected
            
            for btn in agreeButtons {
                btn.isSelected = agreeAllButton.isSelected
            }
            updateUI()
            
        case .agree_service_button, .agree_private_button:
            for btn in agreeButtons {
                if btn.tag == sender.tag {
                    btn.isSelected = !btn.isSelected
                }
            }
            updateUI()
            
        case .agree_service_detail_button, .agree_private_detail_button:
            // TODO: move to terms page
            break
            
        case .agree_confirm_button:
            performSegue(withIdentifier: SHOW_JOIN_PAGE, sender: nil)
            
        default:
            break
        }
    }
    
    // MARK: - function
    func updateUI() {
        var isChecked = true
        
        for btn in agreeButtons {
            if !btn.isSelected {
                isChecked = false
            }
        }
        isAgree = isChecked
        agreeAllButton.isSelected = isAgree
        confirmButton.isEnabled = isAgree
        confirmButton.backgroundColor = isAgree ? #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1) : #colorLiteral(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        bottomView.backgroundColor = isAgree ? #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1) : #colorLiteral(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
    }
}
