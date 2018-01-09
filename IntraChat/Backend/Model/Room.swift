//
//  Room.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import ObjectMapper

class Room: Mappable, FirebaseModel {
    
    var id: String = ""
    var name: String = ""
    var icon: String = ""
    var users: [String] = []
    
    convenience init(name: String, icon: String, users: [User]) {
        self.init()
        self.name = name
        self.icon = icon
        self.users = users.map { $0.uid }
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
    }
    
    func keyValue() -> [AnyHashable : Any]? {
        return [
            "name": name,
            "icon": icon,
            "users": users
        ]
    }
    
}
