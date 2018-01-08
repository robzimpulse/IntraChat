//
//  ListUserViewController.swift
//  IntraChat
//
//  Created by Robyarta on 1/8/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ListUserViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let users = Variable<[User]>([])
    
    let disposeBag = DisposeBag()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        tableView.register(
            UINib(nibName: "UserCell", bundle: nil),
            forCellReuseIdentifier: "UserCell"
        )
        
        FirebaseManager.shared.users.asObservable().bind(
            to: tableView.rx.items(cellIdentifier: "UserCell", cellType: UserCell.self),
            curriedArgument: { row, user, cell in cell.configure(user: user) }
        ).disposed(by: disposeBag)
        
    }

}
