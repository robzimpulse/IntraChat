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

class Message: MessageType, FirebaseModel {
    var sender: Sender
    var messageId: String
    var sentDate: Date
    var data: MessageData
    var roomId: String
    
    private let format: String = "yyyy-MM-dd'T'HH:mm:ssZ"
    
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
    
    func keyValue() -> [AnyHashable : Any]? {
        var array = [AnyHashable: Any]()
        
        switch data {
        case .text(let text):
            array["type"] = "text"
            array["data"] = text
            array["date"] = sentDate.toString(format: format)
            array["sender"] = sender.id
            array["room"] = roomId
            break
        default:
            print("unknown data")
            break
        }
        
        return array
    }
    
}
