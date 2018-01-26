//
//  Room.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import RealmSwift
import ObjectMapper

class Room: Object, Mappable, FirebaseModel {
    
    @objc dynamic var id: String?
    @objc dynamic var name: String?
    @objc dynamic var icon: String?
    @objc dynamic var lastChat: Date?
    @objc dynamic var _users: String?
  
    override static func primaryKey() -> String? { return "id" }
    
    var users: [String] {
        get { return _users?.split("|") ?? [] }
        set { _users = newValue.joined(separator: "|") }
    }
  
    override static func ignoredProperties() -> [String] {
        return ["users"]
    }
  
    convenience init(name: String, icon: String, users: [User]) {
        self.init()
        self.name = name
        self.icon = icon
        self.users = users.flatMap({ $0.uid })
    }
    
    // MARK: Mappable
    
    convenience required init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        id <- map[Room.firebaseIdKey]
        name <- map["name"]
        icon <- map["icon"]
        users <- map["users"]
        lastChat <- (map["lastChat"], Transform.date)
    }
    
    func keyValue() -> [AnyHashable : Any]? {
        var array : [String : Any] = [:]
        if let data = lastChat { array["lastChat"] = Transform.date.transformToJSON(data) }
        array["name"] = name
        array["icon"] = icon
        array["users"] = users
        return array
    }
    
    static func get(completion: @escaping ((Results<Room>?) -> Void)) {
        Realm.asyncOpen(callback: { realm, error in
            guard let realm = realm else {completion(nil); return}
            completion(realm.objects(Room.self))
        })
    }
    
    // Updater
    
    static func update(object: Room, completion: ((Error?) -> Void)? = nil) {
        Realm.asyncOpen(callback: { realm, error in
            guard let realm = realm else {completion?(error); return}
            do { try realm.write { realm.add(object, update: true) } }
            catch let error { completion?(error) }
        })
    }
    
    // Delete
    
    static func delete(object: Room, completion: ((Error?) -> Void)? = nil) {
        Realm.asyncOpen(callback: { realm, error in
            guard let realm = realm else {completion?(error); return}
            let data = realm.object(ofType: Room.self, forPrimaryKey: object.id)
            guard let room = data else {completion?(error); return}
            do { try realm.write { realm.delete(room) } }
            catch let error { completion?(error) }
        })
    }
    
}
