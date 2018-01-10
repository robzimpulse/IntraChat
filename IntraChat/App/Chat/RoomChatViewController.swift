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
import MessageKit

class RoomChatViewController: MessagesViewController {

    var room: Room?
    
    var isTyping: Bool = false
    
    var messageList: [Message] = []
    
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

        registerSwipeBack()
        
        navigationItem.title = room?.name
        
        if "11.0".isVersionLess() { automaticallyAdjustsScrollViewInsets = true }
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        
        scrollsToBottomOnKeybordBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        
        messageInputBar = customInputBar
        reloadInputViews()
        
        FirebaseManager.shared.messages.asObservable().scan([Message](), accumulator: { old, new in
            guard let last = new.last else {return []}
            return [last]
        }).bind(onNext: {
            guard let message = $0.first else {return}
            self.messageList.append(message)
        }).disposed(by: disposeBag)
        
        FirebaseManager.shared.messages.asObservable()
            .throttle(1, scheduler: MainScheduler.instance)
            .bind(onNext: { _ in
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToBottom(animated: true)
            })
            .disposed(by: disposeBag)
        
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
        let message = Message(roomId: roomId, text: text, sender: currentSender(), messageId: UUID().uuidString, date: Date())
        FirebaseManager.shared.create(message: message, completion: { error in
            guard error == nil else {return}
            FirebaseManager.shared.updateLastChat(roomId: roomId, date: message.sentDate)
            guard let users = room.users else {return}
            users.filter({ self.currentSender().id != $0 }).forEach({ user in
                let notification = Notification(
                    title: "\(self.currentSender().displayName) @\(room.name ?? "")",
                    body: text,
                    receiver: user
                )
                FirebaseManager.shared.create(notification: notification)
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
        return isFromCurrentSender(message: message) ? .bubbleTail(.bottomRight, .curved) : .bubbleTail(.bottomLeft, .curved)
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
        print("message tapped")
    }
    
}
