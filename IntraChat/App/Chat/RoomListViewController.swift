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
  
  typealias cell = RoomCell
  
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
    
    tableView.register(cell.nib(), forCellReuseIdentifier: cell.identifier())
    
    tableView.rx.modelSelected(Room.self).bind(onNext: { [weak self]  room in
      guard let strongSelf = self else {return}
      strongSelf.selectedRoom = room
      strongSelf.performSegue(withIdentifier: "chat", sender: strongSelf)
    }).disposed(by: disposeBag)
    
    tableView.rx.willBeginDragging.bind { [weak self] in
      guard let strongSelf = self else {return}
      strongSelf.isScrolled = true
    }.disposed(by: disposeBag)
    
    tableView.rx.didEndDragging.bind { [weak self] in
      guard let strongSelf = self else {return}
      strongSelf.isScrolled = !$0
    }.disposed(by: disposeBag)
    
    tableView.rx.didEndScrollingAnimation.bind { [weak self] in
      guard let strongSelf = self else {return}
      strongSelf.isScrolled = false
    }.disposed(by: disposeBag)
    
    timer = Timer.runThisEvery(seconds: 1.0, handler: { [weak self] _ in
      guard let strongSelf = self else {return}
      if !strongSelf.isScrolled { strongSelf.tableView.reloadData() }
    })
    
    authListener = Auth.auth().addStateDidChangeListener({ [weak self] _, user in
      guard let strongSelf = self else {return}
      if user == nil { strongSelf.performSegue(withIdentifier: "auth", sender: self) }
    })
    
    Room.get(completion: { [weak self] rooms in
      guard let strongSelf = self else {return}
      guard let rooms = rooms else {return}
      guard let currentUser = FirebaseManager.shared.currentUser() else {return}
      Observable
        .collection(from: rooms.filter("_users CONTAINS '\(currentUser.uid)'").toAnyCollection())
        .bind(
          to: strongSelf.tableView.rx.items(cellIdentifier: "RoomCell", cellType: RoomCell.self),
          curriedArgument: { row, room, cell in cell.configure(room: room)}
        )
        .disposed(by: strongSelf.disposeBag)
    })    
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? RoomChatViewController { destination.room = selectedRoom }
  }
  
  @IBAction func logout(_ sender: Any){
    FirebaseManager.shared.logout()
  }
  
}
