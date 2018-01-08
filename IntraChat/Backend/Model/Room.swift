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
    
    // MARK: Mappable
    
    convenience required init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        id <- map[Room.firebaseIdKey]
        name <- map["name"]
        icon <- map["icon"]
    }
    
    func keyValue() -> [AnyHashable : Any]? {
        return [
            "name": name,
            "icon": icon
        ]
    }
    
}
