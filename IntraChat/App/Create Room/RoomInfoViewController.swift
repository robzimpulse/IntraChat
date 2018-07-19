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
import RxCocoa
import RxSwift
import UserNotifications
import EZSwiftExtensions
import RPCircularProgress
import TOCropViewController

class RoomInfoViewController: UIViewController {
    
    typealias cell = SelectedUserCell
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var roomNameContainer: UIView!
    @IBOutlet weak var roomNameTextField: UITextField!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var users = Variable<[User]>([])
    
    let disposeBag = DisposeBag()
    
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
        photoImageView.addTapGesture(action: { [weak self] _ in
            guard let strongSelf = self else {return}
            strongSelf.presentVC(strongSelf.galleryController)
        })
        
        collectionView.register(cell.nib(), forCellWithReuseIdentifier: cell.identifier())
        
        users.asObservable().bind(
            to: collectionView.rx.items(cellIdentifier: cell.identifier(), cellType: cell.self),
            curriedArgument: { row, user, cell in cell.configure(user: user) }
            ).disposed(by: disposeBag)
        
        collectionView.rx
            .modelSelected(User.self)
            .bind(onNext: { [weak self] user in
                guard let strongSelf = self else {return}
                guard let index = strongSelf.users.value.index(where: { $0.uid == user.uid }) else {return}
                strongSelf.users.value.remove(at: index)
                NotificationCenter.default.post(name: .didChangeSelectedUser, object: strongSelf.users.value)
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func create(_ sender: Any) {
        guard let name = roomNameTextField.text else {return}
        guard let icon = photoImageView.image else {return}
        guard let user = FirebaseManager.shared.currentUser() else {return}
        guard !name.isBlank else {return}
        photoImageView.addSubview(progressView)
        progressView.centerInSuperView()
        FirebaseManager.shared.upload(image: icon, handleProgress: { [weak self] snapshot in
            guard let strongSelf = self else {return}
            guard let progress = snapshot.progress?.fractionCompleted.toCGFloat else {return}
            strongSelf.progressView.updateProgress(progress)
            }, completion: { [weak self] meta, _ in
                guard let strongSelf = self else {return}
                strongSelf.progressView.updateProgress(1, animated: true, initialDelay: 0.2, duration: 0.2, completion: {
                    strongSelf.progressView.removeFromSuperview()
                    guard let meta = meta else {return}
                    guard let icon = meta.downloadURL()?.absoluteString else {return}
                    strongSelf.users.value.append(User(user: user))
                    let room = Room(name: name, icon: icon, users: strongSelf.users.value)
                    FirebaseManager.shared.create(room: room, completion: { error in
                        guard error == nil else {return}
                        strongSelf.navigationController?.dismissVC(completion: nil)
                    })
                })
        })
    }
    
}

extension RoomInfoViewController: GalleryControllerDelegate {
    
    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {}
    
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        Image.resolve(images: images, completion: { [weak self] in
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
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.image = image
        cropViewController.dismissVC(completion: { [weak self] in
            guard let strongSelf = self else {return}
            strongSelf.galleryController.dismissVC(completion: nil)
        })
    }
}
