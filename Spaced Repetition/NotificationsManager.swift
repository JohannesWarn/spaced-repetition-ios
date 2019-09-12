//
//  NotificationsManager.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-13.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit
import UserNotifications

struct Reminder {
    var hour: Int
    var minute: Int
    var badge: Bool
    var sound: Bool
    var isOn: Bool
    
    init(hour: Int, minute: Int, badge: Bool, sound: Bool, isOn: Bool) {
        self.hour = hour
        self.minute = minute
        self.badge = badge
        self.sound = sound
        self.isOn = isOn
    }
    
    init(dictionary: [String: Any]) {
        hour = dictionary["hour"] as! Int
        minute = dictionary["minute"] as! Int
        badge = dictionary["badge"] as! Bool
        sound = dictionary["sound"] as! Bool
        isOn = dictionary["isOn"] as! Bool
    }
    
    func asDictionary() -> [String: Any] {
        return [
            "hour": hour,
            "minute": minute,
            "badge": badge,
            "sound": sound,
            "isOn": isOn
        ]
    }
}
class NotificationsManager: Any {
    
    class var reminders: [Reminder] {
        get {
            if let reminderDictionaries = UserDefaults.standard.array(forKey: "reminders") as? [[String: Any]] {
                return reminderDictionaries.map { (reminderDictionary) -> Reminder in
                    return Reminder(dictionary: reminderDictionary)
                }
            } else {
                return []
            }
        }
    }
    
    class func scheduleNotifications() {
        let activeReminders = reminders.filter { $0.isOn }
        
        if activeReminders.count > 0 {
            if #available(iOS 12.0, *) {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .providesAppNotificationSettings]) { (success, error) in
                    print("request authorization: \(success ? "success" : "failure"), error: \(error?.localizedDescription ?? "none")")
                }
            } else {
                let notificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                UIApplication.shared.registerUserNotificationSettings(notificationSettings)
            }
        }
        
        UIApplication.shared.cancelAllLocalNotifications()
        var badgeNumber = 0
        for reminder in activeReminders {
            if reminder.isOn {
                badgeNumber += reminder.badge ? 1 : 0
                scheduleNotification(forReminder: reminder, badgeNumber: badgeNumber)
            }
        }
    }
    
    class func scheduleNotification(forReminder reminder: Reminder, badgeNumber: Int) {
        let notification = UILocalNotification()
        notification.alertTitle = "Reminder"
        notification.alertBody = "Do today’s test"
        notification.applicationIconBadgeNumber = badgeNumber
        if reminder.sound {
            notification.soundName = UILocalNotificationDefaultSoundName
        }
        //        notification.alertLaunchImage = "TestLaunchScreen"
        
        let now = Date()
        var dateComponents = Calendar.current.dateComponents([.calendar, .year, .month, .day], from: now)
        dateComponents.setValue(reminder.hour, for: .hour)
        dateComponents.setValue(reminder.minute, for: .minute)
        var fireDate = dateComponents.date!
        if fireDate < now {
            fireDate = Calendar.current.date(byAdding: .day, value: 1, to: fireDate)!
        }
        if DaysCompletedManager.completionState(forDay: fireDate) == .completed {
            fireDate = Calendar.current.date(byAdding: .day, value: 1, to: fireDate)!
        }
        notification.fireDate = fireDate
        notification.repeatInterval = .day
        
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
}
