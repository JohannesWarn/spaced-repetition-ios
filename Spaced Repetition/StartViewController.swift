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
    
    var oldTableViewSeparatorInset: UIEdgeInsets? = nil
    @IBOutlet var cardsHeaderLeadingLayoutConstraint: NSLayoutConstraint!
    @IBOutlet var addNewCardButton: UIButton!
    
    @IBOutlet weak var testButton: FancyButton!
    @IBOutlet weak var testDetailLabel: UILabel!
    
    @IBOutlet var creditsTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet var creditsHeightStopBlock: UIView!
    
    @IBOutlet var versionLabel: UILabel!
    
    @IBOutlet var fadeView: GradientView!
    
    var numberOfCardsAtLevelCache: [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for view in daysStackView.subviews {
            let dayView: DayView = UINib.init(nibName: "DayView", bundle: nil).instantiate(withOwner: self, options: nil).first as! DayView
            dayView.frame = view.bounds
            view.addSubview(dayView)
            
            dayViews.append(dayView)
        }
        
        creditsHeightStopBlock.isHidden = true
        
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
        
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "version \(appVersion)"
        }
        
        if #available(iOS 13.0, *) {
            let bottomColor = self.fadeView.bottomColor!
            let middleColor = self.fadeView.middleColor!
            let topColor = self.fadeView.topColor!
            
            fadeView.bottomColor = UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return UIColor.init(white: 0.0, alpha: bottomColor.alpha)
                } else {
                    return bottomColor
                }
            }
            fadeView.middleColor = UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return UIColor.init(white: 0.0, alpha: middleColor.alpha)
                } else {
                    return middleColor
                }
            }
            fadeView.topColor = UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    return UIColor.init(white: 0.0, alpha: topColor.alpha)
                } else {
                    return topColor
                }
            }
        }
    }
    
    var hasCheckedOnboarding = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DaysCompletedManager.skipDaysWithoutTests()
        updateCardsAtLevelCache()
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
        tableView.reloadData()
        
        updateCalendarView()
        
        if !hasCheckedOnboarding && (DaysCompletedManager.getCompletedDays().count == 0 && !(ImageManager.containsAnyCards() || ImageManager.containsDrafts())) {
            performSegue(withIdentifier: "showOnboarding", sender: self)
        }
        hasCheckedOnboarding = true
    }
    
    override func viewDidLayoutSubviews() {
        if oldTableViewSeparatorInset != tableView.separatorInset {
            cardsHeaderLeadingLayoutConstraint.constant = tableView.separatorInset.left - 3.0 // subtract three for optical aligmnent
            addNewCardButton.contentEdgeInsets.left = tableView.separatorInset.left
            addNewCardButton.contentEdgeInsets.right = tableView.separatorInset.left
            
            oldTableViewSeparatorInset = tableView.separatorInset
        }
        
        let cellHeight: CGFloat = 44.0
        let headerAndContentHeight = (tableView.tableHeaderView?.bounds.height ?? 0) + cellHeight * CGFloat(tableView.numberOfRows(inSection: 0))
        let viewportHeight = tableView.frame.height - tableView.contentInset.top
        let extraHeight = max(viewportHeight - headerAndContentHeight, 0)
        let creditsOffset = extraHeight + 100
        if creditsTopLayoutConstraint.constant != creditsOffset {
            creditsTopLayoutConstraint.constant = creditsOffset
        }
        
        guard let tableFooterView = tableView.tableFooterView else { return }
        
        let creditsHeight = creditsHeightStopBlock.frame.origin.y
        if tableFooterView.frame.size.height != creditsHeight {
            var frame = tableFooterView.frame
            frame.size.height = creditsHeight
            tableFooterView.frame = frame
            
            // setting the tableFooterView updates the height
            tableView.tableFooterView = tableFooterView
        }
    }
    
    func updateCardsAtLevelCache() {
        numberOfCardsAtLevelCache = []
        for i in 0...8 {
            numberOfCardsAtLevelCache.append(ImageManager.numberOfCards(atLevel: i))
        }
    }
    
    func updateCalendarView() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        
        let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day], from: Date())
        let today = Calendar.current.date(from: dateComponents)!
        let firstWeekday = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let lastWeekday = Calendar.current.date(byAdding: .day, value: 6, to: firstWeekday)!

        let numberOfDaysCompleted = DaysCompletedManager.getCompletedDays().count
        let numberOfDaysSkipped = DaysCompletedManager.getSkippedDays().count
        let completionStateForToday = DaysCompletedManager.completionState(forDay: today)
        let numberOfDaysCompletedUntilToday = (numberOfDaysCompleted + numberOfDaysSkipped) - (completionStateForToday == .completed ? 1 : 0)
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
        if completionStateForToday == .completed || !ImageManager.containsAnyCards() {
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
            case .skipped:
                dayView.circleImageView.image = UIImage(named: "skip circle")
            default:
                dayView.circleImageView.image = nil
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
            
            let completionState = DaysCompletedManager.completionState(forDay: day)
            if completionState == .completed || completionState == .skipped {
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
    
    @IBAction func shareButtonAction(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = sender
        
        if ImageManager.containsAnyCards() || ImageManager.containsDrafts() {
            alertController.addAction(UIAlertAction(title: "Share All Cards…", style: .default, handler: { (_) in
                self.shareAllImages(barButtonItem: sender)
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "Share App Store Link…", style: .default, handler: { (_) in
            self.shareAppStoreLink()
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true)
    }
    
    func shareAllImages(barButtonItem: UIBarButtonItem? = nil) {
        let currentlySelectedCards = ImageManager.deckOfAllImages()
        
        var images: [UIImage] = []
        for card in currentlySelectedCards {
            if let frontImage = card.frontImage {
                images.append(frontImage)
            }
            if let backImage = card.backImage {
                images.append(backImage)
            }
        }
        
        let activityViewController = UIActivityViewController(activityItems: images, applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = barButtonItem
        activityViewController.addSaveToCameraRollErrorCompletion()
        present(activityViewController, animated: true, completion: nil)
    }
    
    func shareAppStoreLink(barButtonItem: UIBarButtonItem? = nil) {
        let appStoreURL = URL(string: "https://apps.apple.com/app/spaced-repetition/id1476169025")!
        
        let activityViewController = UIActivityViewController(activityItems: [appStoreURL], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = barButtonItem
        present(activityViewController, animated: true, completion: nil)
    }
    
    func level(forIndexPath indexPath: IndexPath) -> Int {
        if ImageManager.containsDrafts() {
            return indexPath.row
        }
        return indexPath.row + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ImageManager.containsDrafts() {
            return 9
        }
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let level = self.level(forIndexPath: indexPath)
        let identifier = (level != 0 && level <= 7) ? "level cell subtitle" : "level cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        var cellContentView = cell.contentView.subviews.first { return $0.isKind(of: LevelCell.self) } as? LevelCell
        if cellContentView == nil {
            let newCellContentView = UINib(nibName: "LevelCell", bundle: nil).instantiate(withOwner: self, options: nil).first as! LevelCell
            newCellContentView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(newCellContentView)

            let detailLabelInset: CGFloat
            if #available(iOS 13, *) { detailLabelInset = -8.0 }
            else { detailLabelInset = 0.0 }
            NSLayoutConstraint.activate([
                newCellContentView.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor, constant: detailLabelInset),
                newCellContentView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                newCellContentView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
            ])
            cellContentView = newCellContentView
        }
        
        // remove the left constraint before potentially removing the image view
        if let leftConstraint = cellContentView?.leftConstraint {
            cell.contentView.removeConstraint(leftConstraint)
        }
        
        if level == 0 {
            cell.imageView?.image = nil
            cell.textLabel?.text = "Drafts"
            cell.detailTextLabel?.text = nil
        } else if level <= 7 {
            cell.imageView?.image = UIImage.imageWithCircle(radius: 4.0, color: dayColors[level - 1])
            cell.textLabel?.text = "Level \(level)"
            cell.detailTextLabel?.text = ["Everyday", "Every 2 days", "Every 4 days", "Every 8 days", "Every 16 days", "Every 32 days", "Every 64 days"][level - 1]
        } else {
            cell.imageView?.image = nil
            cell.textLabel?.text = "Finished Cards"
            cell.detailTextLabel?.text = nil
        }
        
        let numberOfCardsAtLevel = numberOfCardsAtLevelCache[level]
        if numberOfCardsAtLevel == 1 {
            cellContentView?.cardsLabel.text = "\(numberOfCardsAtLevel) card"
        } else {
            cellContentView?.cardsLabel.text = "\(numberOfCardsAtLevel) cards"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
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
    
    @IBAction func openNickyCaseIntro(_ sender: Any) {
        let url = URL(string: "https://ncase.me/remember/")!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func contactDeveloper(_ sender: Any) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Open Mail", style: .default, handler: { (_) in
            let url = URL(string: "mailto:carlolof@johanneswarn.com?subject=Spaced%20Repetition")!
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }))
        alertController.addAction(UIAlertAction(title: "Copy Mail Address", style: .default, handler: { (_) in
            let mail = "carlolof@johanneswarn.com"
            UIPasteboard.general.string = mail
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func openCrabNebula(_ sender: Any) {
        let url = URL(string: "https://images.nasa.gov/details-PIA17563.html")!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let levelCollectionViewController = segue.destination as? LevelCollectionViewController {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                levelCollectionViewController.level = level(forIndexPath: selectedIndexPath)
            }
        } else if let testViewController = segue.destination as? TestViewController {
            testViewController.levels = DaysCompletedManager.levelsForToday()
        }
    }

}
