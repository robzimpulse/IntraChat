//
//  AuthSignInViewController.swift
//  IntraChat
//
//  Created by Robyarta on 1/7/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import Hero
import UIKit
import RxSwift
import RxCocoa
import FirebaseAuth
import EZSwiftExtensions

class AuthSignInViewController: UIViewController {

    @IBOutlet weak var signinContainer: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var submitContainer: UIView!
    @IBOutlet weak var submitButton: UIButton!
    
    let disposeBag = DisposeBag()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        navigationController?.interactivePopGestureRecognizer?.addTarget(self, action: #selector(self.pan(panGR:)))
        submitButton.rx.tap.bind(onNext: {
            guard let email = self.emailTextField.text else {return}
            guard let password = self.passwordTextField.text else {return}
            self.submitButton.isEnabled = false
            Auth.auth().signIn(withEmail: email, password: password, completion: { user, error in
                guard user != nil else {
                    print(error as Any)
                    self.submitButton.isEnabled = true
                    return
                }
                self.navigationController?.dismissVC(completion: nil)
            })
            
        }).disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        signinContainer.roundCorners(.allCorners, radius: 6.0)
        submitContainer.roundCorners(.allCorners, radius: 6.0)
        submitButton.roundCorners(.allCorners, radius: 6.0)
    }
    
    @objc func pan(panGR: UIPanGestureRecognizer) {
        guard let view = panGR.view else { return }
        let translation = panGR.translation(in: nil)
        let progress = translation.x / 2 / view.bounds.width
        switch panGR.state {
        case .began:
            hero_dismissViewController()
        case .changed:
            Hero.shared.update(progress)
        default:
            if progress + panGR.velocity(in: nil).x / view.bounds.width > 0.3 {
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
        }
    }
    
}
