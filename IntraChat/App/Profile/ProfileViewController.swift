//
//  SettingViewController.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import Eureka
import ViewRow
import Lightbox
import ImagePicker
import Firebase
import RPCircularProgress
import TOCropViewController

class ProfileViewController: FormViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    struct formIndex {
        static let email = "email"
        static let image = "image"
        static let name = "name"
        static let phone = "phone"
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = FirebaseManager.shared.currentUser()?.photoURL {
            profileImageView.setImage(url: url )
        }
        
        form
            
            +++ Section()
            <<< ViewRow<UIImageView>(){ row in
                row.tag = formIndex.image
                row.cellSetup { cell, _ in
                    cell.view = self.profileImageView
                    cell.contentView.addSubview(cell.view!)
                    cell.viewRightMargin = 0.0
                    cell.viewLeftMargin = 0.0
                    cell.viewTopMargin = 0.0
                    cell.viewBottomMargin = 0.0
                    cell.height = { return CGFloat(200) }
                    cell.separatorInset.left = 0
                }
                row.onCellSelection({ cell, _ in
                    self.presentVC(self.imagePicker)
                })
            }
            
            +++ Section("Email")
            <<< PhoneRow() { row in
                row.tag = formIndex.email
                row.disabled = true
                row.cellUpdate({ cell, _ in
                    row.value = FirebaseManager.shared.currentUser()?.email
                })
            }
            
            +++ Section("Display Name")
            <<< NameRow() { row in
                row.tag = formIndex.name
                row.onCellHighlightChanged({ cell, _ in
                    guard !row.isHighlighted else {return}
                    guard let value = row.value else {return}
                    FirebaseManager.shared.change(name: value,completion: { error in
                        guard error == nil else {return}
                        row.reload()
                    })
                })
                row.cellUpdate({ cell, _ in
                    row.value = FirebaseManager.shared.currentUser()?.displayName
                })
            }
            
            +++ Section("Phone Number")
            <<< PhoneRow() { row in
                row.tag = formIndex.phone
                row.disabled = true
                row.cellUpdate({ cell, _ in
                    row.value = FirebaseManager.shared.currentUser()?.phoneNumber
                })
            }
        
    }

}

extension ProfileViewController: ImagePickerDelegate {
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

extension ProfileViewController: TOCropViewControllerDelegate {
    func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        cropViewController.dismissVC(completion: nil)
    }
    func cropViewController(_ cropViewController: TOCropViewController, didCropToImage image: UIImage, rect cropRect: CGRect, angle: Int) {
        cropViewController.dismissVC(completion: {
            self.imagePicker.dismissVC(completion: {
                self.profileImageView.addSubview(self.progressView)
                self.progressView.centerInSuperView()
                FirebaseManager.shared.upload(image: image, handleProgress: { snapshot in
                    guard let progress = snapshot.progress?.fractionCompleted.toCGFloat else {return}
                    self.progressView.updateProgress(progress)
                }, completion: { meta, _ in
                    self.progressView.updateProgress(1, animated: true, initialDelay: 0.2, duration: 0.2, completion: {
                        self.progressView.removeFromSuperview()
                        guard let meta = meta else {return}
                        guard let url = meta.downloadURL() else {return}
                        FirebaseManager.shared.change(photoUrl: url, completion: { error in
                            guard error == nil else {return}
                            self.profileImageView.setImage(url: url)
                        })
                    })
                })
            })
        })
        
        
    }
    
}
