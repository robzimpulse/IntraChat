//
//  UIImage.swift
//  IntraChat
//
//  Created by Robyarta Ruci on 1/13/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit

extension UIImage {

    func thumbnail() -> UIImage {
        return self.resizeWithWidth(50).resizeWithHeight(50)
    }
    
    func resize(width: CGFloat, height: CGFloat) -> UIImage {
        return self.resizeWithWidth(width).resizeWithHeight(height)
    }
    
    func toBase64() -> String? {
        return UIImagePNGRepresentation(self)?.base64EncodedString(options: .lineLength64Characters)
    }
    
}
