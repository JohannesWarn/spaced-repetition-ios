//
//  DaysCompletedManager.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-10.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

let levelsToRepeatAtDay = [[2,1], [3,1], [2,1], [4,1], [2,1], [3,1], [2,1], [1], [2,1], [3,1], [2,1], [5,1], [4,2,1], [3,1], [2,1], [1], [2,1], [3,1], [2,1], [4,1], [2,1], [3,1], [2,1], [6,1], [2,1], [3,1], [2,1], [5,1], [4,2,1], [3,1], [2,1], [1], [2,1], [3,1], [2,1], [4,1], [2,1], [3,1], [2,1], [1], [2,1], [3,1], [2,1], [5,1], [4,2,1], [3,1], [2,1], [1], [2,1], [3,1], [2,1], [4,1], [2,1], [3,1], [2,1], [7,1], [2,1], [3,1], [6,2,1], [5,1], [4,2,1], [3,1], [2,1], [1]]

let dayColors = [
    UIColor.init(rgb: 0xEE4035),
    UIColor.init(rgb: 0xF37737),
    UIColor.init(rgb: 0xFFDB13),
    UIColor.init(rgb: 0x7BC043),
    UIColor.init(rgb: 0x0292CF),
    UIColor.init(rgb: 0x673888),
    UIColor.init(rgb: 0xEF4F91)
]

enum DayCompletionState {
    case nothing
    case completed
    case missed
}

class DaysCompletedManager: NSObject {
    
    class func getCompletedDays() -> [Date] {
        if let completedDays = UserDefaults.standard.array(forKey: "completedDays") as? [Date] {
            return completedDays
        }
        return []
    }
    
    class func levelsForToday() -> [Int] {
        let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day], from: Date())
        let today = Calendar.current.date(from: dateComponents)!
        
        let numberOfDaysCompleted = DaysCompletedManager.getCompletedDays().count
        let completionStateForToday = DaysCompletedManager.completionState(forDay: today)
        let numberOfDaysCompletedUntilToday = numberOfDaysCompleted - (completionStateForToday == .completed ? 1 : 0)
        let levelsToRepeatToday = levelsToRepeatAtDay[numberOfDaysCompletedUntilToday % 64]
        
        return(levelsToRepeatToday)
    }
    
    class func completionStateForToday() -> DayCompletionState {
        let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day], from: Date())
        let today = Calendar.current.date(from: dateComponents)!
        return completionState(forDay: today)
    }
    
    class func completionState(forDay date: Date) -> DayCompletionState {
        let completedDays = getCompletedDays().reversed()
        for completedDay in completedDays {
            if Calendar.current.isDate(completedDay, inSameDayAs: date) {
                return .completed
            }
        }
        if let firstDay = completedDays.last {
            if firstDay < date && !(Calendar.current.isDateInToday(date) || date > Date()) {
                return.missed
            }
        }
        return .nothing
    }
    
    class func setCompletion(forDay date: Date) {
        guard completionState(forDay: date) != .completed else { return }
        var completedDays = getCompletedDays()
        completedDays.append(date)
        UserDefaults.standard.set(completedDays, forKey: "completedDays")
    }
    
}
