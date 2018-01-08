//
//  DictionaryTransform.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import ObjectMapper

class DictionaryTransform: TransformType {
    typealias Object = [String]
    typealias JSON = [String: Bool]
    
    func transformFromJSON(_ value: Any?) -> Object? {
        guard let v = value as? JSON else { return Object() }
        return Array(v.keys)
    }
    
    func transformToJSON(_ value: Object?) -> JSON? {
        return value?.reduce(JSON(), { (result, string) -> JSON in
            var dict = result
            dict[string] = true
            return dict
        })
    }
}
