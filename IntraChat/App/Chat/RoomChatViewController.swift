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
import Lightbox
import ImagePicker
import RPCircularProgress
import TOCropViewController


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
    
    lazy var imagePicker: ImagePickerController = {
        var config = Configuration()
        config.doneButtonTitle = "Next"
        config.noImagesTitle = "Sorry! There are no images here!"
        config.recordLocation = true
        config.allowMultiplePhotoSelection = false
        config.allowVideoSelection = false
        let imagePickerController = ImagePickerController(configuration: config)
        imagePickerController.delegate = self
        return imagePickerController
    }()
    
    lazy var progressView: RPCircularProgress = {
        let progress = RPCircularProgress()
        progress.innerTintColor = .clear
        progress.thicknessRatio = 0.1
        progress.progressTintColor = .green
        return progress
    }()
    
    lazy var customInputBar: MessageInputBar = {
        let height: CGFloat = 34
        let newMessageInputBar = MessageInputBar()
        let mediaButton = InputBarButtonItem().configure({
            $0.spacing = .flexible
            $0.image = #imageLiteral(resourceName: "icon_add").resizeWithWidth(height - 14).resizeWithHeight(height - 14)
            $0.setSize(CGSize(width: height, height: height), animated: true)
        }).onTouchUpInside({ _ in
            self.showActionSheet(title: nil, actions: [
                UIAlertAction(title: "Media", style: .default, handler: { _ in
                    self.presentVC(self.imagePicker)
                }),
                UIAlertAction(title: "Document", style: .default, handler: { _ in
                    self.reloadInputViews()
                }),
                UIAlertAction(title: "Location", style: .default, handler: { _ in
                    self.reloadInputViews()
                })
            ], cancel: { self.reloadInputViews() })
        }).onTextViewDidChange({ button, textView in
            let width = textView.text.isBlank ? height : 0
            button.setSize(CGSize(width: width, height: height), animated: true)
            newMessageInputBar.setLeftStackViewWidthConstant(to: width , animated: true)
        })
        newMessageInputBar.isTranslucent = false
        newMessageInputBar.backgroundView.backgroundColor = UIColor.black
        newMessageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        newMessageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 16)
        newMessageInputBar.inputTextView.layer.borderColor = UIColor.white.cgColor
        newMessageInputBar.inputTextView.layer.borderWidth = 1.0
        newMessageInputBar.inputTextView.layer.cornerRadius = height / 2
        newMessageInputBar.inputTextView.layer.masksToBounds = true
        newMessageInputBar.inputTextView.autocorrectionType = .no
        newMessageInputBar.textViewPadding.left = 8
        newMessageInputBar.textViewPadding.right = 8
        newMessageInputBar.setRightStackViewWidthConstant(to: height, animated: true)
        newMessageInputBar.setStackViewItems([newMessageInputBar.sendButton], forStack: .right, animated: true)
        newMessageInputBar.setStackViewItems([mediaButton], forStack: .left, animated: true)
        newMessageInputBar.setLeftStackViewWidthConstant(to: height , animated: true)
        newMessageInputBar.sendButton.setSize(CGSize(width: height, height: height), animated: true)
        newMessageInputBar.sendButton.image = #imageLiteral(resourceName: "icon_send").resizeWithWidth(height - 14).resizeWithHeight(height - 14)
        newMessageInputBar.sendButton.title = nil
        newMessageInputBar.sendButton.backgroundColor = UIColor.darkGray
        newMessageInputBar.sendButton.layer.cornerRadius = height / 2
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

extension RoomChatViewController: ImagePickerDelegate {
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        guard images.count > 0 else {return}
        let lightboxImages = images.map { LightboxImage(image: $0) }
        let lightBoxController = LightboxController(images: lightboxImages, startIndex: 0)
        imagePicker.presentVC(lightBoxController)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        guard let image = images.first else {
            imagePicker.dismissVC(completion: nil)
            return
        }
        let cropViewController = TOCropViewController(croppingStyle: .default, image: image)
        cropViewController.delegate = self
        imagePicker.presentVC(cropViewController)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismissVC(completion: nil)
    }
}

extension RoomChatViewController: TOCropViewControllerDelegate {
    func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        cropViewController.dismissVC(completion: nil)
    }
    func cropViewController(_ cropViewController: TOCropViewController, didCropToImage image: UIImage, rect cropRect: CGRect, angle: Int) {
        cropViewController.dismissVC(completion: {
            self.imagePicker.dismissVC(completion: {
                
//                self.profileImageView.addSubview(self.progressView)
//                self.progressView.centerInSuperView()
//                FirebaseManager.shared.upload(image: image, handleProgress: { snapshot in
//                    guard let progress = snapshot.progress?.fractionCompleted.toCGFloat else {return}
//                    self.progressView.updateProgress(progress)
//                }, completion: { meta, _ in
//                    self.progressView.updateProgress(1, animated: true, initialDelay: 0.2, duration: 0.2, completion: {
//                        self.progressView.removeFromSuperview()
//                        guard let meta = meta else {return}
//                        guard let url = meta.downloadURL() else {return}
//                        FirebaseManager.shared.change(photoUrl: url, completion: { error in
//                            guard error == nil else {return}
//                            self.profileImageView.setImage(url: url)
//                        })
//                    })
//                })
            })
        })
        
        
    }
    
}
