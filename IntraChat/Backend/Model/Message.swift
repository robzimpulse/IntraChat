//
//  Message.swift
//  IntraChat
//
//  Created by admin on 9/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import MessageKit

class Message: MessageType {
    
    var sender: Sender
    var messageId: String
    var sentDate: Date
    var data: MessageData
    
    init(data: MessageData, sender: Sender, messageId: String, date: Date) {
        self.data = data
        self.sender = sender
        self.messageId = messageId
        self.sentDate = date
    }
    
    convenience init(text: String, sender: Sender, messageId: String, date: Date) {
        self.init(data: .text(text), sender: sender, messageId: messageId, date: date)
    }
    
}
