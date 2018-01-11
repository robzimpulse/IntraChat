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
import RealmSwift
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
    
//    let rooms = Variable<[Room]>([])
    
    let messages = Variable<[Message]>([])
    
    let roomForMessage = Variable<Room?>(nil)
    
    let disposeBag = DisposeBag()
    
    var authListener: AuthStateDidChangeListenerHandle?
    
    private var lastUid: String?
    
    lazy var roomRef: DatabaseReference = {
        return Database.database().reference().child("room")
    }()
    
    lazy var userRef: DatabaseReference = {
        return Database.database().reference().child("user")
    }()
    
    lazy var messageRef: DatabaseReference = {
        return Database.database().reference().child("message")
    }()
    
    lazy var notificationRef: DatabaseReference = {
        return Database.database().reference().child("notification")
    }()
    
    lazy var storageRef: StorageReference = {
        return Storage.storage().reference()
    }()
    
    override init() {
        
        super.init()
        
        Messaging.messaging().delegate = self
        
        userForRoom.asObservable().bind(onNext: {
            if let uid = $0?.uid {
                self.roomRef.observe(.childAdded, with: { snapshot in
                    guard let room = Room(snapshot: snapshot) else {return}
                    guard room.users.contains(uid) else {return}
                    Realm.asyncOpen(callback: { realm, _ in
                        guard let realm = realm else {return}
                        print("added to realm")
                        do { try realm.write { realm.add(room, update: true) } }
                        catch { print("error add to realm") }
                    })
                    
                })
                
                self.roomRef.observe(.childRemoved, with: { snapshot in
                    guard let room = Room(snapshot: snapshot) else {return}
                    guard room.users.contains(uid) else {return}
                    Realm.asyncOpen(callback: { realm, _ in
                        guard let realm = realm else {return}
                        guard let roomId = room.id else {return}
                        guard let object = realm.object(ofType: Room.self, forPrimaryKey: roomId) else {return}
                        print("deleted from realm")
                        do { try realm.write { realm.delete(object) } }
                        catch { print("error delete from realm") }
                    })
                })
                
                self.roomRef.observe(.childChanged, with: { snapshot in
                    guard let room = Room(snapshot: snapshot) else {return}
                    guard room.users.contains(uid) else {return}
                    Realm.asyncOpen(callback: { realm, _ in
                        guard let realm = realm else {return}
                        print("updated to realm")
                        do { try realm.write { realm.add(room, update: true) } }
                        catch { print("error update to realm") }
                    })
                })
            }else{
                self.roomRef.removeAllObservers()
            }
            
        }).disposed(by: disposeBag)
        
        roomForMessage.asObservable().bind(onNext: {
            if let room = $0 {
                self.messageRef.observe(.childAdded, with: { snapshot in
                    guard let message = Message(snapshot: snapshot) else {return}
                    guard message.roomId == room.id else {return}
                    Realm.asyncOpen(callback: { realm, _ in
                        guard let realm = realm else {return}
                        print("add to realm")
                        do { try realm.write { realm.add(message, update: true) } }
                        catch { print("error update to realm") }
                    })
                })
                
                self.messageRef.observe(.childRemoved, with: { snapshot in
                    guard let message = Message(snapshot: snapshot) else {return}
                    guard message.roomId == room.id else {return}
                    Realm.asyncOpen(callback: { realm, _ in
                        guard let realm = realm else {return}
                        guard let messageId = message.messageId else {return}
                        guard let object = realm.object(ofType: Message.self, forPrimaryKey: messageId) else {return}
                        print("deleted from realm")
                        do { try realm.write { realm.delete(object) } }
                        catch { print("error delete from realm") }
                    })
                })
                
                self.messageRef.observe(.childChanged, with: { snapshot in
                    guard let message = Message(snapshot: snapshot) else {return}
                    guard message.roomId == room.id else {return}
                    Realm.asyncOpen(callback: { realm, _ in
                        guard let realm = realm else {return}
                        print("updated to realm")
                        do { try realm.write { realm.add(message, update: true) } }
                        catch { print("error update to realm") }
                    })
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
                
                self.notificationRef.observe(.childAdded, with: { snapshot in
                    guard let notification = Notification(snapshot: snapshot) else {return}
                    guard notification.receiver == user.uid else {return}
                    self.localNotification(object: notification)
                    snapshot.ref.removeValue()
                })
                
                self.userRef.child(user.uid).updateChildValues(["online": true])
                self.userRef.child(user.uid).onDisconnectUpdateChildValues(["online": false])
                self.userRef.child(user.uid).updateChildValues(User(user: user).keyValue() ?? [:])
                
                Messaging.messaging().subscribe(toTopic: user.uid)
                self.lastUid = user.uid
                
            }else{
                
                self.users.value = []
                self.userRef.removeAllObservers()
                self.notificationRef.removeAllObservers()
                if let uid = self.lastUid {
                    defer{ self.lastUid = nil }
                    self.userRef.child(uid).updateChildValues(["online": false])
                    Messaging.messaging().unsubscribe(fromTopic: uid)
                }
                
            }
        })
    }
    
    deinit {
        guard let listener = authListener else {return}
        Auth.auth().removeStateDidChangeListener(listener)
    }
    
    func setupApns(token: Data?){
        Messaging.messaging().apnsToken = token
    }
    
    func currentUser() -> Firebase.User? {
        return Auth.auth().currentUser
    }
    
    func logout(completion: ((Error?) -> Void)? = nil) {
        do { try Auth.auth().signOut(); completion?(nil) }
        catch let error { completion?(error) }
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
    
    func didReceiveRemoteNotification(userInfo: [AnyHashable : Any]) {
        print("didReceiveRemoteNotification: \(userInfo)")
    }
    
    // MARK: Message
    
    func create(message: Message, completion: ((Error?) -> Void)? = nil){
        messageRef.childByAutoId().setValue(message.keyValue(), withCompletionBlock: { error, ref in
            completion?(error)
        })
    }
    
    // MARK: Notification
    
    func create(notification: Notification, completion: ((Error?) -> Void)? = nil){
        notificationRef.childByAutoId().setValue(notification.keyValue(), withCompletionBlock: { error, ref in
            completion?(error)
        })
    }
    
    // MARK: Room
    
    func create(room: Room, completion: ((Error?) -> Void)? = nil){
        roomRef.childByAutoId().setValue(room.keyValue(), withCompletionBlock: { error, ref in
            completion?(error)
        })
    }
    
    func updateLastChat(roomId: String, date: Date, completion: ((Error?) -> Void)? = nil){
        roomRef.child(roomId)
            .updateChildValues(
                ["lastChat": Transform.date.transformToJSON(date) as Any],
                withCompletionBlock: { error, _ in
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
    
    private func localNotification(object: Notification, delay: TimeInterval = 0){
        let notification = UILocalNotification()
        notification.alertTitle = object.title
        notification.alertBody = object.body
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.fireDate = Date().addingTimeInterval(delay)
        UIApplication.shared.scheduleLocalNotification(notification)
    }
}

extension FirebaseManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("didReceiveRegistrationToken: \(fcmToken)")
    }
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("didReceive remoteMessage: \(remoteMessage.appData)")
    }
}
