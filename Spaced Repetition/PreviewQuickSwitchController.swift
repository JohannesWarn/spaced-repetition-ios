//
//  PreviewQuickSwitchController.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-10-23.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

private let reuseIdentifier = "CardCell"

class PreviewQuickSwitchController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    var cards: [CardSides]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let itemHeight = collectionView.bounds.size.height * 0.8
            let itemWidth = floor(itemHeight * 0.675)
            flowLayout.itemSize = CGSize(width: itemWidth, height: itemHeight)
            
            let inset = (collectionView.bounds.size.height - itemHeight) / 2
            let centeringContentInset = (collectionView.bounds.size.width - itemWidth) / 2 - inset
            flowLayout.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
            
            collectionView.contentInset = UIEdgeInsets(top: 0.0, left: centeringContentInset, bottom: 0.0, right: centeringContentInset)
        }
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemHeight = collectionView.bounds.size.height * 0.8
        let itemWidth = floor(itemHeight * 0.675)
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cards?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CardCollectionViewCell
        
        cell.shouldShowCheckMark = false
        cell.imageView.image = cards?[indexPath.row].frontImage
        
        return cell
    }

}
