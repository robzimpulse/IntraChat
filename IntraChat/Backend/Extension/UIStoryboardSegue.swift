//
//  UIStoryboardSegue.swift
//  IntraChat
//
//  Created by Robyarta on 1/8/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit

extension UIStoryboardSegue {
    func safePresentingDestinationVC(){
        if let presentedVC = self.destination.presentedViewController {
            if presentedVC == self.source {
                self.destination.dismiss(animated: false, completion: nil)
            } else {
                self.source.present(self.destination as UIViewController, animated: false, completion: nil)
            }
        }else {
            self.source.present(self.destination as UIViewController, animated: false, completion: nil)
        }
    }
}
