//
//  JoinSettingViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/06/03.
//

import UIKit

protocol JoinSettingViewDelegate: class {
    func setSelectedPerson(_ name: String)
}

class JoinSettingViewController: BaseViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var joinTableView: UITableView!
    @IBOutlet var searchTableView: UITableView!
    
    @IBOutlet var joinTableViewHeight: NSLayoutConstraint!
    @IBOutlet var searchTableViewHeight: NSLayoutConstraint!
    
    @IBOutlet var searchTextField: UITextField!
    
    private var joinModelList: [FriendModel] = []
    private var searchModelList: [FriendModel] = []
    
    weak var delegate: JoinSettingViewDelegate?
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    // MARK: - IBAction
    @IBAction func onTouchBackground(_ sender: UIControl) {
        searchTextField.resignFirstResponder()
    }
    
    @IBAction func onTouchButton(_ sender: UIButton) {
        guard preventButtonClick, let tag = sender.viewTag else { return }
        
        switch tag {
        case .join_setting_cancel_button:
            self.dismiss(animated: true)
            
        case .join_setting_search_button:
            let searchText = searchTextField.text ?? ""
            
            // TODO: Search API
            searchModelList.removeAll()
            searchModelList.append(FriendModel(1, "김말자"))
            searchModelList.append(FriendModel(2, "김태희"))
            searchModelList.append(FriendModel(3, "홍길동"))
            searchTableView.reloadData()
            
        case .join_setting_confirm_button:
            if joinModelList.isEmpty {
                CommonUtil().showToast("참석자를 추가해 주세요.")
                return
            }
            var result: String = ""
            for model in joinModelList {
                result += "\(model.name),"
            }
            result.removeLast()
            delegate?.setSelectedPerson(result)
            self.dismiss(animated: true)
            
        default:
            break
        }
    }
    
    // MARK: - function
    func initView() {
        
    }
}

// MARK: - Extension UITableViewDelegate, UITableViewDataSource
extension JoinSettingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView {
        case joinTableView:
            return 55.0
            
        case searchTableView:
            return 40.0
            
        default:
            return 55.0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case joinTableView:
            self.joinTableViewHeight.constant = CGFloat(55 * joinModelList.count)
            self.view.layoutIfNeeded()
            return joinModelList.count
            
        case searchTableView:
            self.searchTableViewHeight.constant = CGFloat(40 * searchModelList.count) + 85
            self.view.layoutIfNeeded()
            return searchModelList.count
            
        default:
            return joinModelList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case joinTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "JoinListCell", for: indexPath) as! JoinListCell
            cell.model = joinModelList[indexPath.row]
            cell.delegate = self
            cell.deleteButton.tag = indexPath.row
            
            return cell
            
        case searchTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchListCell", for: indexPath) as! SearchListCell
            cell.model = searchModelList[indexPath.row]
            cell.delegate = self
            cell.addButton.tag = indexPath.row
            
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "JoinListCell", for: indexPath) as! JoinListCell
            cell.model = joinModelList[indexPath.row]
            
            return cell
        }
    }
}
// MARK: - Extension JoinListCellDelegate, SearchListCellDelegate
extension JoinSettingViewController: JoinListCellDelegate, SearchListCellDelegate {
    func setDeletedItem(_ index: Int) {
        joinModelList.remove(at: index)
        joinTableView.reloadData()
    }
    
    func addItem(_ index: Int) {
        joinModelList.append(searchModelList[index])
        joinTableView.reloadData()
        
        searchModelList.remove(at: index)
        searchTableView.reloadData()
    }
}
