//
//  AppDelegate.swift
//  IntraChat
//
//  Created by Robyarta on 1/5/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Firebase
import RealmSwift
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  let disposeBag = DisposeBag()
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    Realm.Configuration.defaultConfiguration = Realm.Configuration(deleteRealmIfMigrationNeeded: true)
    registerPushNotification(application: application)
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

extension AppDelegate: UNUserNotificationCenterDelegate {
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    FirebaseManager.shared.setupApns(token: deviceToken)
    let token = deviceToken.map({ return String(format: "%02.2hhx", $0) }).joined()
    print("device token : \(token)")
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
    FirebaseManager.shared.didReceiveRemoteNotification(userInfo: userInfo)
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    FirebaseManager.shared.didReceiveRemoteNotification(userInfo: userInfo)
    completionHandler(.newData)
  }
  
  func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
    print("didReceive \(notification)")
  }
  
  private func registerPushNotification(application: UIApplication) {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
    } else {
      let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    application.registerForRemoteNotifications()
  }
  
  @available(iOS 10, *)
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("willPresent withCompletionHandler \(notification)")
    completionHandler([.sound,.alert,.badge])
  }
  
  @available(iOS 10, *)
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    print("didReceive withCompletionHandler \(response)")
    completionHandler()
  }
}

