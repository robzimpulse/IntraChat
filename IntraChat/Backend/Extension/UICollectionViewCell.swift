//
//  UICollectionViewCell.swift
//  IntraChat
//
//  Created by Robyarta Ruci on 03/02/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit

extension UICollectionViewCell {
  
  static func nib() -> UINib {
    return UINib(nibName: className, bundle: nil)
  }
  
  static func identifier() -> String {
    return className
  }
  
}
