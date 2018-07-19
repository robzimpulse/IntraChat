//
//  Location.swift
//  IntraChat
//
//  Created by Robyarta Haruli Ruci on 19/07/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import MapKit
import MessageKit

class Location: LocationItem {
    var location: CLLocation
    var size: CGSize
    
    init(location: CLLocation, size: CGSize) {
        self.location = location
        self.size = size
    }
    
}
