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
    
    var selectedRoomId: String?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        tableView.register(
            UINib(nibName: "RoomCell", bundle: nil),
            forCellReuseIdentifier: "RoomCell"
        )

        tableView.rx.modelSelected(Room.self).bind(onNext: { room in
            self.selectedRoomId = room.id
            self.performSegue(withIdentifier: "chat", sender: self)
        }).disposed(by: disposeBag)
        
        FirebaseManager.shared.rooms.asObservable().bind(
            to: tableView.rx.items(cellIdentifier: "RoomCell", cellType: RoomCell.self),
            curriedArgument: { row, room, cell in cell.configure(room: room) }
        ).disposed(by: disposeBag)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? RoomChatViewController {
            destination.roomId = selectedRoomId
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Auth.auth().currentUser == nil {
            performSegue(withIdentifier: "auth", sender: self)
        }
    }
    
    @IBAction func createRoom(_ sender: Any){
//        let room = Room()
//        room.name = "testing"
//        room.icon = "https://lorempixel.com/200/200"
//        manager.create(room: room)
    }
    
}
