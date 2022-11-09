//
//  CalleeDialog.swift
//  carewell
//
//  Created by DOYEON BAEK on 2022/10/27.
//

import Foundation
import UIKit

class CalleeDialog: UIView {

    @IBOutlet var buttons: UIStackView!
    @IBOutlet var mTitle: UILabel!
    @IBOutlet var mMessage: UILabel!

    @IBOutlet var mLeft: UIButton!
    @IBOutlet var mRight: UIButton!

    @IBAction func onClickAccept(_ sender: Any) {
        // click left
        if let mDialogType {
            if mDialogType != DialogType.CONFIRM_ONLY {
                if let mCallbacks, mCallbacks.count > 0 {
                    for callback in mCallbacks {
                        callback.onClicked(id: ButtonType.BTN_RIGHT.ordinal())
                    }
                } else {
                    if let mCallback {
                        mCallback.onClicked(id: ButtonType.BTN_RIGHT.ordinal())
                    }
                }
            }
        }
    }

    @IBAction func onClickReject(_ sender: Any) {
        // click right
        if let mDialogType {
            if mDialogType != DialogType.CANCEL_ONLY {
                if let mCallbacks, mCallbacks.count > 0 {
                    for callback in mCallbacks {
                        callback.onClicked(id: ButtonType.BTN_LEFT.ordinal())
                    }
                } else {
                    if let mCallback {
                        mCallback.onClicked(id: ButtonType.BTN_LEFT.ordinal())
                    }
                }
            }
        }
    }

    private var mCallbacks: [MessageDialogCallback]?
    private var mCallback: MessageDialogCallback?
    private var mDialogType: DialogType?

    private var extra1: String?
    private var extra2: String?
    private var mTitleMsg: String?, mDesc: String?

    required init?(coder aCoder: NSCoder) {
        super.init(coder: aCoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    private static var USE_MULTI_CALLBACK = false

    func initView(use_multi_callback: Bool, type: DialogType, title: String, message: String) {
        CalleeDialog.USE_MULTI_CALLBACK = use_multi_callback
        if CalleeDialog.USE_MULTI_CALLBACK {
            mCallbacks = [MessageDialogCallback]()
        }

        mDialogType = type
        mTitleMsg = title
        mDesc = message

        mTitle.text = mTitleMsg
        mMessage.text = mDesc

        if let mDialogType {
            if mDialogType == DialogType.CONFIRM_ONLY {
                buttons.removeArrangedSubview(mLeft)
                mLeft.removeFromSuperview()
            } else if mDialogType == DialogType.CANCEL_ONLY {
                buttons.removeArrangedSubview(mRight)
                mRight.removeFromSuperview()
            }
        }
    }

    public func setExtra1(extra1: String, extra2: String) {
        self.extra1 = extra1
        self.extra2 = extra2
    }

    public func setTitle(title: String) {
        if let mTitle {
            mTitle.text = title
        }
    }

    public func setRightButtonText(text: String) {
        if let mRight {
            mRight.setTitle(text, for: .normal)
        }
    }

    public func setLeftButtonText(text: String) {
        if let mLeft {
            mLeft.setTitle(text, for: .normal)
        }
    }

    public func setMessage(text: String) {
        if let mMessage {
            mMessage.text = text
        }
    }

    public func release() {
        if self != nil {
            self.removeFromSuperview()
        }

        if let mCallbacks {
            for callback in mCallbacks {
                callback.onDismiss()
            }
        } else {
            if let mCallback {
                mCallback.onDismiss()
            }
        }
    }

    public func getType() -> DialogType? {
        return mDialogType
    }

    public func isShowing() -> Bool {
        return self != nil
    }

    public func addCallback(callback: MessageDialogCallback) {
//        if CalleeDialog.USE_MULTI_CALLBACK {
//            if var mCallbacks {
//                for i in 0...mCallbacks.count {
//                    if mCallbacks[i] === callback {
//                        return
//                    }
//                }
//                mCallbacks.append(callback)
//            }
//        } else {
//            print("add callback!!")
//            mCallback = callback
//        }
        // USE_MULTI_CALLBACK => 필요없는 parameter인데 괜히 true로 되어서 전화 여러번 거절이 안됨
        print("add callback!!")
        mCallback = callback
    }

    public func removeCallback() {
        if CalleeDialog.USE_MULTI_CALLBACK {
            if var mCallbacks {
                mCallbacks.removeAll()
            }
        } else {
            mCallback = nil
        }
    }
}
