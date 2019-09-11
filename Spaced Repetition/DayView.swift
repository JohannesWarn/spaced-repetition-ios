//
//  DayView.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-06.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

class DayView: UIView {
    
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var circleImageView: UIImageView!
    
    var dotLayers: [CAShapeLayer] = []
    
    override func awakeFromNib() {
        for i in 0...6 {
            let dotLayer = CAShapeLayer()
            dotLayer.fillColor = dayColors[i].cgColor
            layer.addSublayer(dotLayer)
            dotLayers.append(dotLayer)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let dotSize = CGSize(width: 8.0, height: 8.0)
        let dotX = bounds.size.width / 2 - dotSize.width / 2
        let dotSpacing: CGFloat = 9.0
        let firstDotY = circleImageView.frame.origin.y + (dotSpacing * 6) + circleImageView.bounds.size.height + 14
        
        for i in 0...6 {
            let dotLayer = dotLayers[i]
            // The first circle is at firstDotY, then every circle is moved up by dotSpacing
            let origin = CGPoint(x: dotX, y: firstDotY - CGFloat(i) * dotSpacing)
            dotLayer.path = UIBezierPath.init(ovalIn: CGRect(origin: origin, size: dotSize)).cgPath
        }
    }
}
