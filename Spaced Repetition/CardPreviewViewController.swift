//
//  CardPreviewViewController.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-10-23.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

class CardPreviewViewController: ModalCardViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var flipCardGestureRecognizer: UITapGestureRecognizer!
    var swipeCardGestureRecognizer: UIPanGestureRecognizer!

    var cardDeck: [CardSides]!
    var currentIndex: Int!
    var currentCard: CardSides?
    
    var frontImageView: UIImageView?
    var backImageView: UIImageView?
    
    var previewQuickSwitchController: PreviewQuickSwitchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCardView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        cardView.frame = cardViewPlaceholder.frame
        cardView.frontViewContentView.frame = cardView.bounds
        for subview in cardView.frontViewContentView.subviews {
            subview.frame = cardView.frontViewContentView.bounds
        }
        cardView.backViewContentView.frame = cardView.bounds
        for subview in cardView.backViewContentView.subviews {
            subview.frame = cardView.backViewContentView.bounds
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        currentCard?.updateImages()
        if let currentCard = currentCard {
            cardDeck[currentIndex] = currentCard
            previewQuickSwitchController?.cards = cardDeck
            previewQuickSwitchController?.collectionView.reloadItems(at: [IndexPath(item: currentIndex, section: 0)])
        }
        frontImageView?.image = currentCard?.frontImage
        backImageView?.image = currentCard?.backImage
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return [.portrait, .portraitUpsideDown]
        }
    }
    
    func setupCardView() {
        guard let currentCard = currentCard else { return }
        
        cardView = CardView(frame: cardViewPlaceholder.frame)
        
        frontImageView = UIImageView(frame: cardView.frontViewContentView.bounds)
        frontImageView!.image = currentCard.frontImage
        cardView.frontViewContentView.addSubview(frontImageView!)
        
        backImageView = UIImageView(frame: cardView.backViewContentView.bounds)
        backImageView!.image = currentCard.backImage
        cardView.backViewContentView.addSubview(backImageView!)
        
        view.addSubview(cardView)
        
        flipCardGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(flipCard))
        cardView.addGestureRecognizer(flipCardGestureRecognizer)
        swipeCardGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(swipeCard(_:)))
        cardView.addGestureRecognizer(swipeCardGestureRecognizer)
    }
    
    @objc func flipCard() {
        flipCardGestureRecognizer.isEnabled = false
        
        cardView.flip(animated: true) { (finished) in
            self.flipCardGestureRecognizer.isEnabled = true
        }
    }
    
    @objc func swipeCard(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        cardView.center.x = cardViewPlaceholder.center.x + translation.x
                
        var velocity = gesture.velocity(in: view)
        velocity.y = 0.0
        let finalPosition = CGPoint(x: translation.x + velocity.x, y: 0.0)
        let finalProgress = finalPosition.x / (view.bounds.width / 2.0)
        
        if gesture.state == .ended || gesture.state == .failed || gesture.state == .cancelled {
            if finalProgress <= -1.0 && translation.x < 20.0 && currentIndex + 1 < cardDeck.count {
                cardView.velocity = velocity
                moveCardBack()
            } else if finalProgress >= 1.0 && translation.x > 20.0 && currentIndex > 0 {
                cardView.velocity = velocity
                moveCardForward()
            } else {
                animateCardToCenter(cardView)
            }
        }
    }
    
    @objc func moveCardForward() {
        guard let cardToAnimate = self.cardView else { return }
        animateOutCard(cardToAnimate, direction: 1, shouldRotate: false)
        
        currentIndex -= 1
        currentCard = cardDeck[currentIndex]
        previewQuickSwitchController?.collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: true)
        
        setupCardView()
        animateInNewCard(cardView, direction: 1)
    }
    
    @objc func moveCardBack() {
        guard let cardToAnimate = self.cardView else { return }
        animateOutCard(cardToAnimate, direction: -1, shouldRotate: false)
        
        currentIndex += 1
        currentCard = cardDeck[currentIndex]
        previewQuickSwitchController?.collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: true)
        
        setupCardView()
        animateInNewCard(cardView, direction: -1)
    }
    
    
    func animateCardToCenter(_ cardView: CardView) {
        let randomFactor = 0.9 + drand48() * 0.2
        UIView.animate(withDuration: 0.45 * randomFactor, delay: 0.0, options: [], animations: {
            cardView.center.x = self.cardViewPlaceholder.center.x
            cardView.center.y = self.cardViewPlaceholder.center.y
            cardView.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let newCardController = segue.destination as? NewCardViewController {
            newCardController.existingCard = self.currentCard
            newCardController.shouldAnimateClose = false
        } else if let previewQuickSwitchController = segue.destination as? PreviewQuickSwitchController {
            previewQuickSwitchController.cards = self.cardDeck
            if let currentIndex = currentIndex {
                DispatchQueue.main.async {
                    previewQuickSwitchController.collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: false)
                }
            }
            previewQuickSwitchController.collectionView.delegate = self
            self.previewQuickSwitchController = previewQuickSwitchController
        }
    }
    
    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == currentIndex {
            return
        }
        
        cardView.removeFromSuperview()
        
        currentIndex = indexPath.row
        currentCard = cardDeck[currentIndex]
        previewQuickSwitchController?.collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: true)
        setupCardView()
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
    
    
}
