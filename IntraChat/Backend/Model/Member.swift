//
//  Member.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import ObjectMapper

class Member: Mappable, FirebaseModel {

    var id: String = ""
    var users: [String] = []
    
    // MARK: Mappable
    
    convenience required init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        id <- map[Member.firebaseIdKey]
        users <- map["users"]
    }
    
    func keyValue() -> [AnyHashable : Any]? {
        return [
            "users": users
        ]
    }
    
}
