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
    @IBOutlet weak var searchBar: UISearchBar!
    
    let users = Variable<[User]>([])
    
    let disposeBag = DisposeBag()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        tableView.allowsMultipleSelection = true
        
        tableView.register(
            UINib(nibName: "UserCell", bundle: nil),
            forCellReuseIdentifier: "UserCell"
        )
        
        searchBar.rx.text.orEmpty
            .throttle(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .map({ return $0 })
            .observeOn(MainScheduler.instance)
            .bind(onNext: { text in
                guard let user = FirebaseManager.shared.currentUser() else {return}
                print(user)
//                self.users.value = text.isBlank ?
//                    FirebaseManager.shared.users.value.filter({$0.uid != user.uid}) :
//                    FirebaseManager.shared.users.value.filter({$0.uid != user.uid}).filter({
//                    $0.name?.contains(text, compareOption: .caseInsensitive) ?? true
//                })
            })
            .disposed(by: disposeBag)
        
        searchBar.rx.textDidBeginEditing.bind(onNext: {
            self.searchBar.setShowsCancelButton(true, animated: true)
        }).disposed(by: disposeBag)
        
        searchBar.rx.textDidEndEditing.bind(onNext: {
            self.searchBar.setShowsCancelButton(false, animated: true)
        }).disposed(by: disposeBag)
        
        searchBar.rx.cancelButtonClicked.bind(onNext: {
            self.searchBar.endEditing(true)
        }).disposed(by: disposeBag)
        
        users.asObservable().bind(
            to: tableView.rx.items(cellIdentifier: "UserCell", cellType: UserCell.self),
            curriedArgument: { row, user, cell in cell.configure(user: user) }
        ).disposed(by: disposeBag)
        
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? RoomInfoViewController {
            guard let selectedIndex = tableView.indexPathsForSelectedRows else {return}
            destination.users = selectedIndex.flatMap({ (index) -> User? in
                guard let cell = self.tableView.cellForRow(at: index) as? UserCell else {return nil}
                return cell.user
            })
        }
    }
    
}
