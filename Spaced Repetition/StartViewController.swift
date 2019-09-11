//
//  StartViewController.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-06.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

class StartViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var daysStackView: UIStackView!
    var dayViews: [DayView]! = []
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var testButton: FancyButton!
    @IBOutlet weak var testDetailLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for view in daysStackView.subviews {
            let dayView: DayView = UINib.init(nibName: "DayView", bundle: nil).instantiate(withOwner: self, options: nil).first as! DayView
            dayView.frame = view.bounds
            view.addSubview(dayView)
            
            dayViews.append(dayView)
        }
        
        updateCalendarView()
        
        testButton.addTarget(self, action:#selector(forwardTestButtonTouchDownEvent), for:.touchDown)
        testButton.addTarget(self, action:#selector(forwardTestButtonTouchDownRepeatEvent), for:.touchDownRepeat)
        testButton.addTarget(self, action:#selector(forwardTestButtonTouchDragInsideEvent), for:.touchDragInside)
        testButton.addTarget(self, action:#selector(forwardTestButtonTouchDragOutsideEvent), for:.touchDragOutside)
        testButton.addTarget(self, action:#selector(forwardTestButtonTouchDragEnterEvent), for:.touchDragEnter)
        testButton.addTarget(self, action:#selector(forwardTestButtonTouchDragExitEvent), for:.touchDragExit)
        testButton.addTarget(self, action:#selector(forwardTestButtonTouchUpInsideEvent), for:.touchUpInside)
        testButton.addTarget(self, action:#selector(forwardTestButtonTouchUpOutsideEvent), for:.touchUpOutside)
        testButton.addTarget(self, action:#selector(forwardTestButtonTouchCancelEvent), for:.touchCancel)
        testButton.addTarget(self, action:#selector(forwardTestButtonValueChangedEvent), for:.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
        tableView.reloadSections([0], with: .none)
        
        updateCalendarView()
    }
    
    func updateCalendarView() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        
        let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day], from: Date())
        let today = Calendar.current.date(from: dateComponents)!
        let firstWeekday = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let lastWeekday = Calendar.current.date(byAdding: .day, value: 6, to: firstWeekday)!

        let numberOfDaysCompleted = DaysCompletedManager.getCompletedDays().count
        let completionStateForToday = DaysCompletedManager.completionState(forDay: today)
        let numberOfDaysCompletedUntilToday = numberOfDaysCompleted - (completionStateForToday == .completed ? 1 : 0)
        let levelsToRepeatToday = levelsToRepeatAtDay[numberOfDaysCompletedUntilToday % 64]
        var levelStrings = levelsToRepeatToday.map { (level) -> String in
            return String(level)
        }
        let lastLevelString = levelStrings.popLast()!
        if levelStrings.count > 0 {
            testDetailLabel.text = "Levels \([levelStrings.joined(separator: ", "), lastLevelString].joined(separator: " and "))"
        } else {
            testDetailLabel.text = "Level \(lastLevelString)"
        }
        if completionStateForToday == .completed {
            testButton.superview?.isHidden = true
            tableView.contentInset.bottom = 0
        } else {
            testButton.superview?.isHidden = false
            tableView.contentInset.bottom = 108
        }
        
        var day = firstWeekday
        var todayIndex: Int = 0
        var i = 0
        for dayView in dayViews {
            
            let isToday =  Calendar.current.isDate(today, inSameDayAs: day)
            dayView.dayLabel.textColor = isToday ? view.tintColor : UIColor(white: 0.5, alpha: 1.0)
            dayView.dayLabel.font = UIFont.systemFont(ofSize: dayView.dayLabel.font.pointSize, weight: (isToday ? .bold : .medium))
            dayView.dayLabel.text = String(dateFormatter.string(from: day).capitalized.first!)
            
            let completionState = DaysCompletedManager.completionState(forDay: day)
            switch completionState {
            case .completed:
                dayView.circleImageView.image = UIImage(named: "win circle")
            case .missed:
                dayView.circleImageView.image = UIImage(named: "error circle")
            default:
                dayView.circleImageView.image = UIImage(named: "empty circle")
            }
            
            for dotLayer in dayView.dotLayers {
                dotLayer.isHidden = true
            }
            
            if today == day {
                todayIndex = i
                let numberOfDaysCompletedUntilDay = numberOfDaysCompletedUntilToday
                let levelsToRepeat = levelsToRepeatAtDay[numberOfDaysCompletedUntilDay % 64]
                for (index, dotLayer) in dayView.dotLayers.enumerated() {
                    dotLayer.isHidden = !levelsToRepeat.contains(index + 1)
                }
            }
            
            i += 1
            day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
        }
        
        day = today
        i = todayIndex
        var numberOfDaysCompletedUntilDay = numberOfDaysCompletedUntilToday
        while day > firstWeekday {
            day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
            i -= 1
            
            if DaysCompletedManager.completionState(forDay: day) == .completed {
                numberOfDaysCompletedUntilDay -= 1
                
                let levelsToRepeat = levelsToRepeatAtDay[numberOfDaysCompletedUntilDay % 64]
                for (index, dotLayer) in dayViews[i].dotLayers.enumerated() {
                    dotLayer.isHidden = !levelsToRepeat.contains(index + 1)
                }
            }
        }
        
        day = today
        i = todayIndex
        numberOfDaysCompletedUntilDay = numberOfDaysCompletedUntilToday
        while day < lastWeekday {
            day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
            i += 1
            numberOfDaysCompletedUntilDay += 1

            let levelsToRepeat = levelsToRepeatAtDay[numberOfDaysCompletedUntilDay % 64]
            for (index, dotLayer) in dayViews[i].dotLayers.enumerated() {
                dotLayer.isHidden = !levelsToRepeat.contains(index + 1)
            }
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "level cell", for: indexPath)
        
        if indexPath.row < 7 {
            cell.imageView?.image = UIImage.imageWithCircle(radius: 4.0, color: dayColors[indexPath.row])
            cell.textLabel?.text = "Level \(indexPath.row + 1)"
        } else {
            cell.imageView?.image = nil
            cell.textLabel?.text = "Finished Cards"
        }
        
        let numberOfCardsAtLevel = ImageManager.numberOfCards(atLevel: indexPath.row + 1)
        if numberOfCardsAtLevel == 1 {
            cell.detailTextLabel?.text = "\(ImageManager.numberOfCards(atLevel: indexPath.row + 1)) card"
        } else {
            cell.detailTextLabel?.text = "\(ImageManager.numberOfCards(atLevel: indexPath.row + 1)) cards"
        }
        
        return cell
    }
    
    @objc func forwardTestButtonTouchDownEvent() { forwardTestButtonEvent(.touchDown) }
    @objc func forwardTestButtonTouchDownRepeatEvent() { forwardTestButtonEvent(.touchDownRepeat) }
    @objc func forwardTestButtonTouchDragInsideEvent() { forwardTestButtonEvent(.touchDragInside) }
    @objc func forwardTestButtonTouchDragOutsideEvent() { forwardTestButtonEvent(.touchDragOutside) }
    @objc func forwardTestButtonTouchDragEnterEvent() { forwardTestButtonEvent(.touchDragEnter) }
    @objc func forwardTestButtonTouchDragExitEvent() { forwardTestButtonEvent(.touchDragExit) }
    @objc func forwardTestButtonTouchUpInsideEvent() { forwardTestButtonEvent(.touchUpInside) }
    @objc func forwardTestButtonTouchUpOutsideEvent() { forwardTestButtonEvent(.touchUpOutside) }
    @objc func forwardTestButtonTouchCancelEvent() { forwardTestButtonEvent(.touchCancel) }
    @objc func forwardTestButtonValueChangedEvent() { forwardTestButtonEvent(.valueChanged) }
    
    func forwardTestButtonEvent(_ event: UIControl.Event) {
        let alpha: CGFloat
        
        switch event {
        case .touchDown, .touchDownRepeat, .touchDragInside, .touchDragEnter:
            alpha = 0.2
        default:
            alpha = 1.0
        }
        
        let duration: TimeInterval
        switch event {
        case .touchDown, .touchDownRepeat:
            duration = 0.0
        default:
            duration = 0.3
        }
        
        UIView.animate(withDuration: duration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
            self.testDetailLabel.alpha = alpha
        }, completion: nil)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let levelCollectionViewController = segue.destination as? LevelCollectionViewController {
            if let selectedRow = tableView.indexPathForSelectedRow?.row {
                levelCollectionViewController.level = selectedRow + 1
            }
        } else if let testViewController = segue.destination as? TestViewController {
            testViewController.levels = DaysCompletedManager.levelsForToday()
        }
    }

}
