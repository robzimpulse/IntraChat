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
    
    static let date = TransformOf<Date, String>(fromJSON: { (value: String?) -> Date? in
        // transform value from String? to Date?
        return value?.dateFormat()
    }, toJSON: { (value: Date?) -> String? in
        // transform value from Date? to String?
        return value?.toString(format: "yyyy-MM-dd'T'HH:mm:ssZ")
    })
    
}
