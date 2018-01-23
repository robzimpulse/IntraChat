//
//  ListUserViewController.swift
//  IntraChat
//
//  Created by Robyarta on 1/8/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import Diff
import UIKit
import RxCocoa
import RxSwift
import RxRealm
import RxDataSources

class ListUserViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var selectedUserCollectionView: UICollectionView!
    @IBOutlet weak var selectedUserCollectionViewHeight: NSLayoutConstraint!
    
    let users = Variable<[User]>([])
    
    let filteredUsers = Variable<[User]>([])
    
    let selectedUsers = Variable<[User]>([])
    
    let sectionedUser = Variable<[MultipleSectionModel]>([])
    
    let disposeBag = DisposeBag()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .didChangeSelectedUser, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        tableView.allowsMultipleSelection = true
        
        tableView.register(
            UINib(nibName: "UserCell", bundle: nil),
            forCellReuseIdentifier: "UserCell"
        )
        
        selectedUserCollectionView.register(
            UINib(nibName: "SelectedUserCell", bundle: nil),
            forCellWithReuseIdentifier: "SelectedUserCell"
        )
        
        User.get(completion: { realmUsers in
            guard let realmUsers = realmUsers else {return}
            
            Observable.changeset(from: realmUsers).bind(onNext: { results, _ in
                guard let user = FirebaseManager.shared.currentUser() else {return}
                self.users.value = results.toArray().filter({ $0.uid != user.uid })
            }).disposed(by: self.disposeBag)
            
            self.searchBar.rx.text.orEmpty
                .throttle(0.3, scheduler: MainScheduler.instance)
                .distinctUntilChanged()
                .map({ return $0 })
                .observeOn(MainScheduler.instance)
                .bind(onNext: { text in
                    guard let user = FirebaseManager.shared.currentUser() else {return}
                    self.filteredUsers.value = text.isBlank ?
                        self.users.value.filter({$0.uid != user.uid}) :
                        self.users.value.filter({$0.uid != user.uid}).filter({
                            $0.name?.contains(text, compareOption: .caseInsensitive) ?? true
                        })
                })
                .disposed(by: self.disposeBag)

        })
        
        searchBar.rx.textDidBeginEditing.bind(onNext: {
            self.searchBar.setShowsCancelButton(true, animated: true)
        }).disposed(by: disposeBag)
        
        searchBar.rx.textDidEndEditing.bind(onNext: {
            self.searchBar.setShowsCancelButton(false, animated: true)
        }).disposed(by: disposeBag)
        
        searchBar.rx.cancelButtonClicked.bind(onNext: {
            self.searchBar.endEditing(true)
        }).disposed(by: disposeBag)

        let datasource = ListUserViewController.datasource()
        
        sectionedUser.asObservable().bind(to: tableView.rx.items(dataSource: datasource)).disposed(by: disposeBag)
        
        selectedUsers.asObservable().bind(
            to: selectedUserCollectionView.rx.items(cellIdentifier: "SelectedUserCell", cellType: SelectedUserCell.self),
            curriedArgument: { row, user, cell in cell.configure(user: user) }
        ).disposed(by: disposeBag)
        
        selectedUsers.asObservable()
            .bind(onNext: {
                self.navigationItem.titleView = self.setTitle(
                    title: "Add Participant",
                    subtitle: " \($0.count) / 256"
                )
                self.navigationItem.rightBarButtonItem?.isEnabled = ($0.count > 0)
                self.selectedUserCollectionViewHeight.constant = ($0.count > 0) ? 80 : 0
                UIView.animate(withDuration: 0.2, animations: { self.view.layoutIfNeeded() })
            })
            .disposed(by: disposeBag)
        
        selectedUserCollectionView.rx
            .modelSelected(User.self)
            .bind(onNext: { user in
                guard let index = self.selectedUsers.value.index(where: { $0.uid == user.uid }) else {return}
                self.selectedUsers.value.remove(at: index)

                guard let rows = self.tableView.indexPathsForSelectedRows else {return}
                guard let userIndex = rows.index(where: {
                    guard let cell = self.tableView.cellForRow(at: $0) as? UserCell else {return false}
                    return user.uid == cell.user?.uid
                }) else {return}
                self.tableView.deselectRow(at: rows[userIndex], animated: false)
            })
            .disposed(by: disposeBag)
        
        tableView.rx
            .modelSelected(SectionItem.self)
            .bind(onNext: { model in
                switch model {
                case .UserSectionItem(user: let user):
                    self.selectedUsers.value.append(user)
                    break
                }
            })
            .disposed(by: disposeBag)

        tableView.rx
            .modelDeselected(SectionItem.self)
            .bind(onNext: { model in
                switch model {
                case .UserSectionItem(user: let user):
                    guard let index = self.selectedUsers.value.index(where: { $0.uid == user.uid }) else {return}
                    self.selectedUsers.value.remove(at: index)
                    break
                }
            })
            .disposed(by: disposeBag)
        
        filteredUsers.asObservable().bind(onNext: { users in
            self.sectionedUser.value = users.sorted(by: {
                guard let name1 = $0.name, let name2 = $1.name else {return false}
                return name1 < name2
            }).categorise({ $0.name?.first ?? Character("") }).map({ key, items in
                return MultipleSectionModel.UserSection(
                    title: String(key),
                    items: items.map({ SectionItem.UserSectionItem(user: $0) })
                )
            })
        }).disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeSelectedUser(_:)), name: .didChangeSelectedUser, object: nil)
    }

    @objc func didChangeSelectedUser(_ notification: NSNotification) {
        guard let users = notification.object as? [User] else {return}
        self.selectedUsers.value = users
    }
    
    private func setTitle(title: String?, subtitle: String?) -> UIView {
        let titleLabel = UILabel(frame: CGRect(x:0, y:-5, width:0, height:0))
        
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.text = title
        titleLabel.sizeToFit()
        
        let subtitleLabel = UILabel(frame: CGRect(x:0, y:18, width:0, height:0))
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textColor = .lightGray
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.text = subtitle
        subtitleLabel.sizeToFit()
        
        let width = max(titleLabel.frame.size.width, subtitleLabel.frame.size.width)
        let titleView = UIView(frame: CGRect(x:0, y:0, width:width, height:30))
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)
        
        let widthDiff = subtitleLabel.frame.size.width - titleLabel.frame.size.width
        let newX = widthDiff / 2
        if widthDiff < 0 { subtitleLabel.frame.origin.x = abs(newX) }
        else { titleLabel.frame.origin.x = newX }
        return titleView
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? RoomInfoViewController {
            destination.users.value = selectedUsers.value
        }
    }
    
}

extension ListUserViewController {
    static func datasource() -> RxTableViewSectionedReloadDataSource<MultipleSectionModel> {
        return RxTableViewSectionedReloadDataSource<MultipleSectionModel>(configureCell: { datasource, table, indexPath, _ in
            switch datasource[indexPath] {
            case .UserSectionItem(user: let user):
                let cell: UserCell = table.dequeueReusableCell(forIndexPath: indexPath)
                cell.configure(user: user)
                return cell
            }
        }, titleForHeaderInSection: { datasource, indexPath in
            return datasource[indexPath].title
        })
    }
}

