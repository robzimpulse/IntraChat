//
//  Chat.swift
//  IntraChat
//
//  Created by Robyarta on 1/11/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift
import MessageKit

class Chat: MessageType {
    var kind: MessageKind
    var sender: Sender
    var messageId: String
    var sentDate: Date
    
    convenience init?(message: Message) {
        guard let messageId = message.messageId else {return nil}
        guard let sentDate = message.sentDate else {return nil}
        guard let senderId = message.sender else {return nil}
        guard let username = User.get()?.filter("uid = '\(senderId)'").first?.name else {return nil}
        return nil
//        guard let data = message.data else {return nil}
//        let sender = Sender(id: senderId, displayName: username)
//        self.init(data: data, sender: sender, messageId: messageId, date: sentDate)
    }
    
    convenience init(text: String, sender: Sender, messageId: String, date: Date) {
        self.init(data: .text(text), sender: sender, messageId: messageId, date: date)
    }
    
    convenience init(video: Media, sender: Sender, messageId: String, date: Date) {
        self.init(data: .video(video), sender: sender, messageId: messageId, date: date)
    }
    
    convenience init(image: Media, sender: Sender, messageId: String, date: Date) {
        self.init(data: .photo(image), sender: sender, messageId: messageId, date: date)
    }
    
    convenience init(location: Location, sender: Sender, messageId: String, date: Date) {
        self.init(data: .location(location), sender: sender, messageId: messageId, date: date)
    }
    
    init(data: MessageKind, sender: Sender, messageId: String, date: Date) {
        self.kind = data
        self.sender = sender
        self.messageId = messageId
        self.sentDate = date
    }
    
    func getMessage(completion: @escaping ((Message?) -> Void) ){
        Message.get(completion: { completion($0?.filter("messageId = '\(self.messageId)'").first) })
    }
}
