//
//  ColorSlider.swift
//  calendar
//
//  Created by Johannes Warn on 2019-07-09.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

@IBDesignable class ColorSlider: UISlider {

    let edgeWidth: CGFloat = 30
    
    let saturation: CGFloat = 1.0
    let brightness: CGFloat = 1.0
    
    var realValue: Float {
        get {
            let edgeWidthAsValue = Float(edgeWidth / 2 / bounds.width)
            let realValue = (value - edgeWidthAsValue) / ((Float(bounds.width) - Float(edgeWidth)) / Float(bounds.width))
            return realValue
        }
    }
    
    var colorValue: UIColor {
        get {
            if realValue <= -0.005 {
                return .white
            } else if realValue >= 1.005 {
                return .black
            } else {
                if realValue < 0 || realValue > 1 {
                    return UIColor(hue: 0.0, saturation: saturation, brightness: brightness, alpha: 1.0)
                }
                return UIColor(hue: CGFloat(realValue), saturation: saturation, brightness: brightness, alpha: 1.0)
            }
        }
    }
    
    func value(forColorValue colorValue: UIColor) -> Float {
        if colorValue == .white {
            return 0.0
        } else if colorValue == .black {
            return 1.0
        } else {
            var hue = CGFloat()
            colorValue.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
            let edgeWidthAsValue = Float(edgeWidth / 2 / bounds.width)
            return edgeWidthAsValue + Float(hue) * ((Float(bounds.width) - Float(edgeWidth)) / Float(bounds.width))
        }
    }
    
    let thumbLayer = CALayer()
    var currentColorLayer = CAShapeLayer()
    var blackBackground = CAShapeLayer()
    var whiteBackground = CAShapeLayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        setup()
    }
    
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        
        if subview.bounds.size.width == subview.bounds.size.height {
            blackBackground = CAShapeLayer()
            blackBackground.path = UIBezierPath.init(ovalIn: CGRect(origin: CGPoint(x: 4.0, y: 4.0), size: CGSize(width: 24.0, height: 24.0))).cgPath
            blackBackground.fillColor = UIColor.black.cgColor
            subview.layer.addSublayer(blackBackground)
            
            whiteBackground = CAShapeLayer()
            whiteBackground.path = UIBezierPath.init(ovalIn: CGRect(origin: CGPoint(x: 6.0, y: 6.0), size: CGSize(width: 20.0, height: 20.0))).cgPath
            whiteBackground.fillColor = UIColor.white.cgColor
            subview.layer.addSublayer(whiteBackground)
            
            currentColorLayer = CAShapeLayer()
            currentColorLayer.path = UIBezierPath.init(ovalIn: CGRect(origin: CGPoint(x: 8.0, y: 8.0), size: CGSize(width: 16.0, height: 16.0))).cgPath
            currentColorLayer.fillColor = colorValue.cgColor
            subview.layer.addSublayer(currentColorLayer)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateThumb()
        
        layer.borderColor = UIColor.appForegroundColorGrayInDarkMode.cgColor
    }
    
    var oldSize: CGSize?
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if oldSize != bounds.size {
            setNeedsDisplay()
        }
        oldSize = bounds.size
    }
    
    func updateThumb() {
        blackBackground.fillColor = UIColor.black.cgColor
        whiteBackground.fillColor = UIColor.white.cgColor
        currentColorLayer.fillColor = colorValue.cgColor
        
        let thumbImage = UIImage.imageWithLayer(layer: thumbLayer)
        
        setThumbImage(thumbImage, for: .normal)
    }
    
    func setup() {
        thumbLayer.bounds = CGRect(origin: .zero, size: CGSize(width: 32.0, height: 32.0))
        
        blackBackground = CAShapeLayer()
        blackBackground.path = UIBezierPath.init(ovalIn: CGRect(origin: CGPoint(x: 4.0, y: 4.0), size: CGSize(width: 24.0, height: 24.0))).cgPath
        thumbLayer.addSublayer(blackBackground)
        
        whiteBackground = CAShapeLayer()
        whiteBackground.path = UIBezierPath.init(ovalIn: CGRect(origin: CGPoint(x: 6.0, y: 6.0), size: CGSize(width: 20.0, height: 20.0))).cgPath
        thumbLayer.addSublayer(whiteBackground)
        
        currentColorLayer = CAShapeLayer()
        currentColorLayer.path = UIBezierPath.init(ovalIn: CGRect(origin: CGPoint(x: 8.0, y: 8.0), size: CGSize(width: 16.0, height: 16.0))).cgPath
        thumbLayer.addSublayer(currentColorLayer)
        
        DispatchQueue.main.async {
            self.updateThumb()
        }
        
        addTarget(self, action: #selector(updateColorIndicator), for: .valueChanged)
        addTarget(self, action: #selector(editingDidEnd), for: .touchUpInside)
        addTarget(self, action: #selector(editingDidEnd), for: .touchUpOutside)
                
        minimumTrackTintColor = .clear
        maximumTrackTintColor = .clear
        
        layer.cornerRadius = 16
        layer.masksToBounds = true
        layer.borderColor = UIColor.appForegroundColorGrayInDarkMode.cgColor
        layer.borderWidth = 3.0
    }
    
    @objc func updateColorIndicator() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        updateThumb()
        
        CATransaction.commit()
    }
    
    @objc func editingDidEnd() {
//        if realValue <= -0.005 {
//            setValue(0.0, animated: true)
//        } else if realValue >= 1.005 {
//            setValue(1.0, animated: true)
//        }
    }
    
    override func draw(_ rect: CGRect) {
        let onePixel = 1.0 / UIScreen.main.scale
        let context = UIGraphicsGetCurrentContext()
        for x: CGFloat in stride(from: 0.0, to: rect.width - edgeWidth * 2.0, by: onePixel) {
            let hue = x / (rect.width - edgeWidth * 2.0)
            let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
            context!.setFillColor(color.cgColor)
            context!.fill(CGRect(x: x + edgeWidth, y: 0.0, width: onePixel, height: rect.size.height))
        }
        
        context!.setFillColor(UIColor.white.cgColor)
        context!.fill(CGRect(x: 0.0, y: 0.0, width: edgeWidth, height: rect.size.height))
        context!.setFillColor(UIColor.black.cgColor)
        context!.fill(CGRect(x: rect.width - edgeWidth, y: 0.0, width: edgeWidth, height: rect.size.height))
    }

}
