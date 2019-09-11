//
//  WidthSlider.swift
//  calendar
//
//  Created by Johannes Warn on 2019-07-09.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

@IBDesignable class WidthSlider: UISlider {

    var widthValue: CGFloat {
        get {
            return 1.0 + CGFloat((value + value * value) / 2) * 48
        }
    }
    
    override func awakeFromNib() {
        setup()
    }
    
    override func prepareForInterfaceBuilder() {
        setup()
    }
    
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        
        if subview.bounds.size.width == subview.bounds.size.height {
            let blackBackground = CAShapeLayer()
            blackBackground.path = UIBezierPath.init(ovalIn: CGRect(origin: CGPoint(x: 4.0, y: 4.0), size: CGSize(width: 24.0, height: 24.0))).cgPath
            blackBackground.fillColor = UIColor.black.cgColor
            subview.layer.addSublayer(blackBackground)
            
            let whiteBackground = CAShapeLayer()
            whiteBackground.path = UIBezierPath.init(ovalIn: CGRect(origin: CGPoint(x: 6.0, y: 6.0), size: CGSize(width: 20.0, height: 20.0))).cgPath
            whiteBackground.fillColor = UIColor.white.cgColor
            subview.layer.addSublayer(whiteBackground)
        }
    }
    
    func setup() {
        setThumbImage(UIImage.clearImageWithSize(CGSize(width: 32.0, height: 32.0)), for: .normal)
        minimumTrackTintColor = .clear
        maximumTrackTintColor = .clear
        
        layer.cornerRadius = 16
        layer.masksToBounds = true
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 3.0
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context!.setFillColor(UIColor.white.cgColor)
        context!.fill(CGRect(x: 0.0, y: 0.0, width: rect.size.width, height: rect.size.height))
        
        context!.setFillColor(UIColor.black.cgColor)
        for x: CGFloat in stride(from: 0.0, to: rect.width - 32.0, by: 1) {
            let progress = x / (rect.width - 32.0)
            let size = CGFloat((progress + progress * progress) / 2)
            context!.fill(CGRect(x: x + 16.0, y: 3 + ((1 - size) * (rect.size.height - 6)), width: 1.0, height: rect.size.height * size))
        }
        context!.setFillColor(UIColor.black.cgColor)
        context!.fill(CGRect(x: rect.width - 16.0, y: 0.0, width: 16.0, height: rect.size.height))
        context!.setFillColor(UIColor(white: 0.0, alpha: 0.2).cgColor)
        context!.fill(CGRect(x: 0.0, y: rect.size.height-0.5, width: rect.size.width, height: 0.5))
    }

}
