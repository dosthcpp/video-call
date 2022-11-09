//
//  MainTabbarController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/27.
//

import UIKit

class MainTabbarController: UITabBarController {
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.selectedViewController = viewControllers![selectedIndex]
        if let selectedViewController = selectedViewController as? UINavigationController {
            selectedViewController.popToRootViewController(animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //custom tabbaritem
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.4392156863, green: 0.4392156863, blue: 0.4392156863, alpha: 1), NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12, weight: .regular)], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1), NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12, weight: .medium)], for: .selected)
    }
}

// MARK: - Extension UITabBarControllerDelegate
extension MainTabbarController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let controllers = (viewController as! UINavigationController).viewControllers
//        if #available(iOS 13.0, *), controllers[0] is AlbumListViewController {
//            let albumListViewController = controllers[0] as! AlbumListViewController
//            if albumListViewController.isFinishRender {
//                albumListViewController.initData()
//            }
//        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // did selected tab
        return true
    }
}
