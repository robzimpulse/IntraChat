//
//  Message.swift
//  IntraChat
//
//  Created by admin on 9/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import MessageKit
import RealmSwift
import ObjectMapper

class Message: Object, FirebaseModel, Mappable {
    
    @objc dynamic var sender: String?
    @objc dynamic var messageId: String?
    @objc dynamic var sentDate: Date?
    @objc dynamic var roomId: String?
    @objc dynamic var type: String?
    
    @objc dynamic var contentText: String?
    @objc dynamic var contentImage: String?
    
    override static func primaryKey() -> String? { return "messageId" }
    override static func ignoredProperties() -> [String] {
        return ["data","task"]
    }
    
    var data: MessageData? {
        get {
            guard let type = self.type else {return nil}
            switch type {
            case "text":
                guard let content = self.contentText else {return nil}
                return MessageData.text(content)
            case "photo":
                guard let content = self.contentImage, let image = content.toUIImage() else {return nil}
                return MessageData.photo(image)
            default:
                return nil
            }
        }
        set {
            guard let value = newValue else {return}
            switch value {
            case .text(let text):
                self.type = "text"
                self.contentText = text
                break
            case .photo(let image):
                self.type = "photo"
                self.contentImage = image.toBase64()
                break
            default:
                break
            }
        }
    }
    
    convenience init(roomId: String, text: String, sender: String, date: Date) {
        self.init()
        self.roomId = roomId
        self.sender = sender
        self.sentDate = date
        self.contentText = text
        
        self.data = .text(text)
    }
    
    convenience init(roomId: String, image: UIImage, sender: String, date: Date) {
        self.init()
        self.roomId = roomId
        self.sender = sender
        self.sentDate = date
        self.contentImage = image.toBase64()
        
        self.data = .photo(image)
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
