//
//  ImageViewerViewController.swift
//  IntraChat
//
//  Created by admin on 15/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import Hero

private let reuseIdentifier = "Cell"

class ImageViewerViewController: UICollectionViewController {
    
    let imageAsync: [ImageAsync]
    var selectedIndex: IndexPath?
    var panGR = UIPanGestureRecognizer()

    struct ImageAsync {
        var thumbnail: UIImage
        var original: URL
    }
    
    init(imagesAsync: [ImageAsync]) {
        self.imageAsync = imagesAsync
        super.init(nibName: "ImageViewerViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        self.collectionView?.register(ScrollingImageCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        automaticallyAdjustsScrollViewInsets = false
        preferredContentSize = CGSize(width: view.bounds.width, height: view.bounds.width)
        
        view.layoutIfNeeded()
        collectionView?.reloadData()
        if let selectedIndex = selectedIndex {
            collectionView?.scrollToItem(at: selectedIndex, at: .centeredHorizontally, animated: false)
        }

        panGR.addTarget(self, action: #selector(pan))
        panGR.delegate = self
        collectionView?.addGestureRecognizer(panGR)

    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        for v in (collectionView!.visibleCells as? [ScrollingImageCell])! {
            v.topInset = topLayoutGuide.length
        }
    }
    
    @objc func pan() {
        let translation = panGR.translation(in: nil)
        let progress = translation.y / 2 / collectionView!.bounds.height
        switch panGR.state {
        case .began:
            hero_dismissViewController()
        case .changed:
            Hero.shared.update(progress)
            if let cell = collectionView?.visibleCells[0]  as? ScrollingImageCell {
                let currentPos = CGPoint(x: translation.x + view.center.x, y: translation.y + view.center.y)
                Hero.shared.apply(modifiers: [.position(currentPos)], to: cell.imageView)
            }
        default:
            if progress + panGR.velocity(in: nil).y / collectionView!.bounds.height > 0.3 {
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let cell = collectionView?.visibleCells[0] as? ScrollingImageCell,
            cell.scrollView.zoomScale == 1 {
            let v = panGR.velocity(in: nil)
            return v.y > abs(v.x)
        }
        return false
    }
    
}

extension ImageViewerViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageAsync.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let imageCell = (collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? ScrollingImageCell)!
        imageCell.image = imageAsync[indexPath.row].thumbnail
        imageCell.imageView.heroID = "image_\(indexPath.item)"
        imageCell.imageView.heroModifiers = [.position(CGPoint(x:view.bounds.width/2, y:view.bounds.height+view.bounds.width/2)), .scale(0.6), .fade]
        imageCell.topInset = topLayoutGuide.length
        imageCell.imageView.isOpaque = true
        return imageCell
    }
}

extension ImageViewerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.bounds.size
    }
}

