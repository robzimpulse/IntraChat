//
//  String.swift
//  IntraChat
//
//  Created by admin on 9/1/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit

extension String {
    
    func isVersionLess() -> Bool {
        return UIDevice
            .current
            .systemVersion
            .compare(
                self,
                options: NSString.CompareOptions.numeric
            ) == ComparisonResult.orderedAscending
    }
    
    func initials() -> String {
        return self.capitalized.split(" ").flatMap({ $0.first?.toString }).joined()
    }
    
}
