//
//  CardCollectionViewCell.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-10.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

class CardCollectionViewCell: UICollectionViewCell {
    
    var imageView = UIImageView()
    var highlightOverlay = UIView()
    var shouldShowCheckMark = false
    var selectedImageView = UIImageView(image: UIImage(named: "selected"))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        imageView.layer.borderWidth = 2.0
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.cornerRadius = 10.0
        imageView.layer.masksToBounds = true
        addSubview(imageView)
        
        highlightOverlay.backgroundColor = UIColor.init(white: 0.0, alpha: 0.25)
        highlightOverlay.isHidden = true
        imageView.addSubview(highlightOverlay)
    }
    
    override func layoutSubviews() {
        imageView.frame = bounds
        highlightOverlay.frame = imageView.bounds
    }
    
    override var isHighlighted: Bool {
        didSet {
            highlightOverlay.isHidden = !self.isHighlighted
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if self.isSelected && shouldShowCheckMark {
                selectedImageView.frame.origin.x = bounds.size.width - selectedImageView.bounds.size.width
                selectedImageView.frame.origin.y = bounds.size.height - selectedImageView.bounds.size.height
                addSubview(selectedImageView)
            } else {
                selectedImageView.removeFromSuperview()
            }
        }
    }
    
}
