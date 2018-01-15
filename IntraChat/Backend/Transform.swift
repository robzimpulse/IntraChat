//
//  Transform.swift
//  IntraChat
//
//  Created by admin on 10/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import MessageKit
import ObjectMapper

class Transform: NSObject {

//    static let sender = TransformOf<Sender, String>(fromJSON: { (value: String?) -> Sender? in
//        // transform value from String? to Sender?
//        guard let id = value else {return nil}
//        let user = FirebaseManager.shared.users.value.filter({ id == $0.uid }).first
//        return Sender(id: id, displayName: user?.name ?? "User")
//    }, toJSON: { (value: Sender?) -> String? in
//        // transform value from Sender? to String?
//        return value?.id
//    })
//    
    static let date = TransformOf<Date, String>(fromJSON: { (value: String?) -> Date? in
        // transform value from String? to Date?
        return value?.dateFormat()
    }, toJSON: { (value: Date?) -> String? in
        // transform value from Date? to String?
        return value?.toString(format: "yyyy-MM-dd'T'HH:mm:ssZ")
    })
    
//    static let data = TransformOf<MessageData, [String: Any]>(fromJSON: { (value: [String: Any]?) -> MessageData? in
//        // transform value from [String: Any]? to MyMessageData?
//        guard let type = value?["type"] as? String else {return nil}
//        switch type {
//        case "text":
//            guard let content = value?["text"] as? String else {return nil}
//            return .text(content)
//        case "photo":
//            guard let thumbnail = value?["image"] as? String else {return nil}
//            guard let image = thumbnail.toUIImage() else {return nil}
//            return .photo(image)
//        default:
//            return nil
//        }
//
//    }, toJSON: { (value: MessageData?) -> [String: Any]? in
//        // transform value from MyMessageData? to [String: Any]?
//        guard let value = value else {return nil}
//        switch value {
//        case .text(let text):
//            return ["type": "text", "text": text]
//        case .photoAsync(let url, let image):
//            return ["type": "photoAsync", "thumbnail": image.toBase64() as Any, "original": url.absoluteString]
//        case .photo(let image):
//            return ["type": "photo", "image": image.toBase64() as Any]
//        }
//    })
    
}
