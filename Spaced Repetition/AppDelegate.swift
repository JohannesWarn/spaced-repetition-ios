//
//  AppDelegate.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-06.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        } else {
            // Fallback on earlier versions
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        DispatchQueue.global(qos: .background).async {
            let cardDeckForToday = ImageManager.deckOfImages(forLevels: DaysCompletedManager.levelsForToday())
            if DaysCompletedManager.completionStateForToday() == .completed || cardDeckForToday.count == 0 {
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
            }
        }
    }
    
    /*
     // The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
     func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
     
     }
     */
    
    // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from application:didFinishLaunchingWithOptions:.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            if let navigationController = window?.rootViewController as? UINavigationController,
                let startViewController = navigationController.viewControllers.first as? StartViewController {
                startViewController.performSegue(withIdentifier: "testNowAnimated", sender: self)
            }
        }
        
        completionHandler()
    }
    
    // The method will be called on the delegate when the application is launched in response to the user's request to view in-app notification settings. Add UNAuthorizationOptionProvidesAppNotificationSettings as an option in requestAuthorizationWithOptions:completionHandler: to add a button to inline notification settings view and the notification settings view in Settings. The notification will be nil when opened from Settings.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        if let navigationController = window?.rootViewController as? UINavigationController,
            let startViewController = navigationController.viewControllers.first as? StartViewController {
            startViewController.performSegue(withIdentifier: "showNotificationSettings", sender: self)
        }
    }
    
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        // the test vc cannot be state restored
        // if state restoration for the test vc is added in the future it should still be disabled when the test is done
        if window?.rootViewController?.presentedViewController?.isKind(of: TestViewController.self) ?? false {
            return false
        }
        return true
    }
    
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }

}

