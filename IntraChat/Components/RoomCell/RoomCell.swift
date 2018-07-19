//
//  RoomCell.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit

class RoomCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastChatLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var containerCountView: UIView!
    @IBOutlet weak var countLabel: UILabel!
    
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
        lastChatLabel.text = "Last chat \((room.lastChat ?? Date()).timePassed())"
        if let url = URL(string: room.icon ?? "") { iconImageView.setPersistentImage(url: url) }
        containerCountView.roundView()
        countLabel.text = room.unread.toString
        containerCountView.isHidden = room.unread < 1
    }
    
}
