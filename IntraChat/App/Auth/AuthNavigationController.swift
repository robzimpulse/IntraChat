//
//  AuthNavigationController.swift
//  IntraChat
//
//  Created by Robyarta Ruci on 1/13/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import Hero

class AuthNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isHeroEnabled = true
        heroNavigationAnimationType = .fade
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        heroModalAnimationType = .cover(direction: .up)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        heroModalAnimationType = .cover(direction: .down)
    }
    
}
