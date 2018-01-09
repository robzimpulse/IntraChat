//
//  User.swift
//  IntraChat
//
//  Created by Robyarta on 1/8/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import Firebase
import ObjectMapper

class User: Mappable, FirebaseModel {

    var uid: String = ""
    var name: String?
    var email: String?
    var photo: String?
    var phone: String?
    var online: Bool = false
    
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
    
}
