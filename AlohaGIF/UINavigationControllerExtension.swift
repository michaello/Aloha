//
//  UINavigationControllerExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

extension UINavigationController {
    func pushViewControllerWithFadeAnimation(_ viewController: UIViewController) {
        transitionAnimation {
            self.pushViewController(viewController, animated: false)
        }
    }
    
    func popViewControllerWithFadeAnimation() {
        transitionAnimation {
            self.popViewController(animated: false)
        }
    }
    
    private func transitionAnimation(animation: @escaping () -> ()) {
        UIView.transition(with: view, duration: 0.4, options: .transitionCrossDissolve, animations: {
            UIView.performWithoutAnimation {
                animation()
            }
        }, completion: nil)
    }
}
