//
//  User.swift
//  IntraChat
//
//  Created by Robyarta on 1/8/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import ObjectMapper

class User: Mappable, FirebaseModel {

    var uid: String = ""
    var name: String?
    var email: String?
    var photo: String?
    var phone: String?
    var online: Bool = false
    
    // MARK: Mappable
    
    convenience required init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        uid <- map[Member.firebaseIdKey]
        name <- map["name"]
        email <- map["email"]
        photo <- map["photo"]
        phone <- map["phone"]
        online <- map["online"]
    }
    
    func keyValue() -> [AnyHashable : Any]? {
        return [
            "name": name,
            "email": email,
            "photo": photo,
            "phone": phone,
            "online": online
        ]
    }
    
}
