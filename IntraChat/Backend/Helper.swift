//
//  Helper.swift
//  IntraChat
//
//  Created by Robyarta Ruci on 04/02/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit

class Helper: NSObject {

  static func getTitleView(title: String?, subtitle: String?) -> UIView {
    let titleLabel = UILabel(frame: CGRect(x:0, y:-5, width:0, height:0))
    
    titleLabel.backgroundColor = UIColor.clear
    titleLabel.textColor = .white
    titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
    titleLabel.text = title
    titleLabel.sizeToFit()
    
    let subtitleLabel = UILabel(frame: CGRect(x:0, y:18, width:0, height:0))
    subtitleLabel.backgroundColor = UIColor.clear
    subtitleLabel.textColor = .lightGray
    subtitleLabel.font = UIFont.systemFont(ofSize: 12)
    subtitleLabel.text = subtitle
    subtitleLabel.sizeToFit()
    
    let width = max(titleLabel.frame.size.width, subtitleLabel.frame.size.width)
    let titleView = UIView(frame: CGRect(x:0, y:0, width:width, height:30))
    titleView.addSubview(titleLabel)
    titleView.addSubview(subtitleLabel)
    
    let widthDiff = subtitleLabel.frame.size.width - titleLabel.frame.size.width
    let newX = widthDiff / 2
    if widthDiff < 0 { subtitleLabel.frame.origin.x = abs(newX) }
    else { titleLabel.frame.origin.x = newX }
    return titleView
  }
  
}
