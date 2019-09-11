//
//  FancyButton.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-08.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

@IBDesignable class FancyButton: UIButton {

    var gradientLayer: CAGradientLayer?
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    @IBInspectable var topColor: UIColor? = nil {
        didSet {
            updateGradient()
        }
    }
    
    @IBInspectable var bottomColor: UIColor? = nil {
        didSet {
            updateGradient()
        }
    }
    
    func updateGradient() {
        if let bottomColor = bottomColor, let topColor = topColor {
            if gradientLayer == nil {
                gradientLayer = CAGradientLayer()
                layer.insertSublayer(gradientLayer!, at: 0)
            }
            gradientLayer?.colors = [topColor.cgColor, bottomColor.cgColor]
            setNeedsLayout()
        } else {
            gradientLayer?.removeFromSuperlayer()
            gradientLayer = nil
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = layer.bounds
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
