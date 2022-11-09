//
//  TermsDetailViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/30.
//

import UIKit

class TermsDetailViewController: BaseViewController {
    
    @IBOutlet var titleLabel: UILabel!
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    // MARK: - IBAction
    @IBAction func onTouchBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - function
    func initView() {
        guard let title = preparedData?[TITLE] as? String else { return }
        
        titleLabel.text = title
    }
}
