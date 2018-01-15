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

enum MessageData {
    /// A standard text message.
    case text(String)
    
    /// A photo message.
    case photo(UIImage)
    
    /// A photo message with url.
    case photoAsync(URL,UIImage)
    
}

class Message: Object, FirebaseModel, Mappable {
    
    @objc dynamic var messageId: String?
    @objc dynamic var sender: String?
    @objc dynamic var sentDate: Date?
    @objc dynamic var roomId: String?
    @objc dynamic var type: String?
    
    @objc dynamic var contentText: String?
    @objc dynamic var contentImageUrl: String?
    @objc dynamic var contentImageThumbnail: String?
    
    override static func primaryKey() -> String? { return "messageId" }
    override static func ignoredProperties() -> [String] { return ["data"] }
    
    var data: MessageData? {
        get {
            guard let type = self.type else {return nil}
            switch type {
            case "text":
                guard let content = self.contentText else {return nil}
                return .text(content)
            case "photoAsync":
                guard let thumbnail = self.contentImageThumbnail else {return nil}
                guard let urlString = self.contentImageUrl else {return nil}
                guard let image = thumbnail.toUIImage() else {return nil}
                guard let url = URL(string: urlString) else {return nil}
                return .photoAsync(url, image)
            case "photo":
                guard let thumbnail = self.contentImageThumbnail else {return nil}
                guard let image = thumbnail.toUIImage() else {return nil}
                return .photo(image)
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
            case .photoAsync(let url, let image):
                self.type = "photoAsync"
                self.contentImageThumbnail = image.resize(width: 400, height: 400).toBase64()
                self.contentImageUrl = url.absoluteString
                break
            case .photo(let image):
                self.type = "photo"
                self.contentImageThumbnail = image.resize(width: 400, height: 400).toBase64()
                self.contentImageUrl = nil
            }
        }
    }
    
    convenience init(roomId: String, text: String, sender: String, date: Date) {
        self.init()
        self.roomId = roomId
        self.sender = sender
        self.sentDate = date
        self.data = .text(text)
    }
    
    convenience init(roomId: String, image: UIImage, sender: String, date: Date) {
        self.init()
        self.roomId = roomId
        self.sender = sender
        self.sentDate = date
        self.data = .photo(image)
    }
    
    convenience init(roomId: String, image: UIImage, url: URL, sender: String, date: Date) {
        self.init()
        self.roomId = roomId
        self.sender = sender
        self.sentDate = date
        self.data = .photoAsync(url,image)
    }
    
    convenience required init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        messageId <- map[Message.firebaseIdKey]
        roomId <- map["room"]
        sender <- map["sender"]
        sentDate <- (map["date"], Transform.date)
        data <- (map["data"], Transform.data)
    }
    
    func keyValue() -> [AnyHashable : Any]? {
        var array = [AnyHashable: Any]()
        array["data"] = Transform.data.transformToJSON(data)
        array["date"] = Transform.date.transformToJSON(sentDate)
        array["sender"] = sender
        array["room"] = roomId
        return array
    }
    
    func getData() -> MessageKit.MessageData? {
        guard let data = data else {return nil}
        switch data {
        case .text(let text):
            return MessageKit.MessageData.text(text)
        case .photo(let image):
            return MessageKit.MessageData.photo(image)
        case .photoAsync(_, let image):
            return MessageKit.MessageData.photo(image)
        }
    }
    
    // Updater
    
    static func update(object: Message, completion: ((Error?) -> Void)? = nil) {
        Realm.asyncOpen(callback: { realm, error in
            guard let realm = realm else {completion?(error); return}
            do { try realm.write { realm.add(object, update: true) } }
            catch let error { completion?(error) }
        })
    }
    
    // Delete
    
    static func delete(object: Message, completion: ((Error?) -> Void)? = nil) {
        Realm.asyncOpen(callback: { realm, error in
            guard let realm = realm else {completion?(error); return}
            do { try realm.write { realm.delete(object) } }
            catch let error { completion?(error) }
        })
    }
    
}
