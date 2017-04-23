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
            UIView.transition(with: view, duration: 0.4, options: .transitionCrossDissolve, animations: {
                UIView.performWithoutAnimation {
                    self.pushViewController(viewController, animated: false)
                }
            }, completion: nil)
    }
    
    func popViewControllerWithFadeAnimation() {
        UIView.transition(with: view, duration: 0.4, options: .transitionCrossDissolve, animations: {
            UIView.performWithoutAnimation {
                self.popViewController(animated: false)
            }
        }, completion: nil)
    }
}
