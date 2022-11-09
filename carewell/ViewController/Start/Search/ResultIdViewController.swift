//
//  ResultIdViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/26.
//

import UIKit

protocol ResultIdViewDelegate: class {
    func goToResetPw()
}

class ResultIdViewController: BaseViewController {
    
    @IBOutlet var accountTableView: UITableView!
    @IBOutlet var tableViewHeight: NSLayoutConstraint!
    
    private var modelList: [AccountModel] = []
    weak var delegate: ResultIdViewDelegate?
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    // MARK: - IBAction
    @IBAction func onTouchButton(_ sender: UIButton) {
        guard preventButtonClick, let tag = sender.viewTag else { return }
        
        switch tag {
        case .result_id_back_button:
            self.navigationController?.popViewController(animated: true)
            
        case .result_id_login_button:
            guard let vcs = self.navigationController?.viewControllers else { return }
            
            for vc in vcs {
                if vc is LoginViewController {
                    self.navigationController?.popToViewController(vc, animated: true)
                }
            }
            
        case .result_id_reset_pw_button:
            self.navigationController?.popViewController(animated: true)
            delegate?.goToResetPw()
            
        default:
            break
        }
    }
    
    // MARK: - function
    func initView() {
        guard let d = preparedData?[DELEGATE] as? ResultIdViewDelegate else { return }
        delegate = d
        
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 28))
        header.backgroundColor = .white
        accountTableView.tableHeaderView = header
        
        modelList.append(AccountModel("markx@gmail.com", "2020.08.01"))
        modelList.append(AccountModel("test@naver.com", "2020.08.01"))
        accountTableView.reloadData()
    }
}

// MARK: - Extension UITableViewDelegate, UITableViewDataSource
extension ResultIdViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.tableViewHeight.constant = CGFloat(80 * modelList.count) + 28
        self.view.layoutIfNeeded()
        return modelList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountListCell", for: indexPath) as! AccountListCell
        cell.model = modelList[indexPath.row]
        
        return cell
    }
}
