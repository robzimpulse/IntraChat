//
//  UIImage.swift
//  IntraChat
//
//  Created by Robyarta Ruci on 1/13/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit

extension UIImage {

    func toBase64() -> String? {
        let image = self.resizeWithWidth(50).resizeWithHeight(50)
        return UIImagePNGRepresentation(image)?.base64EncodedString(options: .lineLength64Characters)
    }
    
}
