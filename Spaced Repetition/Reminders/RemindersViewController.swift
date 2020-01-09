//
//  RemindersViewController.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-11.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit
import UserNotifications

class RemindersViewController: UITableViewController {

    var reminders: [Reminder]!
    let defaultReminders = [
        Reminder(hour: 7, minute: 30, badge: true, sound: false, isOn: false),
        Reminder(hour: 13, minute: 0, badge: false, sound: false, isOn: false),
        Reminder(hour: 21, minute: 0, badge: false, sound: false, isOn: false)
    ]
    
    @IBOutlet var warningHeader: UIView!
    @IBOutlet var warningButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.contentInset.top = 0.0
        navigationItem.rightBarButtonItem = editButtonItem
        
        if let reminderDictionaries = UserDefaults.standard.array(forKey: "reminders") as? [[String: Any]] {
            reminders = reminderDictionaries.map { (reminderDictionary) -> Reminder in
                return Reminder(dictionary: reminderDictionary)
            }
        } else {
            reminders = defaultReminders
        }
        
        scheduleNotifications()
        
        tableView.tableHeaderView = nil
        showWarningHeaderIfNeeded()
        NotificationCenter.default.addObserver(
            self, selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
    }
    
    @objc func applicationWillEnterForeground() {
        showWarningHeaderIfNeeded()
    }
    
    @objc func applicationDidBecomeActive() {
        showWarningHeaderIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        isEditing = false
    }
    
    // this method is called before setEditing, so we can use it to detect if setEditing iscalled in response to a swipe
    var isShowingSwipeAction: Bool = false
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        isShowingSwipeAction = true
        return nil
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        for cell in tableView.visibleCells {
            if let reminderCell = cell as? ReminderCell {
                reminderCell.showsDisclosureIndicatorContainer = editing && !isShowingSwipeAction
            }
        }
        
