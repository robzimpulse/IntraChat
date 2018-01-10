//
//  Message.swift
//  IntraChat
//
//  Created by admin on 9/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import MapKit
import MessageKit
import RealmSwift
import ObjectMapper

class Message: Object, FirebaseModel, Mappable {
    
    @objc dynamic var sender: String?
    @objc dynamic var messageId: String?
    @objc dynamic var sentDate: Date?
    @objc dynamic var roomId: String?
    @objc dynamic var type: String?
    @objc dynamic var content: String?
    
    override static func primaryKey() -> String? { return "messageId" }
    override static func ignoredProperties() -> [String] { return ["data"] }
    
    var data: MessageData? {
        get {
            guard let type = self.type else {return nil}
            guard let content = self.content else {return nil}
            if type == "text" {
                return MessageData.text(content)
            } else { return nil }
        }
        set {
            guard let value = newValue else {return}
            switch value {
            case .text(let text):
                self.type = "text"
                self.content = text
                break
            default:
                self.type = nil
                self.content = nil
                break
            }
        }
    }
    
    convenience init(roomId: String, text: String, sender: String, date: Date) {
        self.init()
        self.roomId = roomId
        self.data = .text(text)
        self.sender = sender
        self.sentDate = date
    }
    
    convenience required init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        messageId <- map[Message.firebaseIdKey]
        roomId <- map["room"]
        sender <- map["sender"]
        sentDate <- (map["date"], Transform.date)
        data <- (map["data"], Transform.messageData)
    }
    
    func keyValue() -> [AnyHashable : Any]? {
        var array = [AnyHashable: Any]()
        
        array["data"] = Transform.messageData.transformToJSON(data)
        array["date"] = Transform.date.transformToJSON(sentDate)
        array["sender"] = sender
        array["room"] = roomId
        
        return array
    }
    
}
