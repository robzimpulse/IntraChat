//
//  RoomCell.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import AlamofireImage

class RoomCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastChatLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    var room: Room?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func configure(room: Room){
        self.room = room
        nameLabel.text = room.name
        lastChatLabel.text = ""
        iconImageView.image = nil
        guard let url = URL(string: room.icon) else {return}
        let filter = AspectScaledToFillSizeCircleFilter(size: CGSize(width: 100, height: 100))
        iconImageView.af_setImage(withURL: url, filter: filter)
    }
    
}