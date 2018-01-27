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
  
  func setPersistentImage(url: URL, isRounded: Bool = false) {
    let size = CGSize(width: 30, height: 30)
    let filter = AspectScaledToFillSizeCircleFilter(size: size)
     af_setImage(withURL: url, filter: isRounded ? filter : nil)
  }
  
}
