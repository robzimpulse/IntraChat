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
    
    override static func ignoredProperties() -> [String] {
        return ["imageView"]
    }
    
    private let imageView = UIImageView()
    
    convenience init(user: Firebase.User) {
        self.init()
        uid = user.uid
        name = user.displayName
        email = user.email
        photo = user.photoURL?.absoluteString
        phone = user.phoneNumber
    }
    
    func image() -> UIImage? { return imageView.image }
    
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
        
        guard let value = photo else {return}
        guard let url = URL(string: value) else {return}
        imageView.af_setImage(withURL: url)
    }
    
    func keyValue() -> [AnyHashable : Any]? {
        var array : [AnyHashable: Any] = ["online": online]
        if let data = name { array["name"] = data }
        if let data = email { array["email"] = data }
        if let data = photo { array["photo"] = data }
        if let data = phone { array["phone"] = data }
        return array
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
            do { try realm.write { realm.delete(object) } }
            catch let error { completion?(error) }
        })
    }
}
