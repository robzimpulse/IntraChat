//
//  RoomChatViewController.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import Hero
import Disk
import UIKit
import AVKit
import RxSwift
import RxCocoa
import RxRealm
import Gallery
import Lightbox
import RealmSwift
import MessageKit
import MenuItemKit
import LocationPicker
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
    
    override var inputAccessoryView: UIView? {
        return (presentedViewController == nil) ? messageInputBar : nil
    }
    
    lazy var locationPicker: UINavigationController = {
        let locationPicker = LocationPickerViewController()
        locationPicker.useCurrentLocationAsHint = true
        locationPicker.searchBarPlaceholder = "Search or Enter an address"
        locationPicker.searchHistoryLabel = "Previously searched"
        locationPicker.completion = { location in
            guard let room = self.room else {return}
            guard let roomId = room.id else {return}
            guard let location = location else {return}
            let message = Message(roomId: roomId, location: location.location, sender: self.currentSender().id, date: Date())
            FirebaseManager.shared.create(message: message, completion: { error, _ in
                guard error == nil else {return}
                FirebaseManager.shared.updateLastChatTimeStamp(roomId: roomId, date: Date())
                room.users.filter({ self.currentSender().id != $0 }).forEach({ user in
                    FirebaseManager.shared.create(notification: Notification(
                        title: "\(self.currentSender().displayName) @\(room.name ?? "")",
                        body: "📍Location",
                        receiver: user
                    ))
                })
            })
        }
        let picker = UINavigationController(rootViewController: locationPicker)
        return picker
    }()
    
    lazy var galleryController: GalleryController = {
        Config.tabsToShow = [.cameraTab, .imageTab, .videoTab]
        Config.Camera.imageLimit = 1
        let galleryController = GalleryController()
        galleryController.delegate = self
        return galleryController
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
                    self.presentVC(self.galleryController)
                }),
                UIAlertAction(title: "Document", style: .default, handler: { _ in
                    self.reloadInputViews()
                }),
                UIAlertAction(title: "Location", style: .default, handler: { _ in
                    self.presentVC(self.locationPicker)
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadInputViews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleView.widthAnchor.constraint(equalToConstant: 250).isActive = true
        navigationItem.titleView = titleView
        titleLabel.text = room?.name
        User.get(completion: { users in
            guard let users = users else {return}
            self.subtitleLabel.text = self.room?.users.flatMap({ (uid) -> String? in
                return users.filter("uid = '\(uid)'").first?.name
            }).joined(separator: ",")
        })
        if let icon = room?.icon, let url = URL(string: icon) { iconImageView.setPersistentImage(url: url) }
        
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
        
    }
    
}

extension RoomChatViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        guard let room = room else {return}
        guard let roomId = room.id else {return}
        inputBar.inputTextView.text = String()
        let message = Message(roomId: roomId, text: text, sender: currentSender().id, date: Date())
        FirebaseManager.shared.create(message: message, completion: { error, _ in
            guard error == nil else {return}
            FirebaseManager.shared.updateLastChatTimeStamp(roomId: roomId, date: Date())
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
        let image = FirebaseManager.shared.images[message.sender.id]?.image
        return Avatar(image: image, initials: message.sender.displayName.initials())
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
        let chat = messageList[index.section]
        chat.getMessage(completion: { message in
            guard let message = message else {return}
            switch chat.data {
            case .text(let text):
                print(text)
                break
            case .photo(_):
                guard let imageUrl = message.contentImageUrl, let url = URL(string: imageUrl) else {return}
                let lightboxController = LightboxController(images: [LightboxImage(imageURL: url)], startIndex: 0)
                self.presentVC(lightboxController)
                break
            case .video(file: let url, thumbnail: let thumbnail):
                let lightboxImage = LightboxImage(image: thumbnail, text: "", videoURL: url)
                let lightboxController = LightboxController(images: [lightboxImage], startIndex: 0)
                self.presentVC(lightboxController)
            case .location(let location):
                self.pushVC(LocationViewController(senderName: chat.sender.displayName,location: location))
                print(location.coordinate.latitude, location.coordinate.longitude)
                break
            default:
                break
            }
        })
    }

}

