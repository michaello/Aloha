//
//  OverlayView.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 20/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

final class OverlayView: UIView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var viewsPassingHitTest = [UIView?]()
        let superviewButtons = superview?.subviews.flatMap { $0 as? UIButton }
        superviewButtons?.forEach {
            viewsPassingHitTest.append($0.hitTest(self.convert(point, to: $0), with: event))
        }
        if let view = viewsPassingHitTest.flatMap({ $0 }).first {
            return view
        }
        
        return super.hitTest(point, with: event)
    }
}
