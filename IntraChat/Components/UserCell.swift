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
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        accessoryType = selected ? .checkmark : .none
    }
    
    func configure(user: User){
        usernameLabel.text = user.name
        profileImageView.image = nil
        guard let photo = user.photo, let url = URL(string: photo) else {return}
        let filter = AspectScaledToFillSizeCircleFilter(size: CGSize(width: 100, height: 100))
        profileImageView.af_setImage(withURL: url, filter: filter)
    }
    
}
