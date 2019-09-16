//
//  LevelCollectionViewController.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-10.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

class LevelCollectionViewController: UICollectionViewController {

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
        reload()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
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
        
        if let newCardController = segue.destination as? NewCardViewController {
            if let indexPath = collectionView.indexPathsForSelectedItems?.first {
                newCardController.existingCard = cards?[indexPath.row]
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCell", for: indexPath) as! CardCollectionViewCell
        
        cell.shouldShowCheckMark = isEditing
        cell.imageView.image = cards?[indexPath.row].frontImage
        
        return cell
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
