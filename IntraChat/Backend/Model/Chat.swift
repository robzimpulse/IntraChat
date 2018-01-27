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
  var sender: Sender
  var messageId: String
  var sentDate: Date
  var data: MessageKit.MessageData
  
  convenience init?(message: Message) {
    guard let messageId = message.messageId else {return nil}
    guard let sentDate = message.sentDate else {return nil}
    guard let senderId = message.sender else {return nil}
    guard let username = User.get()?.filter("uid = '\(senderId)'").first?.name else {return nil}
    guard let data = message.data else {return nil}
    let sender = Sender(id: senderId, displayName: username)
    self.init(data: data, sender: sender, messageId: messageId, date: sentDate)
  }
  
  init(text: String, sender: Sender, messageId: String, date: Date) {
    self.data = .text(text)
    self.sender = sender
    self.messageId = messageId
    self.sentDate = date
  }
  
  init(image: UIImage, sender: Sender, messageId: String, date: Date) {
    self.data = .photo(image)
    self.sender = sender
    self.messageId = messageId
    self.sentDate = date
  }
  
  init(location: CLLocation, sender: Sender, messageId: String, date: Date) {
    self.data = .location(location)
    self.sender = sender
    self.messageId = messageId
    self.sentDate = date
  }
  
  init(data: MessageData, sender: Sender, messageId: String, date: Date) {
    self.data = data
    self.sender = sender
    self.messageId = messageId
    self.sentDate = date
  }
  
  func getMessage(completion: @escaping ((Message?) -> Void) ){
    Message.get(completion: { completion($0?.filter("messageId = '\(self.messageId)'").first) })
  }
}
