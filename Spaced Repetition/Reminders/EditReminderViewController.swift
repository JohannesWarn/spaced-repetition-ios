//
//  EditReminderViewController.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-11.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

class EditReminderViewController: UITableViewController {

    var reminder: Reminder!
    var saveCallback: (() -> ())?
    var deleteCallback: (() -> ())?
    
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var badgeCell: UITableViewCell!
    @IBOutlet weak var soundCell: UITableViewCell!
    
    var badgeSwitch = UISwitch()
    var soundSwitch = UISwitch()
    
    @IBOutlet weak var deleteCell: UIView!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        badgeCell.accessoryView = badgeSwitch
        soundCell.accessoryView = soundSwitch
        
        badgeSwitch.addTarget(self, action: #selector(updateReminder), for: .touchUpInside)
        soundSwitch.addTarget(self, action: #selector(updateReminder), for: .touchUpInside)
        
        updateUI()
    }
    
    func updateUI() {
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dateComponents.setValue(reminder.hour, for: .hour)
        dateComponents.setValue(reminder.minute, for: .minute)
        timePicker.date = Calendar.current.date(from: dateComponents)!
        
        badgeSwitch.isOn = reminder.badge
        soundSwitch.isOn = reminder.sound
    }
    
    @IBAction func updateReminder() {
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: timePicker.date)
        reminder.hour = dateComponents.hour!
        reminder.minute = dateComponents.minute!
        
        reminder.badge = badgeSwitch.isOn
        reminder.sound = soundSwitch.isOn
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            if let cellSwitch = cell.accessoryView as? UISwitch {
                cellSwitch.setOn(!cellSwitch.isOn, animated: true)
                tableView.deselectRow(at: indexPath, animated: true)
                updateReminder()
            } else {
                delete()
            }
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        saveCallback?()
        dismiss(animated: true, completion: nil)
    }
    
    func delete() {
        deleteCallback?()
        dismiss(animated: true, completion: nil)
    }
    
}
