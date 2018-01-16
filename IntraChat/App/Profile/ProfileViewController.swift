//
//  SettingViewController.swift
//  IntraChat
//
//  Created by Robyarta on 1/6/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import Eureka
import Gallery
import ViewRow
import Lightbox
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        form.allSections.forEach({ $0.reload() })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                    self.profileImageView.image = nil
                    if let url = FirebaseManager.shared.currentUser()?.photoURL {
                        self.profileImageView.setPersistentImage(url: url )
                    }
                }
                row.onCellSelection({ cell, _ in self.presentVC(self.galleryController) })
            }
            
            +++ Section("Email")
            <<< PhoneRow() { row in
                row.tag = formIndex.email
                row.disabled = true
                row.cellUpdate({ cell, _ in
                    row.value = FirebaseManager.shared.currentUser()?.email
                })
                row.cellSetup({ cell, _ in
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
                row.cellSetup({ cell, _ in
                    row.value = FirebaseManager.shared.currentUser()?.displayName
                })
                row.cellUpdate({ cell, _ in
                    row.value = FirebaseManager.shared.currentUser()?.displayName
                })
            }
            
            +++ Section("Phone Number")
            <<< PhoneRow() { row in
                row.tag = formIndex.phone
                row.disabled = true
                row.cellSetup({ cell, _ in
                    row.value = FirebaseManager.shared.currentUser()?.phoneNumber
                })
                row.cellUpdate({ cell, _ in
                    row.value = FirebaseManager.shared.currentUser()?.phoneNumber
                })
            }
    }
}

extension ProfileViewController: GalleryControllerDelegate {
    
    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {}
    
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        Image.resolve(images: images, completion: {
            guard let image = $0.flatMap({ $0 }).first else {return}
            let cropController = TOCropViewController(image: image)
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

extension ProfileViewController: TOCropViewControllerDelegate {
    func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        cropViewController.dismissVC(completion: nil)
    }
    func cropViewController(_ cropViewController: TOCropViewController, didCropToImage image: UIImage, rect cropRect: CGRect, angle: Int) {
        cropViewController.dismissVC(completion: {
            self.galleryController.dismissVC(completion: {
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
                            self.profileImageView.setPersistentImage(url: url)
                        })
                    })
                })
            })
        })
    }
    
}
