//
//  Notification.swift
//  IntraChat
//
//  Created by admin on 10/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import ObjectMapper

class Notification: Mappable, FirebaseModel {
  
  var title: String?
  var body: String?
  var receiver: String?
  var room: String?
  var sender: String?
  
  convenience init(title: String, body: String, receiver: String, room: String, sender: String) {
    self.init()
    self.title = title
    self.body = body
    self.receiver = receiver
    self.sender = sender
    self.room = room
  }
  
  convenience required init?(map: Map) {
    self.init()
  }
  
  func mapping(map: Map) {
    title <- map["title"]
    body <- map["body"]
    receiver <- map["receiver"]
    room <- map["room"]
    sender <- map["sender"]
  }
  
  func keyValue() -> [AnyHashable : Any]? {
    return [
      "title": title as Any,
      "body": body as Any,
      "receiver": receiver as Any,
      "room": room as Any,
      "sender": sender as Any
    ]
  }
  
}
