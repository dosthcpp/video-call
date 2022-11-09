//
//  MissedListViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/30.
//

import UIKit

class MissedListViewController: BaseViewController {
    
    @IBOutlet var tableView: UITableView!
    
    private var modelList: [MissedModelList] = []
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    // MARK: - function
    func initView() {
        
        var model: [MissedModel] = []
        
        for _ in 0..<2 {
            model.append(MissedModel("대상자", "오후 3:32"))
            model.append(MissedModel("보호자", "오후 3:32"))
        }
        
        modelList.append(MissedModelList(date: "2022-03-23", data: model))
        modelList.append(MissedModelList(date: "2022-03-22", data: model))
        
        tableView.reloadData()
    }
}

// MARK: - Extension UITableViewDelegate, UITableViewDataSource
extension MissedListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 15))
        headerView.backgroundColor = .clear
        
        let headerLabel = UILabel(frame: headerView.bounds)
        headerLabel.text = "\(modelList[section].date)"
        headerLabel.font = .systemFont(ofSize: 14)
        headerLabel.textColor = #colorLiteral(red: 0.6549019608, green: 0.6549019608, blue: 0.6549019608, alpha: 1)
        headerLabel.textAlignment = .left
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerLabel)
        headerLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20).isActive = true
        
        return headerView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return modelList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelList[section].data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MissedListCell", for: indexPath) as! MissedListCell
        cell.model = modelList[indexPath.section].data[indexPath.row]
        
        return cell
    }
}
