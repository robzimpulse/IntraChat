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
    if let listener = authListener {  Auth.auth().removeStateDidChangeListener(listener) }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.tableFooterView = UIView()
    
    tableView.register(
      UINib(nibName: "RoomCell", bundle: nil),
      forCellReuseIdentifier: "RoomCell"
    )
    
    tableView.rx.modelSelected(Room.self).bind(onNext: { [unowned self]  room in
      self.selectedRoom = room
      self.performSegue(withIdentifier: "chat", sender: self)
    }).disposed(by: disposeBag)
    
    tableView.rx.willBeginDragging.bind { [unowned self] in self.isScrolled = true }.disposed(by: disposeBag)
    
    tableView.rx.didEndDragging.bind { [unowned self] in self.isScrolled = !$0 }.disposed(by: disposeBag)
    
    tableView.rx.didEndScrollingAnimation.bind { [unowned self] in self.isScrolled = false }.disposed(by: disposeBag)
    
    timer = Timer.runThisEvery(seconds: 1.0, handler: { [unowned self] _ in
      if !self.isScrolled { self.tableView.reloadData() }
    })
    
    authListener = Auth.auth().addStateDidChangeListener({ [unowned self] _, user in
      if user == nil { self.performSegue(withIdentifier: "auth", sender: self) }
    })
    
    Room.get(completion: { [unowned self] rooms in
      guard let rooms = rooms else {return}
      guard let currentUser = FirebaseManager.shared.currentUser() else {return}
      Observable
        .collection(from: rooms.filter("_users CONTAINS '\(currentUser.uid)'").toAnyCollection())
        .bind(
          to: self.tableView.rx.items(cellIdentifier: "RoomCell", cellType: RoomCell.self),
          curriedArgument: { row, room, cell in cell.configure(room: room)}
        )
        .disposed(by:self.disposeBag)
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
