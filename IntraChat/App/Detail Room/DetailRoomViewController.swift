//
//  DetailRoomViewController.swift
//  IntraChat
//
//  Created by Robyarta Haruli Ruci on 24/01/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import Eureka
import RealmSwift
import AlamofireImage

class DetailRoomViewController: FormViewController {

    var roomId: String?
  
    override var preferredStatusBarStyle: UIStatusBarStyle {
      return .lightContent
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()

        form
            +++ Section()
            <<< LabelRow() { row in
                row.title = "Notification"
            }
            <<< LabelRow() { row in
                row.title = "Shared Media"
            }
      
            +++ Section("0 Members") { section in
                section <<< LabelRow(){ row in
                    row.title = "Invite More User"
                    row.cellUpdate({ cell, _ in
                        cell.accessoryType = .disclosureIndicator
                    })
                    row.onCellSelection({ cell, _ in
                        print("Invite more user")
                    })
                }
                Room.get(completion: { rooms in
                    guard let rooms = rooms else {return}
                    guard let room = rooms.toArray().first(where: { $0.id == self.roomId }) else {return}
                    User.get(completion: { users in
                        guard let users = users else {return}
                        section.header?.title = "\(room.users.count) Members"
                        users.filter("uid IN %@", room.users).toArray().forEach({ user in
                            section <<< LabelRow() { row in
                                row.title = user.name
                                row.cellUpdate({ cell, _ in
                                    cell.accessoryType = .disclosureIndicator
                                    cell.imageView?.setPersistentImage(url: URL(string: user.photo ?? "")!, isRounded: true)
                                })
                                row.onCellSelection({ cell, _ in
                                    print("selected user \(user.name)")
                                })
                            }
                        })
                        section.reload()
                    })
                })
            }
      
            +++ Section()
            <<< ButtonRow(){ row in
                row.title = "Delete and Exit"
                row.cellUpdate({ cell, _ in
                    cell.textLabel?.textColor = UIColor.black
                })
                row.onCellSelection({ cell, _ in
                    let indicator = UIActivityIndicatorView(frame: cell.contentView.frame)
                    indicator.color = UIColor.black
                    indicator.startAnimating()
                    cell.contentView.addSubview(indicator)
                    cell.isUserInteractionEnabled = false
                    cell.textLabel?.alpha = 0
                    Room.get(completion: { rooms in
                        guard let rooms = rooms else {return}
                        guard let room = rooms.toArray().first(where: { $0.id == self.roomId }) else {return}
                        FirebaseManager.shared.exit(room: room, completion: { _ in self.popToRootVC() })
                    })
                })
            }
    }

}