extension RoomChatViewController: GalleryControllerDelegate {
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        Image.resolve(images: images, completion: {
            guard let image = $0.flatMap({ $0 }).first else {return}
            let cropViewController = TOCropViewController(image: image)
            cropViewController.delegate = self
            controller.presentVC(cropViewController)
        })
    }
    
    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        VideoEditor().edit(video: video) { _, url in
            guard let url = url else {return}
            DispatchQueue.main.async {
                guard UIVideoEditorController.canEditVideo(atPath: url.path) else {return}
                let editorController = UIVideoEditorController()
                editorController.videoPath = url.path
                editorController.delegate = self
                editorController.videoQuality = .typeHigh
                controller.presentVC(editorController)
            }
        }
    }
    
    func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        Image.resolve(images: images, completion: {
            let lightboxImages = $0.flatMap({ $0 }).map({ LightboxImage(image: $0) })
            let lightboxController = LightboxController(images: lightboxImages, startIndex: 0)
            controller.presentVC(lightboxController)
        })
    }
    
    func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismissVC(completion: nil)
    }
    
}

extension RoomChatViewController: UINavigationControllerDelegate, UIVideoEditorControllerDelegate {
    func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
        editor.dismissVC(completion: nil)
    }
    func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
        editor.dismissVC(completion: { print(error) })
    }
    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        editor.dismissVC(completion: {
            self.galleryController.dismissVC(completion: {
                let manager = VideoManager(url: URL(fileURLWithPath: editedVideoPath))
                
                manager.getThumbnail(completion: { image in
                    manager.convertToMp4(quality: AVAssetExportPresetHighestQuality, handler: { session in
                        switch session.status {
                        case .completed:
                            guard let room = self.room else {return}
                            guard let roomId = room.id else {return}
                            guard let convertedUrl = session.outputURL else {return}
                            let message = Message(
                                roomId: roomId,
                                thumbnail: image,
                                video: convertedUrl,
                                sender: self.currentSender().id,
                                date: Date()
                            )
                            FirebaseManager.shared.create(message: message, completion: { error, ref in
                                guard let ref = ref else {return}
                                FirebaseManager.shared.updateLastChatTimeStamp(roomId: roomId, date: Date())
                                FirebaseManager.shared.upload(video: convertedUrl, completion: { meta, _ in
                                    message.messageId = ref.key
                                    message.contentVideoUrl = meta?.downloadURL()?.absoluteString
                                    FirebaseManager.shared.update(message: message)
                                    FirebaseManager.shared.updateLastChatTimeStamp(roomId: roomId, date: Date())
                                })
                                room.users.filter({ self.currentSender().id != $0 }).forEach({ user in
                                    FirebaseManager.shared.create(notification: Notification(
                                        title: "\(self.currentSender().displayName) @\(room.name ?? "")",
                                        body: "📷 Video",
                                        receiver: user
                                    ))
                                })
                            })
                            break
                        case .exporting:
                            print("exporting: \(session.progress)")
                            break
                        case .failed:
                            print("failed: \(session.error as Any)")
                            break
                        case .cancelled:
                            print("cancelled")
                            break
                        case .waiting:
                            print("waiting")
                            break
                        case .unknown:
                            print("unknown")
                        }
                        
                    })
                })
            })
        })
    }
}

extension RoomChatViewController: TOCropViewControllerDelegate {
    func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        cropViewController.dismissVC(completion: nil)
    }
    func cropViewController(_ cropViewController: TOCropViewController, didCropToImage image: UIImage, rect cropRect: CGRect, angle: Int) {
        cropViewController.dismissVC(completion: {
            self.galleryController.dismissVC(completion: {
                guard let room = self.room else {return}
                guard let roomId = room.id else {return}
                let message = Message(roomId: roomId, image: image, sender: self.currentSender().id, date: Date())
                FirebaseManager.shared.create(message: message, completion: { error, ref in
                    guard let ref = ref else {return}
                    FirebaseManager.shared.updateLastChatTimeStamp(roomId: roomId, date: Date())
                    FirebaseManager.shared.upload(image: image, completion: { meta, _ in
                        message.messageId = ref.key
                        message.contentImageUrl = meta?.downloadURL()?.absoluteString
                        FirebaseManager.shared.update(message: message)
                        FirebaseManager.shared.updateLastChatTimeStamp(roomId: roomId, date: Date())
                    })
                    room.users.filter({ self.currentSender().id != $0 }).forEach({ user in
                        FirebaseManager.shared.create(notification: Notification(
                            title: "\(self.currentSender().displayName) @\(room.name ?? "")",
                            body: "📷 Image",
                            receiver: user
                        ))
                    })
                })
            })
        })
    }
}

