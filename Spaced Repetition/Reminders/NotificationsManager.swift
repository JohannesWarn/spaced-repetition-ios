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
    
    class var hasActiveReminders: Bool {
        let activeReminders = reminders.filter { $0.isOn }
        return activeReminders.count > 0
    }
    
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
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        } else {
            UIApplication.shared.cancelAllLocalNotifications()
        }
        
        let activeReminders = reminders.filter { $0.isOn }
        
        guard activeReminders.count > 0 else { return }
        
        if #available(iOS 12.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .providesAppNotificationSettings]) { (success, error) in
                print("request authorization: \(success ? "success" : "failure"), error: \(error?.localizedDescription ?? "none")")
            }
        } else {
            let notificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(notificationSettings)
        }
        
        // Find the first day that will have a test
        
        let todayDateComponents = Calendar.current.dateComponents([.era, .year, .month, .day], from: Date())
        let today = Calendar.current.date(from: todayDateComponents)!
        
        let numberOfDaysCompleted = DaysCompletedManager.getCompletedDays().count
        let numberOfDaysSkipped = DaysCompletedManager.getSkippedDays().count
        let completionStateForToday = DaysCompletedManager.completionState(forDay: today)
        
        let numberOfDaysCompletedUntilToday = (numberOfDaysCompleted + numberOfDaysSkipped) - (completionStateForToday == .completed ? 1 : 0)
        
        var day = today
        var dayIndex = numberOfDaysCompletedUntilToday
        var scheduledNotificationForDay = false
        
        // Skip checking today if it has already completed
        if (completionStateForToday == .completed) {
            day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
            dayIndex += 1
        }
        
        for _ in 0...levelsToRepeatAtDay.count {
            let levelsToRepeat = levelsToRepeatAtDay[dayIndex % 64]
            let numberOfCards = ImageManager.numberOfCards(atLevels: levelsToRepeat)
            
            if (numberOfCards > 0) {
                scheduledNotificationForDay = true
                var badgeNumber = 0
                let dayDateComponents = Calendar.current.dateComponents([.era, .year, .month, .day], from: day)
                for reminder in activeReminders {
                    badgeNumber += reminder.badge ? 1 : 0
                    let dateComponents = DateComponents(calendar: Calendar.current,
                                                        era: dayDateComponents.era, year: dayDateComponents.year, month: dayDateComponents.month, day: dayDateComponents.day,
                                                        hour: reminder.hour, minute: reminder.minute)
                    
                    scheduleNotification(
                        title:"Reminder",
                        body: numberOfCards == 1 ? "1 card to review today" : "\(numberOfCards) cards to review today",
                        badge: badgeNumber,
                        withSound: reminder.sound,
                        dateComponents: dateComponents
                    )
                }
                
                break
            }
            
            day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
            dayIndex += 1
        }
        
        // Schedule a notification for the day after that test.
        // “You did not complete yesterday’s test. You won’t recieve any more notifications until you complete it.”
        // If the test was completed this notofication will be cancelled
        
        if scheduledNotificationForDay {
            day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
            let dayDateComponents = Calendar.current.dateComponents([.era, .year, .month, .day], from: day)
            
            let reminder = activeReminders[0]
            let shouldPlaySound = activeReminders[0].sound
            let shouldAddBadge = activeReminders.contains { $0.badge }
            let dateComponents = DateComponents(calendar: Calendar.current,
                                                era: dayDateComponents.era, year: dayDateComponents.year, month: dayDateComponents.month, day: dayDateComponents.day,
                                                hour: reminder.hour, minute: reminder.minute)
            
            scheduleNotification(
                title:"Reminder",
                body: "You did not complete yesterday’s test. You won’t recieve any more reminders until you complete it.",
                badge: shouldAddBadge ? 1 : 0,
                withSound: shouldPlaySound,
                dateComponents: dateComponents
            )
        }
    }
    
    class func scheduleNotification(title: String, body: String, badge: Int, withSound: Bool, dateComponents: DateComponents) {
        guard Date() < dateComponents.date! else { return }

        if #available(iOS 10.0, *) {
            let notificationContent = UNMutableNotificationContent()
            notificationContent.title = title
            notificationContent.body = body
            notificationContent.badge = NSNumber.init(value: badge)
            notificationContent.sound = withSound ? UNNotificationSound.default : nil
            
            let notificationTrigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let notificationRequest = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: notificationTrigger)
            UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: nil)
        } else {
            let notification = UILocalNotification()
            notification.alertTitle = title
            notification.alertBody = body
            notification.applicationIconBadgeNumber = badge
            if withSound {
                notification.soundName = UILocalNotificationDefaultSoundName
            }
            
            notification.fireDate = dateComponents.date!
            UIApplication.shared.scheduleLocalNotification(notification)
        }
    }
    
}
