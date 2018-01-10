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
import ObjectMapper

class Message: MessageType, FirebaseModel, Mappable {
    
    var sender: Sender
    var messageId: String
    var sentDate: Date
    var data: MessageData
    var roomId: String
    
    init(roomId: String, data: MessageData, sender: Sender, messageId: String, date: Date) {
        self.data = data
        self.sender = sender
        self.messageId = messageId
        self.sentDate = date
        self.roomId = roomId
    }
    
    convenience init(roomId: String, text: String, sender: Sender, messageId: String, date: Date) {
        self.init(roomId: roomId, data: .text(text), sender: sender, messageId: messageId, date: date)
    }
    
    convenience required init?(map: Map) {
        guard let messageId = map.JSON[Message.firebaseIdKey] as? String else {return nil}
        guard let roomId = map.JSON["room"] as? String else {return nil}
        guard let date = Transform.date.transformFromJSON(map.JSON["date"]) else {return nil}
        guard let sender = Transform.messageSender.transformFromJSON(map.JSON["sender"]) else {return nil}
        guard let data = Transform.messageData.transformFromJSON(map.JSON["data"]) else {return nil}
        
        self.init(roomId: roomId, data: data, sender: sender, messageId: messageId, date: date)
    }
    
    func mapping(map: Map) {
    }
    
    func keyValue() -> [AnyHashable : Any]? {
        var array = [AnyHashable: Any]()
        
        array["data"] = Transform.messageData.transformToJSON(data)
        array["date"] = Transform.date.transformToJSON(sentDate)
        array["sender"] = Transform.messageSender.transformToJSON(sender)
        array["room"] = roomId
        
        return array
    }
    
}
