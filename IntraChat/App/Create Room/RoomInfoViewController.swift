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
    photoImageView.addTapGesture(action: { [unowned self] _ in self.presentVC(self.galleryController) })
    
    collectionView.register(
      UINib(nibName: "SelectedUserCell", bundle: nil),
      forCellWithReuseIdentifier: "SelectedUserCell"
    )
    
    users.asObservable().bind(
      to: collectionView.rx.items(cellIdentifier: "SelectedUserCell", cellType: SelectedUserCell.self),
      curriedArgument: { row, user, cell in cell.configure(user: user) }
      ).disposed(by: disposeBag)
    
    collectionView.rx
      .modelSelected(User.self)
      .bind(onNext: { [unowned self] user in
        guard let index = self.users.value.index(where: { $0.uid == user.uid }) else {return}
        self.users.value.remove(at: index)
        NotificationCenter.default.post(name: .didChangeSelectedUser, object: self.users.value)
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
    FirebaseManager.shared.upload(image: icon, handleProgress: { [unowned self] snapshot in
      guard let progress = snapshot.progress?.fractionCompleted.toCGFloat else {return}
      self.progressView.updateProgress(progress)
    }, completion: { [unowned self] meta, _ in
      self.progressView.updateProgress(1, animated: true, initialDelay: 0.2, duration: 0.2, completion: {
        self.progressView.removeFromSuperview()
        guard let meta = meta else {return}
        guard let icon = meta.downloadURL()?.absoluteString else {return}
        self.users.value.append(User(user: user))
        let room = Room(name: name, icon: icon, users: self.users.value)
        FirebaseManager.shared.create(room: room, completion: { error in
          guard error == nil else {return}
          
          self.navigationController?.dismissVC(completion: nil)
        })
      })
    })
  }
  
}

extension RoomInfoViewController: GalleryControllerDelegate {
  
  func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {}
  
  func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
    Image.resolve(images: images, completion: { [unowned self] in
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
    cropViewController.dismissVC(completion: { [unowned self] in self.galleryController.dismissVC(completion: nil) })
  }
}
