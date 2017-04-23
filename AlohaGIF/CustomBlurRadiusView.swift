//
//  CustomBlurRadiusView.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 22/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

final class CustomBlurRadiusView: UIVisualEffectView {
    
    var animator: UIViewPropertyAnimator!
    
    init() {
        super.init(effect: UIBlurEffect(style: .dark))
    }
    
    override func didMoveToSuperview() {
        animator = UIViewPropertyAnimator(duration: 1.1, curve: .linear) {
            self.effect = nil
        }
        animator.startAnimation()
        animator.pauseAnimation()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            self.animator.fractionComplete = 0.5
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        effect = UIBlurEffect(style: .dark)
    }
}
