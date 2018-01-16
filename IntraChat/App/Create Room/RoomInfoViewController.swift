//
//  RoomInfoViewController.swift
//  IntraChat
//
//  Created by admin on 9/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import Gallery
import Lightbox
import EZSwiftExtensions
import RPCircularProgress
import TOCropViewController

class RoomInfoViewController: UIViewController {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var roomNameContainer: UIView!
    @IBOutlet weak var roomNameTextField: UITextField!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var users: [User] = []
    
    lazy var progressView: RPCircularProgress = {
        let progress = RPCircularProgress()
        progress.innerTintColor = .clear
        progress.thicknessRatio = 0.1
        progress.progressTintColor = .green
        return progress
    }()
    
    lazy var galleryController: GalleryController = {
        Config.tabsToShow = [.cameraTab, .imageTab]
        Config.Camera.imageLimit = 1
        let galleryController = GalleryController()
        galleryController.delegate = self
        return galleryController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photoImageView.addTapGesture(action: { _ in self.presentVC(self.galleryController) })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        roomNameContainer.roundCorners(.allCorners, radius: 6.0)
        roomNameTextField.roundCorners(.allCorners, radius: 6.0)
    }
    
    @IBAction func create(_ sender: Any) {
        guard let name = roomNameTextField.text else {return}
        guard let icon = photoImageView.image else {return}
        guard let user = FirebaseManager.shared.currentUser() else {return}
        photoImageView.addSubview(progressView)
        progressView.centerInSuperView()
        FirebaseManager.shared.upload(image: icon, handleProgress: { snapshot in
            guard let progress = snapshot.progress?.fractionCompleted.toCGFloat else {return}
            self.progressView.updateProgress(progress)
        }, completion: { meta, _ in
            self.progressView.updateProgress(1, animated: true, initialDelay: 0.2, duration: 0.2, completion: {
                self.progressView.removeFromSuperview()
                guard let meta = meta else {return}
                guard let icon = meta.downloadURL()?.absoluteString else {return}
                self.users.append(User(user: user))
                let room = Room(name: name, icon: icon, users: self.users)
                FirebaseManager.shared.create(room: room, completion: { error in
                    guard error == nil else {return}
                    room.users.filter({ user.uid != $0 }).forEach({
                        FirebaseManager.shared.create(notification: Notification(
                            title: "Room Invitation",
                            body: "You have been invited to room @\(name) by \(user.displayName ?? "")",
                            receiver: $0
                        ))
                    })
                    self.navigationController?.dismissVC(completion: nil)
                })
            })
        })
    }
    
}

extension RoomInfoViewController: GalleryControllerDelegate {
    
    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {}
    
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        Image.resolve(images: images, completion: {
            guard let image = $0.flatMap({ $0 }).first else {return}
            let cropController = TOCropViewController(croppingStyle: .circular, image: image)
            cropController.delegate = self
            controller.presentVC(cropController)
        })
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

extension RoomInfoViewController: TOCropViewControllerDelegate {
    func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        cropViewController.dismissVC(completion: nil)
    }
    func cropViewController(_ cropViewController: TOCropViewController, didCropToCircleImage image: UIImage, rect cropRect: CGRect, angle: Int) {
        self.photoImageView.image = image
        cropViewController.dismissVC(completion: { self.galleryController.dismissVC(completion: nil) })
    }
}
