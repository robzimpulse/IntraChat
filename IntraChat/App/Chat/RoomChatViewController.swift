//
//  RoomChatViewController.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxRealm
import RealmSwift
import MessageKit
import MenuItemKit

class RoomChatViewController: MessagesViewController {

    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var room: Room?
    
    var isTyping: Bool = false
    
    var messageList: [Chat] = []
    
    let disposeBag = DisposeBag()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    lazy var customInputBar: MessageInputBar = {
        let newMessageInputBar = MessageInputBar()
        newMessageInputBar.backgroundColor = UIColor.black
        newMessageInputBar.sendButton.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
        newMessageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        newMessageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 16)
        newMessageInputBar.delegate = self
        return newMessageInputBar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleView.widthAnchor.constraint(equalToConstant: 250).isActive = true
        navigationItem.titleView = titleView
        titleLabel.text = room?.name
        subtitleLabel.text = room?.users.flatMap({ (uid) -> String? in
            return FirebaseManager.shared.users.value.filter({ uid == ($0.uid ?? "") }).first?.name
        }).joined(separator: ",")
        if let icon = room?.icon, let url = URL(string: icon) { iconImageView.setImage(url: url) }
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        
        scrollsToBottomOnKeybordBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        
        messageInputBar = customInputBar
        reloadInputViews()
        
        Realm.asyncOpen(callback: { realm, _ in
            guard let realm = realm else {return}
            guard let roomId = self.room?.id else {return}
            Observable
                .changeset(from: realm.objects(Message.self).filter("roomId = '\(roomId)'"))
                .throttle(1.0, scheduler: MainScheduler.instance)
                .subscribe(onNext: { results, changes in
                    self.messageList = results.flatMap({ Chat(message: $0) })
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToBottom(animated: changes != nil)
                })
                .disposed(by: self.disposeBag)
            
        })
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(UIMenuControllerDidHide(_:)),
            name: .UIMenuControllerDidHideMenu,
            object: nil
        )
        
    }
    
    @objc func UIMenuControllerDidHide(_ notification: NSNotification) {
        UIMenuController.shared.menuItems = []
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIMenuControllerDidHideMenu, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        FirebaseManager.shared.roomForMessage.value = room
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        FirebaseManager.shared.roomForMessage.value = nil
    }
    
}

extension RoomChatViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        guard let room = room else {return}
        guard let roomId = room.id else {return}
        inputBar.inputTextView.text = String()
        let message = Message(roomId: roomId, text: text, sender: currentSender().id, date: Date())
        FirebaseManager.shared.create(message: message, completion: { error in
            guard error == nil else {return}
            FirebaseManager.shared.updateLastChat(roomId: roomId, date: Date())
            room.users.filter({ self.currentSender().id != $0 }).forEach({ user in
                FirebaseManager.shared.create(notification: Notification(
                    title: "\(self.currentSender().displayName) @\(room.name ?? "")",
                    body: text,
                    receiver: user
                ))
            })
        })
    }
}

extension RoomChatViewController: MessagesDataSource {
    func currentSender() -> Sender {
        return Sender(
            id: FirebaseManager.shared.currentUser()?.uid ?? "",
            displayName: FirebaseManager.shared.currentUser()?.displayName ?? ""
        )
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    func avatar(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Avatar {
        let senderName = isFromCurrentSender(message: message) ? currentSender().displayName : message.sender.displayName
        let user = FirebaseManager.shared.users.value.filter({ message.sender.id == $0.uid }).first
        return Avatar(image: user?.image(), initials: senderName.initials())
    }
    
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(
            string: message.sentDate.toString(format: "HH:mm"),
            attributes: [
                NSAttributedStringKey.font: UIFont.systemFont(ofSize: 11, weight: .bold),
                NSAttributedStringKey.foregroundColor : UIColor.lightGray
            ]
        )
    }
}

extension RoomChatViewController: MessagesLayoutDelegate {
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat { return 200 }
    
    func avatarPosition(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> AvatarPosition {
        return AvatarPosition(horizontal: .natural, vertical: .messageBottom)
    }
    
    func messagePadding(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        return isFromCurrentSender(message: message) ?
            UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 4):
            UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 30)
    }
    
    func cellTopLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        return isFromCurrentSender(message: message) ?
            .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)) :
            .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
    }
    
    func cellBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        return isFromCurrentSender(message: message) ?
            .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)) :
            .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
    }
    
    func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: messagesCollectionView.bounds.width, height: 10)
    }
}

extension RoomChatViewController: MessagesDisplayDelegate {
    
    // MARK: All Message
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor.lightGray : UIColor.darkGray
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        return .bubbleOutline(.clear)
    }
    
    // MARK: Text Message
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .white
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey : Any] {
        return MessageLabel.defaultAttributes
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date]
    }
    
}

extension RoomChatViewController: MessageCellDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("avatar tapped")
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let index = messagesCollectionView.indexPath(for: cell) else {return}
        switch messageList[index.section].data {
        case .text(let text):
            print(text)
//            UIMenuController.shared.menuItems = [
//                UIMenuItem(title: "Reply", action: { _ in
//                    print("Reply chat for text \(text)")
//                }),
//                UIMenuItem(title: "Forward", action: { _ in
//                    print("Forward chat for \(text)")
//                }),
//                UIMenuItem(title: "Copy", action: { _ in
//                    UIPasteboard.general.string = text
//                }),
//                UIMenuItem(title: "Delete", action: { _ in
//                    print("Delete chat for text \(text)")
//                })
//            ]
            break
        default:
            break
        }
        
//        let cellRect = cell.convert(cell.messageContainerView.frame, to: messagesCollectionView)
//        UIMenuController.shared.setTargetRect(cellRect, in: messagesCollectionView)
//        UIMenuController.shared.setMenuVisible(true, animated: true)
    }

    
    
}
