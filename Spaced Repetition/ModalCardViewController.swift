//
//  ModalCardViewController.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-09.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

class ModalCardViewController: UIViewController {

    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var cardViewPlaceholder: UIView!
    var cardView: CardView! = CardView()
    
    @IBOutlet weak var infoContainerView: UIView!
    var infoNavigationController: UINavigationController!
    
    var shouldAnimateClose: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardViewPlaceholder.backgroundColor = nil
    }
    
    @IBAction func close(_ sender: Any) {
        view.endEditing(true)
        self.dismiss(animated: shouldAnimateClose, completion: nil)
    }
    
    func animateInNewCard(_ cardView: CardView, direction: Int = 0) {
        let duration: TimeInterval
        let delay: TimeInterval
        if direction == 0 {
            duration = 0.2
            delay = 0.1
            cardView.alpha = 0.0
            cardView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        } else {
            duration = 0.5
            delay = 0.0
            cardView.transform = CGAffineTransform.identity
            if direction < 0 {
                cardView.center.x = self.view.bounds.size.width + (cardView.bounds.width * 1.2)
            } else {
                cardView.center.x = 0 - (cardView.bounds.width * 1.2)
            }
        }
        
        guard let cardToAnimate = self.cardView else { return }
        UIView.animate(withDuration: duration, delay: delay, options: [.curveEaseOut], animations: {
            cardToAnimate.center.x = self.view.bounds.size.width / 2.0
            cardToAnimate.alpha = 1.0
            cardToAnimate.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    func animateOutCard(_ cardView: CardView, direction: Int, shouldRotate: Bool = true, completion: (() -> ())? = nil) {
        cardView.layer.zPosition = 1
        let randomFactor = 0.9 + drand48() * 0.2
        
        var destination: CGPoint = cardView.center
        if direction > 0 {
            destination.x = self.view.bounds.size.width + (cardView.bounds.width * 1.2)
        } else {
            destination.x = 0 - (cardView.bounds.width * 1.2)
        }
        
        let duration: TimeInterval
        if let velocity = cardView.velocity {
            let distance = destination.x - cardView.center.x
            duration = min(TimeInterval(distance / velocity.x), 0.5)
            destination.y += velocity.y * CGFloat(duration)
        } else {
            duration = 0.45 * randomFactor
            if shouldRotate {
                destination.y += cardView.bounds.height * 0.05 * CGFloat(randomFactor)
            }
        }
        
        UIView.animate(withDuration: duration, delay: 0.0, options: [.curveEaseIn], animations: {
            cardView.center = destination
            if shouldRotate {
                cardView.transform = CGAffineTransform(rotationAngle: CGFloat(direction) * .pi/8 * CGFloat(randomFactor))
            }
        }, completion: { (finished) in
            cardView.removeFromSuperview()
            completion?()
        })
    }

}
