//
//  AuthSignUpViewController.swift
//  IntraChat
//
//  Created by Robyarta on 1/7/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import Hero
import UIKit
import RxCocoa
import RxSwift
import FirebaseAuth
import EZSwiftExtensions

class AuthSignUpViewController: UIViewController {
  
  @IBOutlet weak var signupContainer: UIView!
  @IBOutlet weak var usernameTextField: UITextField!
  @IBOutlet weak var emailTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var confirmPasswordTextField: UITextField!
  @IBOutlet weak var submitContainer: UIView!
  @IBOutlet weak var submitButton: UIButton!
  
  let disposeBag = DisposeBag()
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    submitButton.rx.tap.bind(onNext: {
      guard let username = self.usernameTextField.text else {return}
      guard let email = self.emailTextField.text else {return}
      guard let password = self.passwordTextField.text else {return}
      guard let confirmPassword = self.confirmPasswordTextField.text else {return}
      guard password == confirmPassword else {return}
      self.submitButton.isEnabled = false
      Auth.auth().createUser(withEmail: email, password: password, completion: { user, error in
        guard let user = user else {
          print(error as Any)
          self.submitButton.isEnabled = true
          return
        }
        let request = user.createProfileChangeRequest()
        request.displayName = username
        request.commitChanges(completion: { error in
          FirebaseManager.shared.userRef.child(user.uid).updateChildValues(User(user: user).keyValue() ?? [:])
          self.navigationController?.dismissVC(completion: nil)
          print(error as Any)
        })
      })
    }).disposed(by: disposeBag)
  }
  
  override func viewDidLayoutSubviews() {
    signupContainer.roundCorners(.allCorners, radius: 6.0)
    submitContainer.roundCorners(.allCorners, radius: 6.0)
    submitButton.roundCorners(.allCorners, radius: 6.0)
  }
  
}
