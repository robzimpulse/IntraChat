//
//  UserCell.swift
//  IntraChat
//
//  Created by Robyarta on 1/8/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import AlamofireImage

class UserCell: UITableViewCell {
  
  @IBOutlet weak var profileImageView: UIImageView!
  @IBOutlet weak var usernameLabel: UILabel!
  
  var user: User? 
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    accessoryType = selected ? .checkmark : .none
  }
  
  func configure(user: User){
    self.user = user
    usernameLabel.text = user.name
    profileImageView.image = nil
    guard let photo = user.photo, let url = URL(string: photo) else {return}
    profileImageView.setPersistentImage(url: url)
    profileImageView.roundSquareImage()
  }
  
}
