//
//  FirebaseManager.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Firebase
import FirebaseDatabase
import EZSwiftExtensions

protocol FirebaseModel {
    func keyValue() -> [AnyHashable: Any]?
}

class FirebaseManager: NSObject {
    
    static let shared = FirebaseManager()
    
    let users = Variable<[User]>([])
    
    let rooms = Variable<[Room]>([])
    
    var authListener: AuthStateDidChangeListenerHandle?
    
    lazy var roomRef: DatabaseReference = {
        return Database.database().reference().child("room")
    }()
    
    lazy var memberRef: DatabaseReference = {
        return Database.database().reference().child("member")
    }()
    
    lazy var userRef: DatabaseReference = {
        return Database.database().reference().child("user")
    }()
    
    override init() {
        
        super.init()
        
        FirebaseApp.configure()
        
        authListener = Auth.auth().addStateDidChangeListener({ auth, user in
            if let user = user {
                self.roomRef.observe(.childAdded, with: { snapshot in
                    guard let room = Room(snapshot: snapshot) else {return}
                    self.get(memberWithRoomId: room.id, completion: { members in
                        if members.contains(user.uid) { self.rooms.value.append(room) }
                    })
                })
                
                self.roomRef.observe(.childRemoved, with: { snapshot in
                    guard let room = Room(snapshot: snapshot) else {return}
                    guard let index = self.rooms.value.index(where: { room.id == $0.id }) else {return}
                    self.get(memberWithRoomId: room.id, completion: { members in
                        if members.contains(user.uid) { self.rooms.value.remove(at: index) }
                    })
                })
                
                self.roomRef.observe(.childChanged, with: { snapshot in
                    guard let room = Room(snapshot: snapshot) else {return}
                    guard let index = self.rooms.value.index(where: { room.id == $0.id }) else {return}
                    self.get(memberWithRoomId: room.id, completion: { members in
                        if members.contains(user.uid) { self.rooms.value[index] = room }
                    })
                })
                
                self.userRef.observe(.childAdded, with: { snapshot in
                    guard let user = User(snapshot: snapshot) else {return}
                    self.users.value.append(user)
                })
                
                self.userRef.observe(.childRemoved, with: { snapshot in
                    guard let user = User(snapshot: snapshot) else {return}
                    guard let index = self.users.value.index(where: { user.uid == $0.uid }) else {return}
                    self.users.value.remove(at: index)
                })
                
                self.userRef.observe(.childChanged, with: { snapshot in
                    guard let user = User(snapshot: snapshot) else {return}
                    guard let index = self.users.value.index(where: { user.uid == $0.uid }) else {return}
                    self.users.value[index] = user
                })
                
                let myUser = User()
                myUser.name = user.displayName
                myUser.email = user.email
                myUser.phone = user.phoneNumber
                myUser.photo = user.photoURL?.absoluteString
                
                self.userRef.child(user.uid).onDisconnectUpdateChildValues(["online": false])
                self.userRef.child(user.uid).updateChildValues(myUser.keyValue() ?? [:])
                
            }else{
                self.rooms.value = []
                self.users.value = []
                self.roomRef.removeAllObservers()
                self.userRef.removeAllObservers()
            }
        })
    }
    
    deinit {
        guard let listener = authListener else {return}
        Auth.auth().removeStateDidChangeListener(listener)
    }
    
    func applicationWillResignActive() {
        guard let user = Auth.auth().currentUser else {return}
        userRef.child(user.uid).updateChildValues(["online": false])
    }
    
    func applicationDidBecomeActive() {
        guard let user = Auth.auth().currentUser else {return}
        userRef.child(user.uid).updateChildValues(["online": true])
    }
    
    func applicationWillTerminate() {
        guard let user = Auth.auth().currentUser else {return}
        userRef.child(user.uid).updateChildValues(["online": false])
    }
    
    // MARK: Room
    
    func create(room: Room, completion: ((Error?) -> Void)? = nil){
        roomRef.childByAutoId().setValue(room.keyValue(), withCompletionBlock: { error, ref in
            if let error = error { completion?(error); return}
            self.add(memberWithRoomId: room.id, completion: { completion?($0) })
        })
    }
    
    // MARK: Member
    
    private func add(memberWithRoomId roomId: String, completion: ((Error?) -> Void)? = nil){
        if let user = Auth.auth().currentUser {
            get(memberWithRoomId: roomId, completion: { members in
                if !members.contains(user.uid) {
                    var newMembers = members
                    newMembers.append(user.uid)
                    self.memberRef.child(roomId).setValue(["users": newMembers], withCompletionBlock: { error, ref in
                        completion?(error)
                    })
                }
            })
        }
    }
    
    func get(memberWithRoomId roomId: String, completion: (([String]) -> Void)? = nil){
        memberRef.child(roomId).observeSingleEvent(of: .value, with: { snapshot in
            guard let member = Member(snapshot: snapshot) else {return}
            completion?(member.users)
        })
    }
    
    func remove(memberWithRoomId roomId: String, completion: ((Error?) -> Void)? = nil){
        if let user = Auth.auth().currentUser {
            get(memberWithRoomId: roomId, completion: { members in
                if members.contains(user.uid) {
                    var newMembers = members
                    newMembers.removeAll([user.uid])
                    self.memberRef.child(roomId).setValue(["users": newMembers], withCompletionBlock: { error, ref in
                        completion?(error)
                    })
                }
            })
        }
    }
    
}
