//
//  CardView.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-09.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

class CardView: UIView {

    var velocity: CGPoint?
    var isShowingFront = true
    
    fileprivate var frontView: UIView!
    fileprivate var backView: UIView!
    
    var frontViewContentView: UIView!
    var backViewContentView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        frontView = UIView(frame: bounds)
        frontView.layer.transform = CATransform3DMakeRotation(0, 0, 1, 0)
        frontView.layer.borderWidth = 4.0
        frontView.layer.borderColor = UIColor.appForegroundColor.cgColor
        frontView.layer.cornerRadius = 30.0
        frontView.layer.masksToBounds = true
        frontView.layer.transform.m34 = 0.001 // set the perspective
        frontView.layer.isDoubleSided = false
        frontView.backgroundColor = UIColor.appBackgroundColor.staticColor
        addSubview(frontView)
        
        frontViewContentView = UIView(frame: bounds)
        frontViewContentView.backgroundColor = UIColor.appBackgroundColor.staticColor
        frontView.addSubview(frontViewContentView)
        
        backView = UIView(frame: bounds)
        backView.isUserInteractionEnabled = false
        backView.layer.transform = CATransform3DMakeRotation(.pi, 0, 1, 0)
        backView.layer.borderWidth = 4.0
        backView.layer.borderColor = UIColor.appForegroundColor.cgColor
        backView.layer.cornerRadius = 30.0
        backView.layer.masksToBounds = true
        backView.layer.transform.m34 = 0.001 // set the perspective
        backView.layer.isDoubleSided = false
        backView.backgroundColor = UIColor.appBackgroundColor.staticColor
        addSubview(backView)
        
        backViewContentView = UIView(frame: bounds)
        backViewContentView.backgroundColor = UIColor.appBackgroundColor.staticColor
        backView.addSubview(backViewContentView)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        frontView.layer.borderColor = UIColor.appForegroundColor.cgColor
        backView.layer.borderColor = UIColor.appForegroundColor.cgColor
    }
    
    override func layoutSubviews() {
        frontView.frame = bounds
        backView.frame = bounds
        
        frontViewContentView.frame = bounds
        backViewContentView.frame = bounds
    }
    
//    func disableBorder() {
//        frontView.layer.borderWidth = 0.0
//        frontView.layer.borderColor = UIColor.clear.cgColor
//        frontView.layer.cornerRadius = 0.0
//        frontView.layer.masksToBounds = false
//
//        backView.layer.borderWidth = 0.0
//        backView.layer.borderColor = UIColor.clear.cgColor
//        backView.layer.cornerRadius = 0.0
//        backView.layer.masksToBounds = false
//    }
//
//    func enableBorder() {
//        frontView.layer.borderWidth = 4.0
//        frontView.layer.borderColor = UIColor.black.cgColor
//        frontView.layer.cornerRadius = 30.0
//        frontView.layer.masksToBounds = true
//
//        backView.layer.borderWidth = 4.0
//        backView.layer.borderColor = UIColor.black.cgColor
//        backView.layer.cornerRadius = 30.0
//        backView.layer.masksToBounds = true
//    }

    func flip(animated: Bool = true, completion: @escaping ((Bool) -> Void)) {
        isShowingFront = !isShowingFront
        
        frontView.isUserInteractionEnabled = isShowingFront
        backView.isUserInteractionEnabled = !isShowingFront
        
        UIView.animate(withDuration: 0.32, delay: 0.0, options: [.curveEaseInOut], animations: {
            for subview in self.subviews {
                subview.layer.transform = CATransform3DRotate(subview.layer.transform, .pi, 0.0, 1.0, 0.0)
            }
        }, completion: completion)
    }
    
}
