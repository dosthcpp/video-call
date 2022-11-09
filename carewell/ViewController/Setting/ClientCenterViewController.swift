//
//  ClientCenterViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/30.
//

import UIKit

class ClientCenterViewController: BaseViewController {
    
    @IBOutlet var phoneLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    // MARK: - IBAction
    @IBAction func onTouchBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - IBAction
    func initView() {
        // TODO: Get phone and email data
        phoneLabel.text = "0000-0000"
        emailLabel.text = "000000@marknova.co.kr"
    }
}
