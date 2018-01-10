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

class Message: MessageType, FirebaseModel, Mappable, Equatable {
    
    var sender: Sender
    var messageId: String
    var sentDate: Date
    var data: MessageData
    var roomId: String
    
    static let transformSender = TransformOf<Sender, String>(fromJSON: { (value: String?) -> Sender? in
        // transform value from String? to Sender?
        guard let id = value else {return nil}
        let user = FirebaseManager.shared.users.value.filter({ id == $0.uid }).first
        return Sender(id: id, displayName: user?.name ?? "User")
    }, toJSON: { (value: Sender?) -> String? in
        // transform value from Sender? to String?
        return value?.id
    })
    
    static let transformDate = TransformOf<Date, String>(fromJSON: { (value: String?) -> Date? in
        // transform value from String? to Date?
        return value?.dateFormat()
    }, toJSON: { (value: Date?) -> String? in
        // transform value from Date? to String?
        return value?.toString(format: "yyyy-MM-dd'T'HH:mm:ssZ")
    })
    
    static let transformData = TransformOf<MessageData, [String: Any]>(fromJSON: { (value: [String: Any]?) -> MessageData? in
        // transform value from [String: Any]? to MessageData?
        guard let type = value?["type"] as? String else {return nil}
        guard let content = value?["content"] as? String else {return nil}
        switch type {
        case "text":
            return MessageData.text(content)
        default:
            return nil
        }
        
    }, toJSON: { (value: MessageData?) -> [String: Any]? in
        // transform value from MessageData? to [String: Any]?
        guard let value = value else {return nil}
        switch value {
        case .text(let text):
            return ["type": "text", "content": text]
        default:
            return ["type": "unknown", "content": "unknown"]
        }
    })
    
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
        guard let date = Message.transformDate.transformFromJSON(map.JSON["date"]) else {return nil}
        guard let sender = Message.transformSender.transformFromJSON(map.JSON["sender"]) else {return nil}
        guard let data = Message.transformData.transformFromJSON(map.JSON["data"]) else {return nil}
        
        self.init(roomId: roomId, data: data, sender: sender, messageId: messageId, date: date)
    }
    
    func mapping(map: Map) {
        messageId <- map[Message.firebaseIdKey]
        roomId <- map["room"]
    }
    
    func keyValue() -> [AnyHashable : Any]? {
        var array = [AnyHashable: Any]()
        
        array["data"] = Message.transformData.transformToJSON(data)
        array["date"] = Message.transformDate.transformToJSON(sentDate)
        array["sender"] = Message.transformSender.transformToJSON(sender)
        array["room"] = roomId
        
        return array
    }
    
    // MARK: Equatable
    
    static func ==(lhs: Message, rhs: Message) -> Bool {
        return lhs.messageId == rhs.messageId
    }
    
}
