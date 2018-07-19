//
//  User.swift
//  IntraChat
//
//  Created by Robyarta on 1/8/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift
import ObjectMapper

class User: Object, Mappable, FirebaseModel {
    
    @objc dynamic var uid: String?
    @objc dynamic var name: String?
    @objc dynamic var email: String?
    @objc dynamic var photo: String?
    @objc dynamic var phone: String?
    @objc dynamic var online: Bool = false
    
    override static func primaryKey() -> String? { return "uid" }
    
    convenience init(user: Firebase.User) {
        self.init()
        uid = user.uid
        name = user.displayName
        email = user.email
        photo = user.photoURL?.absoluteString
        phone = user.phoneNumber
    }
    
    // MARK: Mappable
    
    convenience required init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        uid <- map[User.firebaseIdKey]
        name <- map["name"]
        email <- map["email"]
        photo <- map["photo"]
        phone <- map["phone"]
        online <- map["online"]
    }
    
    func keyValue() -> [AnyHashable : Any]? {
        var array : [AnyHashable: Any] = ["online": online]
        if let data = name { array["name"] = data }
        if let data = email { array["email"] = data }
        if let data = photo { array["photo"] = data }
        if let data = phone { array["phone"] = data }
        return array
    }
    
    // Getter
    
    static func get() -> Results<User>? {
        do {
            let realm = try Realm()
            return realm.objects(User.self)
        } catch { return nil }
    }
    
    static func get(completion: @escaping ((Results<User>?) -> Void)) {
        Realm.asyncOpen(callback: { realm, error in
            guard let realm = realm else {completion(nil); return}
            completion(realm.objects(User.self))
        })
    }
    
    // Updater
    
    static func update(object: User, completion: ((Error?) -> Void)? = nil) {
        Realm.asyncOpen(callback: { realm, error in
            guard let realm = realm else {completion?(error); return}
            do { try realm.write { realm.add(object, update: true) } }
            catch let error { completion?(error) }
        })
    }
    
    // Delete
    
    static func delete(object: User, completion: ((Error?) -> Void)? = nil) {
        Realm.asyncOpen(callback: { realm, error in
            guard let realm = realm else {completion?(error); return}
            let data = realm.object(ofType: User.self, forPrimaryKey: object.uid)
            guard let user = data else {completion?(error); return}
            do { try realm.write { realm.delete(user) } }
            catch let error { completion?(error) }
        })
    }
}
