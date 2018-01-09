//
//  CreateUserNavigationViewController.swift
//  IntraChat
//
//  Created by admin on 9/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit

class CreateUserNavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.shadowImage = UIImage()
        navigationBar.setBackgroundImage(UIImage(), for: .default)
    }
    
}
