//
//  OverlayView.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 20/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

final class OverlayView: UIView {
    
    var buttons = [UIButton]()
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var hitTest: UIView?
        buttons.forEach {
            hitTest = $0.hitTest(self.convert(point, to: $0), with: event)
        }
        if hitTest != nil {
            return hitTest!
        }
        
        return super.hitTest(point, with: event)
    }
}
