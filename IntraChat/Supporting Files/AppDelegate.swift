//
//  AppDelegate.swift
//  IntraChat
//
//  Created by Robyarta on 1/5/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        FirebaseManager.shared.applicationWillResignActive()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        FirebaseManager.shared.applicationDidBecomeActive()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        FirebaseManager.shared.applicationWillTerminate()
    }

}

