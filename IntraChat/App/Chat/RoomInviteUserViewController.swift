//
//  RoomInviteUserViewController.swift
//  IntraChat
//
//  Created by Robyarta Haruli Ruci on 26/01/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxRealm
import RxDataSources

class RoomInviteUserViewController: UIViewController {
  
  typealias cell1 = UserCell
  
  typealias cell2 = SelectedUserCell
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchBar: UISearchBar!
  @IBOutlet weak var selectedUserCollectionView: UICollectionView!
  @IBOutlet weak var selectedUserCollectionViewHeight: NSLayoutConstraint!
  
  var room: Room?
  
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
    
    tableView.sectionIndexColor = UIColor.black
    
    tableView.register(cell1.nib(), forCellReuseIdentifier: cell1.identifier())
    
    selectedUserCollectionView.register(cell2.nib(), forCellWithReuseIdentifier: cell2.identifier())
    
    User.get(completion: { [unowned self] users in
      guard let users = users else {return}
      guard let room = self.room else {return}
      guard let user = FirebaseManager.shared.currentUser() else {return}
      
      Observable
        .changeset(from: users.filter("NOT uid IN %@", room.users))
        .bind(onNext: { results, _ in
          self.users.value = results.toArray().filter({ $0.uid != user.uid })
        })
        .disposed(by: self.disposeBag)
      
      self.searchBar.rx.text.orEmpty
        .throttle(0.3, scheduler: MainScheduler.instance)
        .distinctUntilChanged()
        .map({ return $0 })
        .observeOn(MainScheduler.instance)
        .bind(onNext: { text in
          self.filteredUsers.value = text.isBlank ?
            self.users.value.filter({$0.uid != user.uid}) :
            self.users.value.filter({$0.uid != user.uid}).filter({
              $0.name?.contains(text, compareOption: .caseInsensitive) ?? true
            })
        })
        .disposed(by: self.disposeBag)
      
    })
    
    searchBar.rx.textDidBeginEditing.bind(onNext: { [weak self] in
      guard let strongSelf = self else {return}
      strongSelf.searchBar.setShowsCancelButton(true, animated: true)
    }).disposed(by: disposeBag)
    
    searchBar.rx.textDidEndEditing.bind(onNext: { [weak self]  in
      guard let strongSelf = self else {return}
      strongSelf.searchBar.setShowsCancelButton(false, animated: true)
    }).disposed(by: disposeBag)
    
    searchBar.rx.cancelButtonClicked.bind(onNext: { [weak self]  in
      guard let strongSelf = self else {return}
      strongSelf.searchBar.endEditing(true)
    }).disposed(by: disposeBag)
    
    sectionedUser.asObservable().bind(to: tableView.rx.items(dataSource: datasource())).disposed(by: disposeBag)
    
    selectedUsers.asObservable().bind(
      to: selectedUserCollectionView.rx.items(cellIdentifier: cell2.identifier(), cellType: cell2.self),
      curriedArgument: { row, user, cell in cell.configure(user: user) }
      ).disposed(by: disposeBag)
    
    selectedUsers.asObservable()
      .bind(onNext: { [weak self] in
        guard let strongSelf = self else {return}
        strongSelf.navigationItem.titleView = Helper.getTitleView(title: "Add Participant", subtitle: " \($0.count) / 256")
        strongSelf.navigationItem.rightBarButtonItem?.isEnabled = ($0.count > 0)
        strongSelf.selectedUserCollectionViewHeight.constant = ($0.count > 0) ? 80 : 0
        UIView.animate(withDuration: 0.2, animations: { strongSelf.view.layoutIfNeeded() })
      })
      .disposed(by: disposeBag)
    
    selectedUserCollectionView.rx
      .modelSelected(User.self)
      .bind(onNext: { [weak self] user in
        guard let strongSelf = self else {return}
        guard let index = strongSelf.selectedUsers.value.index(where: { $0.uid == user.uid }) else {return}
        strongSelf.selectedUsers.value.remove(at: index)
        
        guard let rows = strongSelf.tableView.indexPathsForSelectedRows else {return}
        guard let userIndex = rows.index(where: {
          guard let cell = strongSelf.tableView.cellForRow(at: $0) as? UserCell else {return false}
          return user.uid == cell.user?.uid
        }) else {return}
        strongSelf.tableView.deselectRow(at: rows[userIndex], animated: false)
      })
      .disposed(by: disposeBag)
    
    tableView.rx
      .modelSelected(SectionItem.self)
      .bind(onNext: { [weak self] model in
        guard let strongSelf = self else {return}
        switch model {
        case .UserSectionItem(user: let user):
          guard !strongSelf.selectedUsers.value.contains(where: {$0.uid == user.uid}) else {return}
          strongSelf.selectedUsers.value.append(user)
          break
        }
      })
      .disposed(by: disposeBag)
    
    tableView.rx
      .modelDeselected(SectionItem.self)
      .bind(onNext: { [weak self] model in
        guard let strongSelf = self else {return}
        switch model {
        case .UserSectionItem(user: let user):
          guard let index = strongSelf.selectedUsers.value.index(where: { $0.uid == user.uid }) else {return}
          strongSelf.selectedUsers.value.remove(at: index)
          break
        }
      })
      .disposed(by: disposeBag)
    
    filteredUsers.asObservable().bind(onNext: { [weak self] users in
      guard let strongSelf = self else {return}
      strongSelf.sectionedUser.value = users.sorted(by: {
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
  
  @IBAction func invite(_ sender: Any) {
    guard let room = room else {return}
    FirebaseManager.shared.invite(user: selectedUsers.value, to: room, completion: { [weak self] _ in
      guard let strongSelf = self else {return}
      strongSelf.popVC()
    })
  }
  
  @objc func didChangeSelectedUser(_ notification: NSNotification) {
    guard let users = notification.object as? [User] else {return}
    selectedUsers.value.difference(users).forEach({ [weak self] user in
      guard let strongSelf = self else {return}
      guard let rows = tableView.indexPathsForSelectedRows else {return}
      guard let userIndex = rows.index(where: {
        guard let cell = strongSelf.tableView.cellForRow(at: $0) as? UserCell else {return false}
        return user.uid == cell.user?.uid
      }) else {return}
      strongSelf.tableView.deselectRow(at: rows[userIndex], animated: false)
    })
    selectedUsers.value = users
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? RoomInfoViewController {
      destination.users.value = selectedUsers.value
    }
  }
  
}

extension RoomInviteUserViewController {
  func datasource() -> RxTableViewSectionedReloadDataSource<MultipleSectionModel> {
    return RxTableViewSectionedReloadDataSource<MultipleSectionModel>(configureCell: { [weak self] datasource, table, indexPath, _ in
      guard let strongSelf = self else {return UITableViewCell.init(style: .default, reuseIdentifier: "cell")}
      switch datasource[indexPath] {
      case .UserSectionItem(user: let user):
        let cell: UserCell = table.dequeueReusableCell(forIndexPath: indexPath)
        cell.configure(user: user)
        cell.setSelected(strongSelf.selectedUsers.value.contains(where: { $0.uid == user.uid }), animated: false)
        return cell
      }
    }, titleForHeaderInSection: { datasource, indexPath in
      return datasource[indexPath].title
    }, sectionIndexTitles: { datasource in
      return datasource.sectionModels.map { $0.title }
    })
  }
}
