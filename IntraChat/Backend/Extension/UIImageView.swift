//
//  UIImageView.swift
//  IntraChat
//
//  Created by admin on 11/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import Disk
import AlamofireImage

extension UIImageView {

    func setPersistentImage(url: URL) {
        do {
            image = try Disk.retrieve(url.absoluteString, from: .caches, as: UIImage.self)
        }catch {
            let filter = AspectScaledToFillSizeCircleFilter(size: CGSize(width: 100, height: 100))
            af_setImage(withURL: url, filter: filter, completion: { response in
                guard let image = response.value else {return}
                guard !Disk.exists(url.absoluteString, in: .caches) else {return}
                do { try Disk.save(image, to: .caches, as: url.absoluteString) }
                catch { print("error saving image to disk") }
            })
        }
    }
    
}
