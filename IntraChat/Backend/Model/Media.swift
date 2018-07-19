//
//  Media.swift
//  IntraChat
//
//  Created by Robyarta Haruli Ruci on 19/07/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import MessageKit

class Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(url: URL? = nil, image: UIImage? = nil, placeholder: UIImage, size: CGSize) {
        self.url = url
        self.image = image
        self.placeholderImage = placeholder
        self.size = size
    }
    
}
