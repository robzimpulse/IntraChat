//
//  BaseMappable.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import ObjectMapper
import FirebaseDatabase

extension BaseMappable {
    static var firebaseIdKey : String {
        get { return "FirebaseIdKey" }
    }
    init?(snapshot: DataSnapshot) {
        guard var json = snapshot.value as? [String: Any] else {return nil}
        json[Self.firebaseIdKey] = snapshot.key as Any
        self.init(JSON: json)
    }
}
