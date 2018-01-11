//
//  RoomInfoViewController.swift
//  IntraChat
//
//  Created by admin on 9/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import Lightbox
import ImagePicker
import EZSwiftExtensions
import DACircularProgress

class RoomInfoViewController: UIViewController {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var roomNameContainer: UIView!
    @IBOutlet weak var roomNameTextField: UITextField!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    lazy var progressView: DACircularProgressView = {
        let progress = DACircularProgressView(superView: photoImageView)
        progress.progressTintColor = .red
        progress.trackTintColor = .clear
        progress.innerTintColor = .clear
        progress.roundedCorners = 1
        progress.thicknessRatio = 0.05
        return progress
    }()
    
    var users: [User] = []
    
    lazy var imagePicker: ImagePickerController = {
        var config = Configuration()
        config.doneButtonTitle = "Finish"
        config.noImagesTitle = "Sorry! There are no images here!"
        config.recordLocation = true
        config.allowMultiplePhotoSelection = false
        config.allowVideoSelection = false
        let imagePickerController = ImagePickerController(configuration: config)
        imagePickerController.delegate = self
        return imagePickerController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerSwipeBack()
        photoImageView.addTapGesture(action: { _ in
            self.presentVC(self.imagePicker)
        })
//        photoImageView.image = #imageLiteral(resourceName: "icon_group").af_imageAspectScaled(toFill: photoImageView.frame.size).af_imageRoundedIntoCircle()
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
        FirebaseManager.shared.upload(image: icon, handleProgress: { snapshot in
            guard let progress = snapshot.progress?.fractionCompleted.toCGFloat else {return}
            self.progressView.setProgress(progress, animated: true)
        }, completion: { meta, _ in
            self.progressView.removeFromSuperview()
            guard let meta = meta else {return}
            guard let icon = meta.downloadURL()?.absoluteString else {return}
            self.users.append(User(user: user))
            let room = Room(name: name, icon: icon, users: self.users)
            FirebaseManager.shared.create(room: room, completion: { error in
                print(error as Any)
                self.navigationController?.dismissVC(completion: nil)
            })
        })
        
    }
    
}

extension RoomInfoViewController: ImagePickerDelegate {
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        let lightboxImages = images.map { LightboxImage(image: $0) }
        let lightBoxController = LightboxController(images: lightboxImages, startIndex: 0)
        imagePicker.presentVC(lightBoxController)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        photoImageView.image = images.first?.af_imageAspectScaled(toFill: photoImageView.frame.size).af_imageRoundedIntoCircle()
        imagePicker.dismissVC(completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismissVC(completion: nil)
    }
}
