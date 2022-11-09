//
//  JoinListCell.swift
//  carewell
//
//  Created by 유영문 on 2022/06/03.
//

import UIKit

protocol JoinListCellDelegate {
    func setDeletedItem(_ index: Int)
}

class JoinListCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var deleteButton: UIButton!
    
    var delegate: JoinListCellDelegate?
    
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
    
    @IBAction func onTouchDelete(_ sender: UIButton) {
        delegate?.setDeletedItem(sender.tag)
    }
}
