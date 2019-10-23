//
//  LevelCollectionViewController.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-10.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

class LevelCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    var cards: [CardSides]?
    var level: Int? {
        didSet {
            if let level = self.level {
                if level == 0 {
                    title = "Drafts"
                } else if level <= 7 {
                    title = "Level \(level)"
                } else {
                    title = "Finished Cards"
                }
                cards = ImageManager.deckOfImages(forLevel: level).sortedByCardName()
            } else {
                title = nil
                cards = nil
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.rightBarButtonItem?.title = isEditing ? "Done" : "Select"
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.minimumLineSpacing = 16.0
            flowLayout.minimumInteritemSpacing = 0.0
            
            let itemWidth = floor((collectionView.bounds.size.width - 4 * 16.0) / 3)
            let itemHeight = floor(itemWidth / 0.675)
            flowLayout.itemSize = CGSize(width: itemWidth, height: itemHeight)
            
            flowLayout.sectionInset = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reload()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setToolbarHidden(true, animated: true)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        navigationItem.rightBarButtonItem?.title = editing ? "Done" : "Select"
        navigationController?.setToolbarHidden(!editing, animated: true)
        collectionView.allowsSelection = false
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = editing
        
        for cell in collectionView.visibleCells {
            if let cell = cell as? CardCollectionViewCell {
                cell.shouldShowCheckMark = editing
            }
        }
        
        updateToolbarEnabled()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return !isEditing
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let indexPath = collectionView.indexPathsForSelectedItems?.first {
            if let newCardController = segue.destination as? NewCardViewController {
                newCardController.existingCard = cards?[indexPath.row]
            } else if let cardPreviewController = segue.destination as? CardPreviewViewController {
                cardPreviewController.currentCard = cards?[indexPath.row]
                cardPreviewController.cardDeck = cards
                cardPreviewController.currentIndex = indexPath.row
            }
        }
    }
    
    func reload() {
        guard let level = level else { return }
        
        cards = ImageManager.deckOfImages(forLevel: level).sortedByCardName()
        collectionView.reloadData()
    }
    
    func updateToolbarEnabled() {
        let hasSelection = collectionView.indexPathsForSelectedItems?.count ?? 0 > 0
        for toolbarItem in toolbarItems ?? [] {
            toolbarItem.isEnabled = hasSelection
        }
    }
    
    func selectedCards() -> [CardSides] {
        guard let selectedItems = collectionView.indexPathsForSelectedItems else { return [] }
        guard let cards = cards else { return [] }
        return selectedItems.map({ (indexPath) -> CardSides in
            return cards[indexPath.row]
        })
    }
    
    @IBAction func shareSelectedCards(_ sender: UIBarButtonItem) {
        let currentlySelectedCards = selectedCards()
        
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
        activityViewController.popoverPresentationController?.barButtonItem = sender
        activityViewController.addSaveToCameraRollErrorCompletion()
        present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func moveSelectedCards(_ sender: UIBarButtonItem) {
        let currentlySelectedCards = selectedCards()
        
        func moveSelectedCards(toLevel level: Int) {
            for card in currentlySelectedCards {
                ImageManager.move(card: card, toLevel: level)
            }
            isEditing = false
            reload()
        }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = sender
        if self.level != 0 {
            alertController.addAction(UIAlertAction(title: "Move to Drafts", style: .default, handler: { (_) in
                moveSelectedCards(toLevel: 0)
            }))
        }
        for level in 1...7 {
            if self.level != level {
                alertController.addAction(UIAlertAction(title: "Move to Level \(level)", style: .default, handler: { (_) in
                    moveSelectedCards(toLevel: level)
                }))
            }
        }
        if self.level != 8 {
            alertController.addAction(UIAlertAction(title: "Move to Finished Cards", style: .default, handler: { (_) in
                moveSelectedCards(toLevel: 8)
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func deleteSelectedCards(_ sender: UIBarButtonItem) {
        let currentlySelectedCards = selectedCards()
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = sender
        let title = currentlySelectedCards.count == 1 ? "Delete Card" : "Delete \(currentlySelectedCards.count) Cards"
        alertController.addAction(UIAlertAction(title: title, style: .destructive, handler: { (_) in
            for card in currentlySelectedCards {
                ImageManager.delete(card: card)
            }
            self.isEditing = false
            self.reload()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cards?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = (level == 0) ? "DraftCell" : "CardCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CardCollectionViewCell
        
        cell.shouldShowCheckMark = isEditing
        cell.imageView.image = cards?[indexPath.row].frontImage
        
        return cell
    }
    
    let levelFooterTexts = [
        // drafts
        "Cards with only one side are saved as drafts. You can also move cards from any level to drafts if you are not ready to review them.",
        // level 1
        "New cards are added to level 1. When you review a card, and get it right, it moves up one level. When you review a card, and get it wrong, it is moved back to level 1.",
        // level 2-7
        "When you review a card, and get it right, it moves up one level. When you review a card, and get it wrong, it is moved back to level 1.",
        // completed cards
        "When you have moved a card through all 7 levels they are marked as finished. Finished cards are not shown in the test. If you want to review them again you can move them to another level."
    ]
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let reuseIdentifier = (kind == UICollectionView.elementKindSectionHeader) ? "header" : "footer"
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: reuseIdentifier, for: indexPath)
        let label = view.subviews.first { $0.isKind(of: UILabel.self) } as? UILabel
        
        let levelText: String
        
        if (kind == UICollectionView.elementKindSectionHeader) {
            if let level = level, let cardsCount = cards?.count, cardsCount > 0, let dayForNextReview = DaysCompletedManager.nextDayToRepeatLevel(level) {
                let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day], from: Date())
                let today = Calendar.current.date(from: dateComponents)!
                                
                let reviewDateString: String
                if today == dayForNextReview {
                    reviewDateString = "today"
                } else {
                    let numberOfDays = Calendar.current.dateComponents([.day], from: today, to: dayForNextReview).day!
                    if numberOfDays == 1 {
                        reviewDateString = "tomorrow"
                    } else {
                        reviewDateString = "in \(numberOfDays) days"
                    }
                }
                
                let isPlural = cardsCount > 1
                levelText = "\(cardsCount) card\(isPlural ? "s" : ""), next review \(reviewDateString)"
            } else {
                // keep a space so that the attributes ranges is not out of bounds (which would otherwise cause a crash)
                levelText = " "
            }
        } else {
            if level == 0 {
                levelText = levelFooterTexts[0]
            } else if level == 1 {
                levelText = levelFooterTexts[1]
            } else if level == 2 {
                if cards?.count ?? 0 > 0 {
                    levelText = levelFooterTexts[2] + "\nIt might seem as if cards you got wrong stayed at level 2. That is only because the test repeats all level 1 card until you get them right."
                } else {
                    levelText = levelFooterTexts[2]
                }
            } else if level == 8 {
                levelText = levelFooterTexts[3]
            } else {
                levelText = levelFooterTexts[2]
            }
        }
        
        label?.attributedText = NSAttributedString(string: levelText, attributes: label?.attributedText?.attributes(at: 0, effectiveRange: nil))
        
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if let level = level, let cardsCount = cards?.count, cardsCount > 0, DaysCompletedManager.nextDayToRepeatLevel(level) != nil {
            return CGSize(width: collectionView.bounds.width, height: 50.0)
        } else {
            return CGSize(width: collectionView.bounds.width, height: .leastNonzeroMagnitude)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? CardCollectionViewCell {
            cell.shouldShowCheckMark = isEditing
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateToolbarEnabled()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateToolbarEnabled()
    }
    
}
