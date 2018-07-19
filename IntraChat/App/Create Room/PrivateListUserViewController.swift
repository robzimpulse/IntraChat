//
//  PrivateListUserViewController.swift
//  IntraChat
//
//  Created by Robyarta on 1/8/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxRealm
import RxDataSources

class PrivateListUserViewController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    typealias cell = UserCell
    
    @IBOutlet weak var tableView: UITableView!
    
    let disposeBag = DisposeBag()
    
    let sectionedUser = Variable<[MultipleSectionModel]>([])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.allowsMultipleSelection = false
        tableView.sectionIndexColor = UIColor.black
        tableView.register(cell.nib(), forCellReuseIdentifier: cell.identifier())
        
        sectionedUser.asObservable()
            .bind(to: tableView.rx.items(dataSource: datasource()))
            .disposed(by: disposeBag)
        
        User.get(completion: { [weak self] users in
            guard let ws = self else {return}
            guard let users = users else {return}
            guard let currentUser = FirebaseManager.shared.currentUser() else {return}
            
            Observable.arrayWithChangeset(from: users)
                .map({ $0.0.filter({ $0.uid != currentUser.uid }) })
                .map({ $0.sorted(by: {
                        guard let name1 = $0.name else {return false}
                        guard let name2 = $1.name else {return false}
                        return name1 < name2
                    })
                })
                .map({ $0.categorise({ $0.name?.first ?? Character("") }) })
                .map({ $0.map({
                        MultipleSectionModel.UserSection(
                            title: String($0),
                            items: $1.map({ SectionItem.UserSectionItem(user:  $0) })
                        )
                    })
                })
                .bind(to: ws.sectionedUser)
                .disposed(by: ws.disposeBag)
        })
        
    }
    
}

extension PrivateListUserViewController {
    func datasource() -> RxTableViewSectionedReloadDataSource<MultipleSectionModel> {
        return RxTableViewSectionedReloadDataSource<MultipleSectionModel>(
            configureCell: { datasource, table, indexPath, _ in
                switch datasource[indexPath] {
                case .UserSectionItem(user: let user):
                    let cell: cell = table.dequeueReusableCell(forIndexPath: indexPath)
                    cell.configure(user: user)
                    return cell
                }
            }, titleForHeaderInSection: { datasource, indexPath in
                return datasource[indexPath].title
            }, sectionIndexTitles: { datasource in
                return datasource.sectionModels.map { $0.title }
            }
        )
    }
}
