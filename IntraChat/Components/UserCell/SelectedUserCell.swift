//
//  SelectedUserCell.swift
//  IntraChat
//
//  Created by Robyarta Ruci on 1/20/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit

class SelectedUserCell: UICollectionViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var cancelImageView: UIImageView!
    
    var user: User?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(user: User){
        self.user = user
        profileImageView.image = nil
        guard let photo = user.photo, let url = URL(string: photo) else {return}
        profileImageView.setPersistentImage(url: url)
        profileImageView.roundSquareImage()
        cancelImageView.roundSquareImage()
    }
}