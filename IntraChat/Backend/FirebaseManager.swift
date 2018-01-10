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
import FirebaseStorage
import FirebaseDatabase
import EZSwiftExtensions

protocol FirebaseModel {
    func keyValue() -> [AnyHashable: Any]?
}

class FirebaseManager: NSObject {
    
    static let shared = FirebaseManager()
    
    let users = Variable<[User]>([])
    
    let userForRoom = Variable<User?>(nil)
    
    let rooms = Variable<[Room]>([])
    
    let messages = Variable<[Message]>([])
    
    let roomForMessage = Variable<Room?>(nil)
    
    let disposeBag = DisposeBag()
    
    var authListener: AuthStateDidChangeListenerHandle?
    
    lazy var roomRef: DatabaseReference = {
        return Database.database().reference().child("room")
    }()
    
    lazy var userRef: DatabaseReference = {
        return Database.database().reference().child("user")
    }()
    
    lazy var messageRef: DatabaseReference = {
        return Database.database().reference().child("message")
    }()
    
    lazy var storageRef: StorageReference = {
        return Storage.storage().reference()
    }()
    
    override init() {
        
        super.init()
        
        FirebaseApp.configure()
        
        userForRoom.asObservable().bind(onNext: {
            if let user = $0 {
                self.roomRef.observe(.childAdded, with: { snapshot in
                    guard let room = Room(snapshot: snapshot) else {return}
                    guard room.users.contains(user.uid) else {return}
                    self.rooms.value.append(room)
                })
                
                self.roomRef.observe(.childRemoved, with: { snapshot in
                    guard let room = Room(snapshot: snapshot) else {return}
                    guard let index = self.rooms.value.index(where: { room.id == $0.id }) else {return}
                    guard room.users.contains(user.uid) else {return}
                    self.rooms.value.remove(at: index)
                })
                
                self.roomRef.observe(.childChanged, with: { snapshot in
                    guard let room = Room(snapshot: snapshot) else {return}
                    guard let index = self.rooms.value.index(where: { room.id == $0.id }) else {return}
                    guard room.users.contains(user.uid) else {return}
                    self.rooms.value[index] = room
                })
            }else{
                self.rooms.value = []
                self.roomRef.removeAllObservers()
            }
            
        }).disposed(by: disposeBag)
        
        roomForMessage.asObservable().bind(onNext: {
            if let room = $0 {
                self.messageRef.observe(.childAdded, with: { snapshot in
                    guard let message = Message(snapshot: snapshot) else {return}
                    guard message.roomId == room.id else {return}
                    self.messages.value.append(message)
                })
                
                self.messageRef.observe(.childRemoved, with: { snapshot in
                    guard let message = Message(snapshot: snapshot) else {return}
                    guard message.roomId == room.id else {return}
                    guard let index = self.messages.value.index(where: { message.messageId == $0.messageId }) else {return}
                    self.messages.value.remove(at: index)
                })
                
                self.messageRef.observe(.childChanged, with: { snapshot in
                    guard let message = Message(snapshot: snapshot) else {return}
                    guard message.roomId == room.id else {return}
                    guard let index = self.messages.value.index(where: { message.messageId == $0.messageId }) else {return}
                    self.messages.value[index] = message
                })
            }else{
                self.messages.value = []
                self.messageRef.removeAllObservers()
            }
        }).disposed(by: disposeBag)
        
        
        authListener = Auth.auth().addStateDidChangeListener({ auth, user in
            if let user = user {
                
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
                
                self.userRef.child(user.uid).onDisconnectUpdateChildValues(["online": false])
                self.userRef.child(user.uid).updateChildValues(User(user: user).keyValue() ?? [:])
                
            }else{
                
                self.users.value = []
                self.userRef.removeAllObservers()
                
            }
        })
    }
    
    deinit {
        guard let listener = authListener else {return}
        Auth.auth().removeStateDidChangeListener(listener)
    }
    
    func currentUser() -> Firebase.User? {
        return Auth.auth().currentUser
    }
    
    // MARK: Application Delegate
    
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
    
    // MARK: Message
    
    func create(message: Message, completion: ((Error?) -> Void)? = nil){
        messageRef.childByAutoId().setValue(message.keyValue(), withCompletionBlock: { error, ref in
            completion?(error)
        })
    }
    
    // MARK: Room
    
    func create(room: Room, completion: ((Error?) -> Void)? = nil){
        roomRef.childByAutoId().setValue(room.keyValue(), withCompletionBlock: { error, ref in
            completion?(error)
        })
    }
    
    // MARK: files upload
    func upload(
        image: UIImage,
        handleFailure: ((StorageTaskSnapshot) -> Void)? = nil,
        handlePause: ((StorageTaskSnapshot) -> Void)? = nil,
        handleProgress: ((StorageTaskSnapshot) -> Void)? = nil,
        handleResume: ((StorageTaskSnapshot) -> Void)? = nil,
        handleSuccess: ((StorageTaskSnapshot) -> Void)? = nil,
        handleUnknown: ((StorageTaskSnapshot) -> Void)? = nil,
        completion: ((StorageMetadata?, Error?) -> Void)? = nil
    ){
        guard let data = UIImagePNGRepresentation(image) else {return}
        let filename = UUID().uuidString.appending(".png")
        let meta = StorageMetadata()
        meta.contentType = "image/png"
        let task = storageRef.child(filename).putData(data, metadata: meta, completion: completion)
        if let handler = handleFailure {task.observe(.failure, handler: handler)}
        if let handler = handlePause {task.observe(.pause, handler: handler)}
        if let handler = handleProgress {task.observe(.progress, handler: handler)}
        if let handler = handleResume {task.observe(.resume, handler: handler)}
        if let handler = handleSuccess {task.observe(.success, handler: handler)}
        if let handler = handleUnknown {task.observe(.unknown, handler: handler)}
    }
    
}
