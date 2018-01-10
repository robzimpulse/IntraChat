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
import RxRealm
import RealmSwift
import FirebaseAuth
import FirebaseDatabase

class RoomListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let disposeBag = DisposeBag()
    
    var selectedRoom: Room?
    
    var isScrolled = false
    
    var timer: Timer?
    
    var authListener: AuthStateDidChangeListenerHandle?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    deinit {
        timer?.invalidate()
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
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
        
        tableView.rx.willBeginDragging.bind { self.isScrolled = true }.disposed(by: disposeBag)
        
        tableView.rx.didEndDragging.bind { self.isScrolled = !$0 }.disposed(by: disposeBag)
        
        tableView.rx.didEndScrollingAnimation.bind { self.isScrolled = false }.disposed(by: disposeBag)
        
//        FirebaseManager.shared.rooms.asObservable().bind(
//            to: tableView.rx.items(cellIdentifier: "RoomCell", cellType: RoomCell.self),
//            curriedArgument: { row, room, cell in cell.configure(room: room) }
//        ).disposed(by: disposeBag)
        
        timer = Timer.runThisEvery(seconds: 1.0, handler: { _ in
            if !self.isScrolled { self.tableView.reloadData() }
        })
     
        authListener = Auth.auth().addStateDidChangeListener({ _, user in
            if let user = user {
                FirebaseManager.shared.userForRoom.value = User(user: user)
            } else {
                FirebaseManager.shared.userForRoom.value = nil
                self.performSegue(withIdentifier: "auth", sender: self)
            }
        })
        
        Realm.asyncOpen(callback: { realm, _ in
            guard let realm = realm else {return}
            
            Observable.collection(from: realm.objects(Room.self).toAnyCollection()).bind(
                to: self.tableView.rx.items(cellIdentifier: "RoomCell", cellType: RoomCell.self),
                curriedArgument: { row, room, cell in cell.configure(room: room)}
            ).disposed(by: self.disposeBag)
            
            
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? RoomChatViewController {
            destination.room = selectedRoom
        }
    }
    
    @IBAction func logout(_ sender: Any){
        FirebaseManager.shared.logout()
    }
    
}
