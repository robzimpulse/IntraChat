//
//  UIImageView.swift
//  IntraChat
//
//  Created by admin on 11/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import AlamofireImage

extension UIImageView {
  
  func setPersistentImage(url: URL, isRounded: Bool = true) {
    image = nil
    let filter = AspectScaledToFillSizeCircleFilter(size: self.frame.size)
    af_setImage(withURL: url, filter: isRounded ? filter : nil)
  }
  
}
