//
//  GradientView.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-09.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

@IBDesignable class GradientView: UIView {
    
    var gradientLayer: CAGradientLayer?
    
    @IBInspectable var topColor: UIColor? = nil {
        didSet {
            updateGradient()
        }
    }
    
    @IBInspectable var middleColor: UIColor? = nil {
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
            if let middleColor = middleColor {
                gradientLayer?.colors = [topColor.cgColor, middleColor.cgColor, bottomColor.cgColor]
            }
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

}
