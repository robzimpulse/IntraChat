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
    var lastChat: Date?
    
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
    
}
