//
//  TestViewController.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-07.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

class TestViewController: ModalCardViewController {

    var levels: [Int]?
    
    var flipCardGestureRecognizer: UITapGestureRecognizer!
    var swipeCardGestureRecognizer: UIPanGestureRecognizer!
    
    var buttonsViewController: ButtonsViewController?
    var cardDeck: [CardSides]!
    var currentCard: CardSides?
    
    @IBOutlet weak var progressView: CircularProgressView!
    @IBOutlet weak var allDoneImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let levels = levels else {
            DispatchQueue.main.async {
                self.dismiss(animated: false, completion: nil)
            }
            return
        }
        
        cardDeck = ImageManager.deckOfImages(forLevels: levels)
        cardDeck.shuffle()
        view.insertSubview(allDoneImageView, belowSubview: closeButton)
        
        if cardDeck.count == 0 {
            allDoneImageView.alpha = 1.0
            
            let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day], from: Date())
            let today = Calendar.current.date(from: dateComponents)!
            DaysCompletedManager.setCompletion(forDay: today)
            NotificationsManager.scheduleNotifications()
            UIApplication.shared.applicationIconBadgeNumber = 0
        } else {
            progressView.cardsCompleted = 0
            progressView.totalCards = cardDeck.count
            progressView.updateProgress()
        }
        
        setupCardView()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(applicationDidEnterBackground(notification:)),
            name: UIApplication.didEnterBackgroundNotification, object: nil
        )
    }
    
    @objc func applicationDidEnterBackground(notification: NSNotification) {
        if cardDeck.count == 0 {
            dismiss(animated: false, completion: nil)
        }
    }
    
    func setupCardView() {
        guard let cardSides = cardDeck.popLast() else {
            return
        }
        currentCard = cardSides
        
        cardView = CardView(frame: cardViewPlaceholder.frame)
        let frontImageView = UIImageView(frame: cardView.frontViewContentView.bounds)
        
        frontImageView.image = cardSides.frontImage
        cardView.frontViewContentView.addSubview(frontImageView)
        let backImageView = UIImageView(frame: cardView.backViewContentView.bounds)
        backImageView.image = cardSides.backImage
        cardView.backViewContentView.addSubview(backImageView)
        view.addSubview(cardView)
        
        flipCardGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(flipCard))
        cardView.addGestureRecognizer(flipCardGestureRecognizer)
        swipeCardGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(swipeCard(_:)))
        swipeCardGestureRecognizer.isEnabled = false
        cardView.addGestureRecognizer(swipeCardGestureRecognizer)
    }
    
    override func viewDidLayoutSubviews() {
        // If the back of the card is shown it's possible that it is being animated.
        // We only need to change the frame of the card when it is added, and then the front is shown.
        if cardView.isShowingFront {
            cardView.frame = cardViewPlaceholder.frame
            for subview in cardView.frontViewContentView.subviews {
                subview.frame = cardView.frontViewContentView.bounds
            }
            for subview in cardView.backViewContentView.subviews {
                subview.frame = cardView.backViewContentView.bounds
            }
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return [.portrait, .portraitUpsideDown]
        }
    }
    
    @objc func flipCard() {
        flipCardGestureRecognizer.isEnabled = false
        swipeCardGestureRecognizer.isEnabled = false
        
        cardView.flip(animated: true) { (finished) in
            self.flipCardGestureRecognizer.isEnabled = true
            self.swipeCardGestureRecognizer.isEnabled = !self.cardView.isShowingFront
        }
        
        animateInfoToState(infoNavigationController.viewControllers.count == 1 ? 1 : 0)
    }
    
    @objc func swipeCard(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        cardView.center.x = cardViewPlaceholder.center.x + translation.x
        cardView.center.y = cardViewPlaceholder.center.y + translation.y
        
        let progress = translation.x / (view.bounds.width / 2.0 + cardView.bounds.width * 1.2)
        cardView.transform = CGAffineTransform(rotationAngle: progress * .pi/8)
        
        let velocity = gesture.velocity(in: view)
        let finalPosition = CGPoint(x: translation.x + velocity.x, y: translation.y + velocity.y)
        let finalProgress = finalPosition.x / (view.bounds.width / 2.0)
        
        if gesture.state == .ended || gesture.state == .failed || gesture.state == .cancelled {
            if finalProgress <= -1.0 && translation.x < 20.0 {
                cardView.velocity = velocity
                moveCardBack()
            } else if finalProgress >= 1.0 && translation.x > 20.0 {
                cardView.velocity = velocity
                moveCardForward()
            } else {
                animateCardToCenter(cardView)
            }
        }
    }
    
    func animateInfoToState(_ state: Int) {
        UIView.transition(with: infoContainerView, duration: 0.12, options: [.transitionCrossDissolve], animations: {
            if state == 0 {
                self.infoNavigationController.popToRootViewController(animated: false)
            } else if state == 1 {
                self.infoNavigationController.viewControllers.first!.performSegue(withIdentifier: "showButtons", sender: self)
                let buttonsViewController = self.infoNavigationController.viewControllers.last as! ButtonsViewController
                buttonsViewController.loadViewIfNeeded()
                buttonsViewController.incorrectButton.addTarget(self, action: #selector(self.moveCardBack), for: .touchUpInside)
                buttonsViewController.correctButton.addTarget(self, action: #selector(self.moveCardForward), for: .touchUpInside)
                self.buttonsViewController = buttonsViewController
            }
        }, completion: nil)
    }
    
    @objc func moveCardForward() {
        guard let cardToAnimate = self.cardView else { return }
        progressView.cardsCompleted? += 1
        progressView.updateProgress()
        
        animateOutCard(cardToAnimate, direction: 1)
                
        if let currentCard = currentCard {
            ImageManager.move(card: currentCard, toLevel: currentCard.level + 1)
        }
        
        if cardDeck.count == 0 {
            cardDeck = ImageManager.deckOfImages(forLevel: 1)
            cardDeck.shuffle()
        }
        
        if cardDeck.count > 0 {
            setupCardView()
            animateInNewCard(cardView)
            animateInfoToState(0)
        } else {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseIn], animations: {
                self.infoContainerView.alpha = 0.0
            }, completion: nil)
            UIView.animate(withDuration: 0.4, delay: 0.3, options: [.curveEaseOut], animations: {
                self.allDoneImageView.alpha = 1.0
                
                let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day], from: Date())
                let today = Calendar.current.date(from: dateComponents)!
                DaysCompletedManager.setCompletion(forDay: today)
                UIApplication.shared.applicationIconBadgeNumber = 0
            }, completion: nil)
        }
    }
    
    @objc func moveCardBack() {
        guard let cardToAnimate = self.cardView else { return }
        animateOutCard(cardToAnimate, direction: -1)
        
        if let currentCard = currentCard {
            ImageManager.move(card: currentCard, toLevel: 1)
        }
        
        if cardDeck.count == 0 {
            cardDeck = ImageManager.deckOfImages(forLevel: 1)
            cardDeck.shuffle()
        }
        
        setupCardView()
        animateInNewCard(cardView)
        animateInfoToState(0)
    }
    
    func animateCardToCenter(_ cardView: CardView) {
        let randomFactor = 0.9 + drand48() * 0.2
        UIView.animate(withDuration: 0.45 * randomFactor, delay: 0.0, options: [], animations: {
            cardView.center.x = self.cardViewPlaceholder.center.x
            cardView.center.y = self.cardViewPlaceholder.center.y
            cardView.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedInfoNavigation" {
            infoNavigationController = segue.destination as? UINavigationController
        }
    }

}
