//
//  VideoManager.swift
//  IntraChat
//
//  Created by admin on 16/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import AVKit

class VideoManager: NSObject {
  
  var preset: [String]
  var asset: AVURLAsset
  var thumbnailGenerator: AVAssetImageGenerator
  let time: CMTime = CMTime(seconds: 2, preferredTimescale: 1)
  
  init(url: URL) {
    self.asset = AVURLAsset(url: url)
    self.thumbnailGenerator = AVAssetImageGenerator(asset: self.asset)
    self.preset = AVAssetExportSession.exportPresets(compatibleWith: asset)
  }
  
  func getThumbnail(completion: @escaping ((UIImage) -> Void)){
    DispatchQueue.global().async {
      let OCGImage = try? self.thumbnailGenerator.copyCGImage(at: self.time, actualTime: nil)
      guard let CGImage = OCGImage else {return}
      let image = UIImage(cgImage: CGImage)
      DispatchQueue.main.async { completion(image) }
    }
  }
  
  func convertToMp4(quality: String, handler: @escaping (AVAssetExportSession) -> Void) {
    let output = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("mp4")
    
    if preset.contains(quality) {
      guard let session = AVAssetExportSession( asset: asset, presetName: quality ) else { return }
      session.outputURL = output
      session.outputFileType = .mp4
      session.exportAsynchronously { DispatchQueue.main.async { handler(session) } }
    }
    
  }
}
