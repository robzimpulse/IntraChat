//
//  String.swift
//  IntraChat
//
//  Created by admin on 9/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit

extension String {
  
  func toUIImage() -> UIImage? {
    guard let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) else {return nil}
    return UIImage(data: data)
  }
  
  func dateFormat(from: String = "yyyy-MM-dd'T'HH:mm:ssZ", to: String) -> String {
    guard let validDate = dateFormat(from: from) else { return self }
    return validDate.toString(format: to)
  }
  
  func dateFormat(from: String = "yyyy-MM-dd'T'HH:mm:ssZ") -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = from
    return dateFormatter.date(from: self)
  }
  
  func initials() -> String {
    return self.capitalized.split(" ").flatMap({ $0.first?.toString }).joined()
  }
  
  func isVersionLess() -> Bool {
    return UIDevice
      .current
      .systemVersion
      .compare(
        self,
        options: NSString.CompareOptions.numeric
      ) == ComparisonResult.orderedAscending
  }
  
}