        isShowingSwipeAction = false
    }
    
    func showWarningHeaderIfNeeded() {
        func showWarningHeaderFor(_ bannersDisabled: Bool, _ soundsDisabled: Bool, _ badgesDisabled: Bool) {
            let notificationsDisabled = bannersDisabled && soundsDisabled && badgesDisabled
            
            let activeReminders = reminders.filter { $0.isOn }
            let hasActiveReminders = activeReminders.count > 0
            let hasActiveReminderWithSound = activeReminders.reduce(false) { $0 || $1.sound }
            let hasActiveReminderWithBadge = activeReminders.reduce(false) { $0 || $1.badge }
            
            if hasActiveReminders && notificationsDisabled {
                UIView.performWithoutAnimation {
                    warningButton.setTitle("You have disabled notifications in Settings", for: .normal)
                    warningButton.layoutSubviews()
                }
                tableView.tableHeaderView = warningHeader
            } else if hasActiveReminders && bannersDisabled {
                UIView.performWithoutAnimation {
                    warningButton.setTitle("You have disabled banners in Settings", for: .normal)
                    warningButton.layoutSubviews()
                }
                tableView.tableHeaderView = warningHeader
            } else if hasActiveReminderWithSound && soundsDisabled {
                UIView.performWithoutAnimation {
                    warningButton.setTitle("You have disabled sounds in Settings", for: .normal)
                    warningButton.layoutSubviews()
                }
                tableView.tableHeaderView = warningHeader
            } else if hasActiveReminderWithBadge && badgesDisabled {
                UIView.performWithoutAnimation {
                    warningButton.setTitle("You have disabled badges in Settings", for: .normal)
                    warningButton.layoutSubviews()
                }
                tableView.tableHeaderView = warningHeader
            } else {
                tableView.tableHeaderView = nil
            }
        }
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                if settings.authorizationStatus == .notDetermined {
                    DispatchQueue.main.async {
                        self.tableView.tableHeaderView = nil
                    }
                    return
                }
                
                let bannersDisabled = (settings.alertSetting == .disabled)
                let soundsDisabled = (settings.soundSetting == .disabled)
                let badgesDisabled = (settings.badgeSetting == .disabled)
                
                DispatchQueue.main.async {
                    showWarningHeaderFor(bannersDisabled, soundsDisabled, badgesDisabled)
                }
            }
        } else {
            guard let currentUserNotificationSettings = UIApplication.shared.currentUserNotificationSettings else {
                tableView.tableHeaderView = nil
                return
            }
            
            let bannersDisabled = !currentUserNotificationSettings.types.contains(.alert)
            let soundsDisabled = !currentUserNotificationSettings.types.contains(.sound)
            let badgesDisabled = !currentUserNotificationSettings.types.contains(.badge)
            
            showWarningHeaderFor(bannersDisabled, soundsDisabled, badgesDisabled)
        }
    }
    
    @IBAction func openNotificationsSettings(_ sender: Any) {
        UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
    }
    
    func sortReminders() {
        reminders = reminders.sorted(by: { (reminderA, reminderB) -> Bool in
            if reminderA.hour == reminderB.hour {
                return reminderA.minute < reminderB.minute
            }
            return reminderA.hour < reminderB.hour
        })
    }

    @objc func toggleReminder(_ sender: UISwitch) {
        if let cell = sender.superview as? ReminderCell,
            let cellIndexPath = tableView.indexPath(for: cell) {
            reminders[cellIndexPath.row].isOn = sender.isOn
            configure(cell: cell, at: cellIndexPath)
            scheduleNotifications()
            self.showWarningHeaderIfNeeded()
        }
    }
    
    func scheduleNotifications() {
        let reminderDictionaries = reminders.map { (reminder) -> [String: Any] in
            return reminder.asDictionary()
        }
        UserDefaults.standard.set(reminderDictionaries, forKey: "reminders")
        NotificationsManager.scheduleNotifications()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reminderCell", for: indexPath) as! ReminderCell
        configure(cell: cell, at: indexPath)
        return cell
    }

    func configure(cell: ReminderCell, at indexPath: IndexPath) {
        let reminder = reminders[indexPath.row]
        
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.hour = reminder.hour
        dateComponents.minute = reminder.minute
        
        cell.switchView.removeTarget(self, action: #selector(toggleReminder(_:)), for: .valueChanged)
        cell.switchView.addTarget(self, action: #selector(toggleReminder(_:)), for: .valueChanged)
        
        if let date = Calendar.current.date(from: dateComponents) {
            let timeString = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
            let timeStringComponents = timeString.split(separator: " ", maxSplits: 1)
            cell.timeLabel.text = String(timeStringComponents.first!)
            cell.periodLabel.text = timeStringComponents.count == 2 ? String(timeStringComponents.last!) : nil
        } else {
            cell.timeLabel.text = "Error"
        }
        
        var typeStrings = ["Banner"]
        if reminder.badge { typeStrings.append("Badge") }
        if reminder.sound { typeStrings.append("Sound") }
        cell.typeLabel.text = typeStrings.joined(separator: ", ")
        
        cell.switchView.isOn = reminder.isOn

        let color = labelTextColor(forState: reminder.isOn)
        cell.timeLabel.textColor = color
        cell.periodLabel.textColor = color
        cell.typeLabel.textColor = color
        
        cell.showsDisclosureIndicatorContainer = isEditing
    }

    func labelTextColor(forState state: Bool) -> UIColor {
        if #available(iOS 13.0, *) {
            return state ? .label : .secondaryLabel
        } else {
            return state ? .black : UIColor(white: 0.5, alpha: 1.0)
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            reminders.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            scheduleNotifications()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return isEditing
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 97.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "addReminder" {
            return true
        }
        if isEditing {
            return true
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? UINavigationController,
            let editReminderViewController = navigationController.viewControllers.first as? EditReminderViewController {
            if let selectedRow = tableView.indexPathForSelectedRow {
                editReminderViewController.reminder = reminders[selectedRow.row]
                editReminderViewController.saveCallback = {
                    self.reminders[selectedRow.row] = editReminderViewController.reminder
                    self.sortReminders()
                    self.tableView.reloadSections([0], with: .none)
                    self.scheduleNotifications()
                }
                editReminderViewController.deleteCallback = {
                    self.reminders.remove(at: selectedRow.row)
                    self.tableView.reloadSections([0], with: .automatic)
                    self.scheduleNotifications()
                }
            } else {
                let now = Date()
                let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: now)
                editReminderViewController.reminder = Reminder(hour: dateComponents.hour! + 1, minute: 0, badge: false, sound: false, isOn: true)
                editReminderViewController.saveCallback = {
                    self.reminders.append(editReminderViewController.reminder)
                    self.sortReminders()
                    self.tableView.reloadSections([0], with: .automatic)
                    self.scheduleNotifications()
                    self.showWarningHeaderIfNeeded()
                }
            }
        }
    }

}

class ReminderCell: UITableViewCell {
    
    @IBOutlet weak var labelContainer: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var periodLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    let switchView = UISwitch()
    
    @IBOutlet weak var disclosureIndicatorContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        accessoryView = switchView
        
        let disclosureCell = UITableViewCell()
        disclosureCell.frame = disclosureIndicatorContainer.bounds
        disclosureCell.accessoryType = .disclosureIndicator
        disclosureCell.isUserInteractionEnabled = false
        disclosureIndicatorContainer.addSubview(disclosureCell)
        disclosureIndicatorContainer.backgroundColor = .clear
        
        disclosureIndicatorContainer.alpha = showsDisclosureIndicatorContainer ? 1.0 : 0.0
    }
    
    var showsDisclosureIndicatorContainer: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.2, delay: (self.showsDisclosureIndicatorContainer ? 0.1 : 0.0), options: [(self.showsDisclosureIndicatorContainer ? .curveEaseOut : .curveEaseIn), .beginFromCurrentState], animations: {
                self.disclosureIndicatorContainer.alpha = self.showsDisclosureIndicatorContainer ? 1.0 : 0.0
            }, completion: nil)
        }
    }
    
}
