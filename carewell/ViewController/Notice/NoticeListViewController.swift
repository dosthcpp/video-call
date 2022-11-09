//
//  NoticeListViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/30.
//

import UIKit

class NoticeListViewController: BaseViewController {
    
    @IBOutlet var tableView: UITableView!
    
    fileprivate let SHOW_NOTICE_DETAIL_PAGE = "show_notice_detail_page"
    private var modelList: [NoticeModel] = []
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    // MARK: - function
    func initView() {
        modelList.append(NoticeModel("2022-03-23", "사회적 거리두기 큰 폭 조정 없이 사적모임 인원 6인→8인으로 소폭 조정", "Test", "김복지", false, true))
        modelList.append(NoticeModel("2022-03-23", "사회적 거리두기 큰 폭 조정 없이 사적모임 인원 6인→8인으로 소폭 조정", "Test", "김복지", true, true))
        
        for _ in 0..<6 {
            modelList.append(NoticeModel("2022-03-22", "사회적 거리두기 큰 폭 조정 없이 사적모임 인원 6인→8인으로 소폭 조정", "Test", "김복지", true, false))
        }
        
        tableView.reloadData()
    }
}

// MARK: - Extension UITableViewDelegate, UITableViewDataSource
extension NoticeListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 118.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoticeListCell", for: indexPath) as! NoticeListCell
        cell.model = modelList[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = modelList[indexPath.row]
        self.nextPrepareData = [DATA : data]
        performSegue(withIdentifier: SHOW_NOTICE_DETAIL_PAGE, sender: nil)
    }
}
