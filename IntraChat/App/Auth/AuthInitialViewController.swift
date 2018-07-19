//
//  AuthInitialViewController.swift
//  IntraChat
//
//  Created by Robyarta on 1/7/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import EZSwiftExtensions

class AuthInitialViewController: UIViewController {
    
    @IBOutlet weak var signinContainer: UIView!
    @IBOutlet weak var signinButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        signinContainer.roundCorners(.allCorners, radius: 6.0)
        signinButton.roundCorners(.allCorners, radius: 6.0)
    }
    
}
