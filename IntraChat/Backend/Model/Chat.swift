//
//  Chat.swift
//  IntraChat
//
//  Created by Robyarta on 1/11/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import MessageKit

class Chat: MessageType {
    var sender: Sender
    var messageId: String
    var sentDate: Date
    var data: MessageData
    
    convenience init?(message: Message) {
        guard let data = message.data else {return nil}
        guard let messageId = message.messageId else {return nil}
        guard let sentDate = message.sentDate else {return nil}
        guard let senderId = message.sender else {return nil}
        guard let username = FirebaseManager.shared.users.value.filter({$0.uid == senderId}).first?.name else {return nil}
        let sender = Sender(id: senderId, displayName: username)
        self.init(data: data, sender: sender, messageId: messageId, date: sentDate)
    }
    
    init(data: MessageData, sender: Sender, messageId: String, date: Date) {
        self.data = data
        self.sender = sender
        self.messageId = messageId
        self.sentDate = date
    }
}
