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
    
    Observable<Int>
      .interval(1, scheduler: MainScheduler.instance)
      .subscribe({ _ in
        print("Resource count \(RxSwift.Resources.total)")
      })
    
    Messaging.messaging().delegate = self
    
    authListener = Auth.auth().addStateDidChangeListener({ [weak self] auth, user in
      guard let strongSelf = self else {return}
      if let user = user {
        
        // Mark: Room Listener
        
        strongSelf.roomRef.observe(.childAdded, with: { snapshot in
          guard let room = Room(snapshot: snapshot) else {return}
          Room.update(object: room)
          
          // Mark: Message Listener
          
          guard let id = room.id else {return}
          strongSelf.messageRef.queryOrdered(byChild: "room").queryEqual(toValue: id)
            .observe(.childAdded, with: { snapshot in
              guard let message = Message(snapshot: snapshot) else {return}
              Message.update(object: message)
            })
          strongSelf.messageRef.queryOrdered(byChild: "room").queryEqual(toValue: id)
            .observe(.childChanged, with: { snapshot in
              guard let message = Message(snapshot: snapshot) else {return}
              Message.update(object: message)
            })
          strongSelf.messageRef.queryOrdered(byChild: "room").queryEqual(toValue: id)
            .observe(.childRemoved, with: { snapshot in
              guard let message = Message(snapshot: snapshot) else {return}
              Message.delete(object: message)
            })
        })
        
        strongSelf.roomRef.observe(.childRemoved, with: { snapshot in
          guard let room = Room(snapshot: snapshot) else {return}
          Room.delete(object: room)
          guard let id = room.id else {return}
          strongSelf.messageRef.queryEqual(toValue: id, childKey: "roomId").removeAllObservers()
        })
        
        strongSelf.roomRef.observe(.childChanged, with: { snapshot in
          guard let room = Room(snapshot: snapshot) else {return}
          
          Room.update(object: room)
        })
        
        // Mark: User Listener
        
        strongSelf.userRef.observe(.childAdded, with: { snapshot in
          guard let user = User(snapshot: snapshot) else {return}
          User.update(object: user)
        })
        
        strongSelf.userRef.observe(.childRemoved, with: { snapshot in
          guard let user = User(snapshot: snapshot) else {return}
          User.delete(object: user)
        })
        
        strongSelf.userRef.observe(.childChanged, with: { snapshot in
          guard let user = User(snapshot: snapshot) else {return}
          User.update(object: user)
        })
        
        strongSelf.notificationRef.observe(.childAdded, with: { snapshot in
          guard let notification = Notification(snapshot: snapshot) else {return}
          guard notification.receiver == user.uid else {return}
          if let roomId = notification.room { Room.increaseUnread(roomId: roomId) }
          strongSelf.localNotification(object: notification)
          snapshot.ref.removeValue()
        })
        
        strongSelf.userRef.child(user.uid).updateChildValues(["online": true])
        strongSelf.userRef.child(user.uid).onDisconnectUpdateChildValues(["online": false])
        strongSelf.userRef.child(user.uid).updateChildValues(User(user: user).keyValue() ?? [:])
        
        Messaging.messaging().subscribe(toTopic: user.uid)
        strongSelf.lastUid = user.uid
        
      }else{
        
        strongSelf.messageRef.removeAllObservers()
        strongSelf.roomRef.removeAllObservers()
        strongSelf.userRef.removeAllObservers()
        strongSelf.notificationRef.removeAllObservers()
        if let uid = strongSelf.lastUid {
          defer{ strongSelf.lastUid = nil }
          strongSelf.userRef.child(uid).updateChildValues(["online": false])
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
    guard let user = Auth.auth().currentUser else {return}
    FirebaseManager.shared.userRef.child(user.uid)
      .updateChildValues(["online": false], withCompletionBlock: { _, _ in
        Realm.asyncOpen(callback: { realm, _ in
          guard let realm = realm else {return}
          print("remove all database")
          do {
            try Auth.auth().signOut()
            try realm.write {
              realm.delete(realm.objects(Room.self))
              realm.delete(realm.objects(Message.self))
              realm.delete(realm.objects(User.self))
            }
          } catch { completion?(error) }
        })
      })
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
  
  // MARK: Profile
  
  func change(name: String, completion: UserProfileChangeCallback? = nil){
    guard let user = Auth.auth().currentUser else {completion?(nil);return}
    let request = user.createProfileChangeRequest()
    request.displayName = name
    request.commitChanges(completion: { [weak self] error in
      guard let strongSelf = self else {return}
      strongSelf.userRef.child(user.uid).updateChildValues(User(user: user).keyValue() ?? [:])
      completion?(error)
    })
  }
  
  func change(photoUrl: URL, completion: UserProfileChangeCallback? = nil){
    guard let user = Auth.auth().currentUser else {completion?(nil);return}
    let request = user.createProfileChangeRequest()
    request.photoURL = photoUrl
    request.commitChanges(completion: { [weak self] error in
      guard let strongSelf = self else {return}
      strongSelf.userRef.child(user.uid).updateChildValues(User(user: user).keyValue() ?? [:])
      completion?(error)
    })
  }
  
  // MARK: Message
  
  func create(message: Message, room: Room, completion: ((Error?, DatabaseReference?) -> Void)? = nil){
    messageRef.childByAutoId().setValue(message.keyValue(), withCompletionBlock: { completion?($0, $1) })
    guard let type = message.data else {return}
    switch type {
    case .photo:
      room.users.filter({ currentUser()?.uid != $0 }).forEach({ user in
        FirebaseManager.shared.create(notification: Notification(
          title: "\(currentUser()?.displayName ?? "") @\(room.name ?? "")",
          body: "📷 Image",
          receiver: user,
          room: room.id ?? "",
          sender: currentUser()?.uid ?? ""
        ))
      })
      break
    case .text(let text):
      room.users.filter({ currentUser()?.uid != $0 }).forEach({ user in
        FirebaseManager.shared.create(notification: Notification(
          title: "\(currentUser()?.displayName ?? "") @\(room.name ?? "")",
          body: text,
          receiver: user,
          room: room.id ?? "",
          sender: currentUser()?.uid ?? ""
        ))
      })
      break
    case .video:
      room.users.filter({ currentUser()?.uid != $0 }).forEach({ user in
        FirebaseManager.shared.create(notification: Notification(
          title: "\(currentUser()?.displayName ?? "") @\(room.name ?? "")",
          body: "📹 Video",
          receiver: user,
          room: room.id ?? "",
          sender: currentUser()?.uid ?? ""
        ))
      })
      break
    case .location:
      room.users.filter({ currentUser()?.uid != $0 }).forEach({ user in
        FirebaseManager.shared.create(notification: Notification(
          title: "\(currentUser()?.displayName ?? "") @\(room.name ?? "")",
          body: "📍Location",
          receiver: user,
          room: room.id ?? "",
          sender: currentUser()?.uid ?? ""
        ))
      })
      break
    default:
      break
    }
  }
  
  func update(message: Message, completion: ((Error?) -> Void)? = nil){
    guard let messageId = message.messageId else {return}
    messageRef.child(messageId).updateChildValues(message.keyValue() ?? [:], withCompletionBlock: { error, ref in
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
    roomRef.childByAutoId().setValue(room.keyValue(), withCompletionBlock: { [weak self] error, ref in
      guard let strongSelf = self else {return}
      guard error == nil else {completion?(error);return}
      guard let user = strongSelf.currentUser() else {return}
      room.users.filter({ $0 != user.uid }).forEach({
        FirebaseManager.shared.create(notification: Notification(
          title: "Room Invitation",
          body: "You have been invited to room @\(room.name ?? "") by \(user.displayName ?? "")",
          receiver: $0,
          room: room.id ?? "",
          sender: user.uid
        ))
      })
      completion?(error)
    })
  }
  
  func invite(user: [User], to room: Room, completion: ((Error?) -> Void)? = nil){
    guard let roomId = room.id else {completion?(nil);return}
    let users = room.users + user.flatMap({ $0.uid })
    roomRef.child(roomId).updateChildValues(["users": users], withCompletionBlock: { [weak self] error, ref in
      guard let strongSelf = self else {return}
      guard let currentUser = strongSelf.currentUser() else {return}
      guard error == nil else {completion?(error);return}
      user.forEach({
        strongSelf.create(notification: Notification(
          title: "Room Invitation",
          body: "You have been invited to room @\(room.name ?? "") by \(currentUser.displayName ?? "")",
          receiver: $0.uid ?? "",
          room: room.id ?? "",
          sender: currentUser.uid
        ))
      })
      completion?(error)
    })
  }
  
  func exit(room: Room, completion: ((Error?) -> Void)? = nil){
    guard let currentUser = currentUser() else {completion?(nil);return}
    guard let roomId = room.id else {completion?(nil);return}
    let users = room.users.filter({ $0 != currentUser.uid })
    roomRef.child(roomId).updateChildValues(["users": users], withCompletionBlock: { error, ref in
      completion?(error)
    })
  }
  
  func updateLastChatTimeStamp(room: Room, date: Date, completion: ((Error?) -> Void)? = nil){
    guard let roomId = room.id else {completion?(nil);return}
    roomRef.child(roomId).updateChildValues(
      ["lastChat": Transform.date.transformToJSON(date) as Any],
      withCompletionBlock: { error, _ in completion?(error) }
    )
  }
  
  // MARK: Upload File
  
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
    guard let task = upload(image: image, completion: completion) else {return}
    if let handler = handleFailure {task.observe(.failure, handler: handler)}
    if let handler = handlePause {task.observe(.pause, handler: handler)}
    if let handler = handleProgress {task.observe(.progress, handler: handler)}
    if let handler = handleResume {task.observe(.resume, handler: handler)}
    if let handler = handleSuccess {task.observe(.success, handler: handler)}
    if let handler = handleUnknown {task.observe(.unknown, handler: handler)}
  }
  
  func upload(
    video: URL,
    handleFailure: ((StorageTaskSnapshot) -> Void)? = nil,
    handlePause: ((StorageTaskSnapshot) -> Void)? = nil,
    handleProgress: ((StorageTaskSnapshot) -> Void)? = nil,
    handleResume: ((StorageTaskSnapshot) -> Void)? = nil,
    handleSuccess: ((StorageTaskSnapshot) -> Void)? = nil,
    handleUnknown: ((StorageTaskSnapshot) -> Void)? = nil,
    completion: ((StorageMetadata?, Error?) -> Void)? = nil
    ){
    guard let task = upload(video: video, completion: completion) else {return}
    if let handler = handleFailure {task.observe(.failure, handler: handler)}
    if let handler = handlePause {task.observe(.pause, handler: handler)}
    if let handler = handleProgress {task.observe(.progress, handler: handler)}
    if let handler = handleResume {task.observe(.resume, handler: handler)}
    if let handler = handleSuccess {task.observe(.success, handler: handler)}
    if let handler = handleUnknown {task.observe(.unknown, handler: handler)}
  }
  
  @discardableResult
  func upload(image: UIImage, completion: ((StorageMetadata?, Error?) -> Void)? = nil) -> StorageUploadTask?{
    guard let data = UIImagePNGRepresentation(image) else {return nil}
    let filename = UUID().uuidString.appending(".png")
    let meta = StorageMetadata()
    meta.contentType = "image/png"
    return storageRef.child(filename).putData(data, metadata: meta, completion: completion)
  }
  
  @discardableResult
  func upload(video: URL, completion: ((StorageMetadata?, Error?) -> Void)? = nil) -> StorageUploadTask?{
    let filename = UUID().uuidString.appending(".mp4")
    let meta = StorageMetadata()
    meta.contentType = "video/mp4"
    return storageRef.child(filename).putFile(from: video, metadata: meta, completion: completion)
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
