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
    
    @objc dynamic var messageId: String?
    @objc dynamic var sender: String?
    @objc dynamic var sentDate: Date?
    @objc dynamic var roomId: String?
    @objc dynamic var type: String?
    
    @objc dynamic var contentText: String?
    @objc dynamic var contentImageUrl: String?
    @objc dynamic var contentImageThumbnail: String?
    @objc dynamic var contentVideoUrl: String?
    @objc dynamic var contentVideoThumbnail: String?
    override static func primaryKey() -> String? { return "messageId" }
    override static func ignoredProperties() -> [String] { return ["data"] }
    
    var data: MessageData? {
        get {
            guard let type = self.type else {return nil}
            switch type {
            case "text":
                guard let content = self.contentText else {return nil}
                return .text(content)
            case "photo":
                guard let thumbnail = self.contentImageThumbnail else {return nil}
                guard let image = thumbnail.toUIImage() else {return nil}
                return .photo(image)
            case "video":
                guard let thumbnail = self.contentVideoThumbnail else {return nil}
                guard let image = thumbnail.toUIImage() else {return nil}
                guard let urlString = contentVideoUrl else {return nil}
                guard let url = URL(string: urlString) else {return nil}
                return .video(file: url, thumbnail: image)
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
                self.contentImageThumbnail = image.resize(width: 400, height: 400).toBase64()
                break
            case .video(file: let file, thumbnail: let image):
                self.type = "video"
                self.contentVideoThumbnail = image.resize(width: 400, height: 400).toBase64()
                self.contentVideoUrl = file.absoluteString
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
        self.contentImageUrl = url.absoluteString
        self.data = .photo(image)
    }
    
    convenience init(roomId: String, thumbnail: UIImage, video: URL, sender: String, date: Date) {
        self.init()
        self.roomId = roomId
        self.sender = sender
        self.sentDate = date
        self.data = .video(file: video, thumbnail: thumbnail)
    }
    
    convenience required init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        messageId <- map[Message.firebaseIdKey]
        roomId <- map["room"]
        sender <- map["sender"]
        sentDate <- (map["date"], Transform.date)
        
        guard let array = map.JSON["data"] as? [String: Any] else {return}
        guard let type = array["type"] as? String else {return}
        
        switch type {
        case "text":
            guard let text = array["text"] as? String else {return}
            data = .text(text)
            break
        case "photo":
            guard let imageString = array["image"] as? String else {return}
            guard let image = imageString.toUIImage() else {return}
            contentImageUrl = array["url"] as? String
            data = .photo(image)
            break
        case "video":
            guard let thumbnail = array["image"] as? String else {return}
            guard let urlString = array["url"] as? String else {return}
            guard let image = thumbnail.toUIImage() else {return}
            guard let url = URL(string: urlString) else {return}
            data = .video(file: url, thumbnail: image)
        default:
            break
        }
    }
    
    func keyValue() -> [AnyHashable : Any]? {
        var array = [AnyHashable: Any]()
        array["date"] = Transform.date.transformToJSON(sentDate)
        array["sender"] = sender
        array["room"] = roomId
        
        if let data = data {
            switch data {
            case .text(_):
                array["data"] = [ "type": "text", "text": contentText ]
                break
            case .photo(_):
                array["data"] = [ "type": "photo", "image": contentImageThumbnail, "url": contentImageUrl ]
                break
            case .video(file: _, thumbnail: _):
                array["data"] = [ "type": "video", "image": contentVideoThumbnail, "url": contentVideoUrl]
            default:
                break
            }
        }
        
        return array
    }
    
    // Getter
    
    static func get(completion: @escaping ((Results<Message>?) -> Void)) {
        Realm.asyncOpen(callback: { realm, error in
            guard let realm = realm else {completion(nil); return}
            completion(realm.objects(Message.self))
        })
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
            let data = realm.object(ofType: Message.self, forPrimaryKey: object.messageId)
            guard let message = data else {completion?(error); return}
            do { try realm.write { realm.delete(message) } }
            catch let error { completion?(error) }
        })
    }
    
}
