//
//  COJTextView.swift
//  Spaced Repetition
//
//  Created by Johannes Wärn on 2022-09-19.
//  Copyright © 2022 Johannes Wärn. All rights reserved.
//

import UIKit

class COJTextView: UITextView {
    
    var minimumInteractionSize: CGSize?
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        print("x: \(point.x), y: \(point.y)")
        if super.point(inside: point, with: event) {
            return true
        }
        if let minimumInteractionSize, let pointInSuper = superview?.convert(point, from: self) {
            if abs(pointInSuper.x - center.x) < minimumInteractionSize.width * 0.5
            && abs(pointInSuper.y - center.y) < minimumInteractionSize.height * 0.5
            {
                return true
            }
        }
        return false
    }
    
}
