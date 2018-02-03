//
//  NavigationController.swift
//  IntraChat
//
//  Created by admin on 9/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import IQKeyboardManager

class NavigationController: UINavigationController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.delegate = self
    self.interactivePopGestureRecognizer?.delegate = self
  }
  
  func theme(VC: UIViewController){
    navigationBar.shadowImage = UIImage()
    navigationBar.setBackgroundImage(UIImage(), for: .default)
    
    let keyboard = !(VC is RoomChatViewController)
    IQKeyboardManager.shared().isEnabled = keyboard
  }
  
}

extension NavigationController: UINavigationControllerDelegate {
  func navigationController(
    _ navigationController: UINavigationController,
    willShow viewController: UIViewController,
    animated: Bool
  ) {
    theme(VC: viewController)
    if let coordinator = navigationController.topViewController?.transitionCoordinator {
      coordinator.notifyWhenInteractionEnds({ [weak self] (context) in
        guard let strongSelf = self else {return}
        guard context.isCancelled else {return}
        guard let VC = context.viewController(forKey: .from) else {return}
        strongSelf.theme(VC: VC)
      })
    }
  }
}
