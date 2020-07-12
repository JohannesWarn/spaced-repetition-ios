//
//  CircularProgressView.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2020-07-12.
//  Copyright © 2020 Johannes Wärn. All rights reserved.
//

import UIKit

@IBDesignable class CircularProgressView: UIView {

    var lineWidth: CGFloat = 3.0
    var circleSize = CGSize(width: 30.0 - 3.0, height: 30.0 - 3.0)
    var totalCards: Int?
    var cardsCompleted: Int?
    
    var backgroundCircleLayer: CAShapeLayer!
    var progressCircleLayer: CAShapeLayer!
    var cardsRemainingLabel: UILabel!
    
    override func awakeFromNib() {
        //backgroundColor = .systemPink
        
        cardsRemainingLabel = UILabel(frame: self.bounds)
        
        cardsRemainingLabel.textAlignment = .center
        cardsRemainingLabel.font = UIFont(name: "SFCompactRounded-Medium", size: 14.0)
        cardsRemainingLabel.textColor = .appForegroundColor
        addSubview(cardsRemainingLabel)
        
        backgroundCircleLayer = CAShapeLayer()
        backgroundCircleLayer.path = CGPath(ellipseIn: CGRect(origin: .zero, size: circleSize), transform: nil)
        backgroundCircleLayer.transform = CATransform3DMakeRotation(-.pi / 2.0, 0.0, 0.0, 1.0)
        backgroundCircleLayer.lineWidth = lineWidth
        backgroundCircleLayer.strokeColor = UIColor.appSecondaryForegroundColor.cgColor
        backgroundCircleLayer.fillColor = nil
        layer.addSublayer(backgroundCircleLayer)
        
        progressCircleLayer = CAShapeLayer()
        progressCircleLayer.path = backgroundCircleLayer.path
        progressCircleLayer.transform = backgroundCircleLayer.transform
        progressCircleLayer.lineWidth = backgroundCircleLayer.lineWidth
        progressCircleLayer.strokeColor = UIColor.appForegroundColor.cgColor
        progressCircleLayer.lineCap = .round
        progressCircleLayer.fillColor = nil
        layer.addSublayer(progressCircleLayer)
        
        backgroundCircleLayer.strokeStart = 0.0
        progressCircleLayer.strokeEnd = 0.0
    }
    
    func updateProgress() {
        guard let totalCards = totalCards, let cardsCompleted = cardsCompleted else { return }
        
        let cardsRemaining = totalCards - cardsCompleted
        let progress = Double(cardsCompleted) / Double(totalCards)
        
        cardsRemainingLabel.text = "\(cardsRemaining)"
        if cardsRemaining < 100 {
            cardsRemainingLabel.font = UIFont(name: "SFCompactRounded-Medium", size: 14.0)
        } else if cardsRemaining < 1000 {
            cardsRemainingLabel.font = UIFont(name: "SFCompactRounded-Medium", size: 11.0)
        } else {
            cardsRemainingLabel.font = UIFont(name: "SFCompactRounded-Medium", size: 9.0)
        }
        
        UIView.animate(withDuration: 0.15, delay: 0.0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
            self.backgroundCircleLayer.strokeStart = CGFloat(progress)
            self.progressCircleLayer.strokeEnd = CGFloat(progress)
        }, completion: nil)
    }
    
    override func layoutSubviews() {
        backgroundCircleLayer.frame = CGRect(origin: CGPoint(x: (bounds.size.width - circleSize.width) / 2.0, y: (bounds.size.height - circleSize.height) / 2.0), size: circleSize)
        progressCircleLayer.frame = backgroundCircleLayer.frame
    }

}
