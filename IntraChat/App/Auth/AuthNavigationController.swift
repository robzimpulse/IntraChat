//
//  AuthNavigationController.swift
//  IntraChat
//
//  Created by Robyarta Ruci on 1/13/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import Hero

class AuthNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        isHeroEnabled = true
        heroNavigationAnimationType = .fade
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        heroModalAnimationType = .cover(direction: .up)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        heroModalAnimationType = .cover(direction: .down)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
