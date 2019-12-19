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
    
    var blackBackground: CAShapeLayer?
    var whiteBackground: CAShapeLayer?
    
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
            blackBackground.fillColor = UIColor.appForegroundColor.cgColor
            subview.layer.addSublayer(blackBackground)
            
            let whiteBackground = CAShapeLayer()
            whiteBackground.path = UIBezierPath.init(ovalIn: CGRect(origin: CGPoint(x: 6.0, y: 6.0), size: CGSize(width: 20.0, height: 20.0))).cgPath
            whiteBackground.fillColor = UIColor.appBackgroundColor.cgColor
            subview.layer.addSublayer(whiteBackground)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        blackBackground?.fillColor = UIColor.black.cgColor
        whiteBackground?.fillColor = UIColor.white.cgColor
        
        layer.borderColor = UIColor.appForegroundColorGrayInDarkMode.cgColor
    }

    func setup() {
        setThumbImage(UIImage.clearImageWithSize(CGSize(width: 32.0, height: 32.0)), for: .normal)
        minimumTrackTintColor = .clear
        maximumTrackTintColor = .clear
        
        layer.cornerRadius = 16
        layer.masksToBounds = true
        layer.borderColor = UIColor.appForegroundColorGrayInDarkMode.cgColor
        layer.borderWidth = 3.0
    }
    
    override func draw(_ rect: CGRect) {
        let onePixel = 1.0 / UIScreen.main.scale
        let context = UIGraphicsGetCurrentContext()
        
        context!.setFillColor(UIColor.appBackgroundColor.cgColor)
        context!.fill(CGRect(x: 0.0, y: 0.0, width: rect.size.width, height: rect.size.height))
        
        context!.setFillColor(UIColor.appForegroundColor.cgColor)
        for x: CGFloat in stride(from: 0.0, to: rect.width, by: onePixel) {
            let progress = x / rect.width
            let size = CGFloat((progress + progress * progress) / 2)
            let relativeSize = 0.5 + (rect.size.height - 6.0) * size
            context!.fill(CGRect(x: x, y: rect.size.height * 0.5 - relativeSize * 0.5, width: onePixel, height: relativeSize))
        }
    }

}
