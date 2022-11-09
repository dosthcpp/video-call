//
//  SearchListCell.swift
//  carewell
//
//  Created by 유영문 on 2022/06/07.
//

import UIKit

protocol SearchListCellDelegate {
    func addItem(_ index: Int)
}

class SearchListCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var addButton: UIButton!
    
    var delegate: SearchListCellDelegate?
    
    public var name: String {
        get {
            return nameLabel.text!
        }
        set {
            nameLabel.text = newValue
        }
    }
    private var _model: FriendModel = FriendModel()
    public var model: FriendModel {
        get {
            return _model
        }
        set {
            _model = newValue
            name = _model.name
        }
    }
    
    @IBAction func onTouchAdd(_ sender: UIButton) {
        delegate?.addItem(sender.tag)
    }
}
