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

class RoomUserString: Object {
    @objc dynamic var value = ""
}

class Room: Object, Mappable, FirebaseModel {
    
    @objc dynamic var id: String?
    @objc dynamic var name: String?
    @objc dynamic var icon: String?
    @objc dynamic var lastChat: Date?
    
    override static func primaryKey() -> String? { return "id" }
    
    let _users = List<RoomUserString>()
    var users: [String] {
        get { return _users.map { $0.value } }
        set {
            _users.removeAll()
            newValue.forEach({ _users.append(RoomUserString(value: [$0])) })
        }
    }
    override static func ignoredProperties() -> [String] {
        return ["users"]
    }
    
    convenience init(name: String, icon: String, users: [User]) {
        self.init()
        self.name = name
        self.icon = icon
        self.users = users.flatMap { $0.uid }
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
            do { try realm.write { realm.delete(object) } }
            catch let error { completion?(error) }
        })
    }
    
}
