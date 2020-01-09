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
    case skipped
}

class DaysCompletedManager: NSObject {
    
    class func getCompletedDays() -> [Date] {
        if let completedDays = UserDefaults.standard.array(forKey: "completedDays") as? [Date] {
            return completedDays
        }
        return []
    }
    
    class func getSkippedDays() -> [Date] {
        if let skippedDays = UserDefaults.standard.array(forKey: "skippedDays") as? [Date] {
            return skippedDays
        }
        return []
    }
    
    class func levelsForToday() -> [Int] {
        let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day], from: Date())
        let today = Calendar.current.date(from: dateComponents)!
        
        let numberOfDaysCompleted = DaysCompletedManager.getCompletedDays().count
        let numberOfDaysSkipped = DaysCompletedManager.getSkippedDays().count
        let completionStateForToday = DaysCompletedManager.completionState(forDay: today)
        let numberOfDaysCompletedUntilToday = (numberOfDaysCompleted + numberOfDaysSkipped) - (completionStateForToday == .completed ? 1 : 0)
        let levelsToRepeatToday = levelsToRepeatAtDay[numberOfDaysCompletedUntilToday % 64]
        
        return(levelsToRepeatToday)
    }
    
    class func nextDayToRepeatLevel(_ level: Int) -> Date? {
        guard 1 <= level && level <= 7 else { return nil }
        
        let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day], from: Date())
        let today = Calendar.current.date(from: dateComponents)!
        
        let numberOfDaysCompleted = DaysCompletedManager.getCompletedDays().count
        let numberOfDaysSkipped = DaysCompletedManager.getSkippedDays().count
        let completionStateForToday = DaysCompletedManager.completionState(forDay: today)
        let numberOfDaysCompletedUntilToday = (numberOfDaysCompleted + numberOfDaysSkipped) - (completionStateForToday == .completed ? 1 : 0)
        
        if completionStateForToday != .completed {
            if levelsToRepeatAtDay[numberOfDaysCompletedUntilToday % 64].contains(level) {
                return today
            }
        }
        
        var date = today
        var i = 0
        while true {
            i += 1
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            
            if levelsToRepeatAtDay[(numberOfDaysCompletedUntilToday + i) % 64].contains(level) {
                return date
            }
        }
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
        let skippedDays = getSkippedDays().reversed()
        for skippedDay in skippedDays {
            if Calendar.current.isDate(skippedDay, inSameDayAs: date) {
                return .skipped
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
        let currentCompletionState = completionState(forDay: date)
        guard currentCompletionState != .completed else { return }
        guard currentCompletionState != .skipped else { return }
        
        var completedDays = getCompletedDays()
        completedDays.append(date)
        UserDefaults.standard.set(completedDays, forKey: "completedDays")
    }
    
    // autocomplete days were the test would have been finished without a single card
    class func skipDaysWithoutTests() {
        let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day], from: Date())
        let today = Calendar.current.date(from: dateComponents)!
        
        let completedDays = DaysCompletedManager.getCompletedDays()
        guard completedDays.count > 0 else { return }
        
        var day = completedDays.last!
        day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
        
        let numberOfDaysCompleted = completedDays.count
        let numberOfDaysSkipped = DaysCompletedManager.getSkippedDays().count
        var numberOfDaysCompletedUntilDay = numberOfDaysCompleted + numberOfDaysSkipped
        
        while day < today {
            let levelsToRepeat = levelsToRepeatAtDay[numberOfDaysCompletedUntilDay % 64]
            let cardsForDay = ImageManager.deckOfImages(forLevels: levelsToRepeat)
            if cardsForDay.count == 0 {
                setSkip(forDay: day)
                numberOfDaysCompletedUntilDay += 1
                day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
            } else {
                break
            }
        }
        
    }
    
    class func setSkip(forDay date: Date) {
        let currentCompletionState = completionState(forDay: date)
        guard currentCompletionState != .completed else { return }
        guard currentCompletionState != .skipped else { return }
        
        var skippedDays = getSkippedDays()
        skippedDays.append(date)
        UserDefaults.standard.set(skippedDays, forKey: "skippedDays")
    }
    
}
