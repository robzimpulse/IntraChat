//
//  UIViewController.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import EZSwiftExtensions

extension UIViewController: UIGestureRecognizerDelegate {
    @IBAction func back(_ sender: Any){
        if let nav = self.navigationController {
            if nav.viewControllers.count > 1 {
                nav.popViewController(animated: true)
            }else{
                nav.dismiss(animated: true, completion: nil)
            }
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    func showAlert(title: String, message: String, actions: [UIAlertAction]? = nil, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title,message: message,preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { _ in
            alert.dismissVC(completion: nil)
            completion?()
        }))
        if let actions = actions { actions.forEach({alert.addAction($0)}) }
        self.presentVC(alert)
    }
    func showConfirmDialog(title: String, message: String, handlerOk: @escaping (UIAlertAction) -> Void, handlerCancel: (() -> Void)? = nil){
        let refreshAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: handlerOk))
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            refreshAlert.dismissVC(completion: nil)
            handlerCancel?()
        }))
        self.presentVC(refreshAlert)
    }
    func showActionSheet(title: String?, actions: [UIAlertAction], cancel: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: nil, message: title, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { _ in cancel?() }
        ))
        actions.forEach({ action in alertController.addAction(action) })
        self.presentVC(alertController)
    }
    func topMostViewController() -> UIViewController {
        if self.presentedViewController == nil {
            return self
        }
        if let navigation = self.presentedViewController as? UINavigationController {
            return navigation.visibleViewController!.topMostViewController()
        }
        if let tab = self.presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        return self.presentedViewController!.topMostViewController()
    }
}
