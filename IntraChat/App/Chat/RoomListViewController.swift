//
//  RoomListViewController.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseAuth
import FirebaseDatabase

class RoomListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let disposeBag = DisposeBag()
    
    var selectedRoom: Room?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        tableView.register(
            UINib(nibName: "RoomCell", bundle: nil),
            forCellReuseIdentifier: "RoomCell"
        )

        tableView.rx.modelSelected(Room.self).bind(onNext: { room in
            self.selectedRoom = room
            self.performSegue(withIdentifier: "chat", sender: self)
        }).disposed(by: disposeBag)
        
        FirebaseManager.shared.rooms.asObservable().bind(
            to: tableView.rx.items(cellIdentifier: "RoomCell", cellType: RoomCell.self),
            curriedArgument: { row, room, cell in cell.configure(room: room) }
        ).disposed(by: disposeBag)
        
        if let user = FirebaseManager.shared.currentUser() {
            FirebaseManager.shared.userForRoom.value = User(user: user)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? RoomChatViewController {
            destination.room = selectedRoom
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Auth.auth().currentUser == nil {
            performSegue(withIdentifier: "auth", sender: self)
        }
    }
    
}
