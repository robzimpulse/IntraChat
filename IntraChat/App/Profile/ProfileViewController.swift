//
//  SettingViewController.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import Eureka
import ViewRow

class ProfileViewController: FormViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    struct formIndex {
        static let email = "email"
        static let image = "image"
        static let name = "name"
        static let phone = "phone"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form
            
            +++ Section()
            <<< ViewRow<UIImageView>(){ row in
                row.tag = formIndex.image
                row.cellSetup { cell, _ in
                    cell.view = self.profileImageView
                    cell.contentView.addSubview(cell.view!)
                    cell.viewRightMargin = 0.0
                    cell.viewLeftMargin = 0.0
                    cell.viewTopMargin = 0.0
                    cell.viewBottomMargin = 0.0
                    cell.height = { return CGFloat(150) }
                    cell.separatorInset.left = 0
                }
                
            }
            
            +++ Section("Email")
            <<< PhoneRow() { row in
                row.tag = formIndex.email
                row.disabled = true
                row.cellUpdate({ cell, _ in
                    row.value = FirebaseManager.shared.currentUser()?.email
                })
            }
            
            +++ Section("Display Name")
            <<< NameRow() { row in
                row.tag = formIndex.name
                row.onCellHighlightChanged({ cell, _ in
                    guard !row.isHighlighted else {return}
                    guard let value = row.value else {return}
                    FirebaseManager.shared.change(name: value)
                })
                row.cellUpdate({ cell, _ in
                    row.value = FirebaseManager.shared.currentUser()?.displayName
                })
            }
            
            +++ Section("Phone Number")
            <<< PhoneRow() { row in
                row.tag = formIndex.phone
                row.disabled = true
                row.cellUpdate({ cell, _ in
                    row.value = FirebaseManager.shared.currentUser()?.phoneNumber
                })
            }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        form.allRows.forEach({ $0.reload() })
        if let url = FirebaseManager.shared.currentUser()?.photoURL {
            profileImageView.setImage(url: url )
        }
    }

}
