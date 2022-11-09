//
//  NoticeViewController.swift
//  carewell
//
//  Created by 유영문 on 2022/05/30.
//

import UIKit

class NoticeViewController: BaseViewController {
    
    @IBOutlet var tabLabel1: UILabel!
    @IBOutlet var tabLabel2: UILabel!
    @IBOutlet var tabIndicator1: UIView!
    @IBOutlet var tabIndicator2: UIView!
    
    fileprivate let SHOW_PAGE_VIEW = "show_page_view"
    var pageVC: UIPageViewController?
    var vcArray: Array<UIViewController> = []
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case SHOW_PAGE_VIEW:
            if let vc = segue.destination as? UIPageViewController {
                pageVC = vc
                pageVC?.delegate = self
                pageVC?.dataSource = self
            }
        default:
            break
        }
        super.prepare(for: segue, sender: sender)
    }
    
    // MARK: - IBAction
    @IBAction func onTouchButton(_ sender: UIButton) {
        guard preventButtonClick, let tag = sender.viewTag else { return }
        
        switch tag {
        case .notice_back_button:
            self.navigationController?.dismiss(animated: true)
            
        case .notice_tab1_button:
            pageVC?.setViewControllers([vcArray[0]], direction: .reverse, animated: true, completion: nil)
            updateTabView(index: 0)
            
        case .notice_tab2_button:
            pageVC?.setViewControllers([vcArray[1]], direction: .forward, animated: true, completion: nil)
            updateTabView(index: 1)
            
        default:
            break
        }
    }
    
    // MARK: - function
    func initView() {
        initPageVC()
    }
    // MARK: - PageViewController
    func initPageVC() {
        let sb = UIStoryboard(name: "Notice", bundle: nil)
        
        if let missedListVC = sb.instantiateViewController(withIdentifier: "missed_list") as? MissedListViewController,
           let noticeListVC = sb.instantiateViewController(withIdentifier: "notice_list") as? NoticeListViewController {
            
            vcArray.append(missedListVC)
            vcArray.append(noticeListVC)
            
            pageVC?.setViewControllers([vcArray[0]], direction: .forward, animated: true, completion: nil)
        }
    }
    
    func updateTabView(index: Int) {
        tabLabel1.textColor = index == 0 ? #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1) : #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1)
        tabLabel2.textColor = index == 1 ? #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1) : #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1)
        
        tabIndicator1.backgroundColor = index == 0 ? #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1) : #colorLiteral(red: 0.7254901961, green: 0.7254901961, blue: 0.7254901961, alpha: 1)
        tabIndicator2.backgroundColor = index == 1 ? #colorLiteral(red: 0.9411764706, green: 0.2431372549, blue: 0, alpha: 1) : #colorLiteral(red: 0.7254901961, green: 0.7254901961, blue: 0.7254901961, alpha: 1)
    }
    
    // pageSildeVC
    func pageSlideCurrentVC(_ currentPageVC: UIViewController) {
        switch currentPageVC {
        case vcArray[0]:
            updateTabView(index: 0)
            
        case vcArray[1]:
            updateTabView(index: 1)
            
        default:
            break
        }
    }
}

// MARK: - Extension UIPageViewControllerDelegate, UIPageViewControllerDataSource
extension NoticeViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let curIndex = vcArray.firstIndex(of: viewController) else { return nil }
        
        let prePageIndex = curIndex - 1
        if prePageIndex < 0 {
            return nil
        } else {
            return vcArray[prePageIndex]
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let curIndex = vcArray.firstIndex(of: viewController) else { return nil }
        
        let prePageIndex = curIndex + 1
        if prePageIndex >= vcArray.count {
            return nil
        } else {
            return vcArray[prePageIndex]
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let currentPageVC: UIViewController = pageViewController.viewControllers?[0] else { return }
        pageSlideCurrentVC(currentPageVC)
    }
}
