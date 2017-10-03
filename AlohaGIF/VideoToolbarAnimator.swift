//
//  VideoToolbarAnimator.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

final class VideoToolbarAnimator {
    
    private struct Constants {
        static let duration = 0.5
        static let oneEightyRotationTime = 0.3
        static let ninetyDegreeRotationTime = 0.25
        static let magicMultiplierThatMakesHiddenWithVisibleArrow: CGFloat = 0.74
    }
    
    weak var arrowButton: UIButton?
    weak var movieToolbarBackgroundContainerView: UIView? {
        didSet {
            if let view = movieToolbarBackgroundContainerView {
                collapsedOffset = view.frame.height * Constants.magicMultiplierThatMakesHiddenWithVisibleArrow
            }
        }
    }
    weak var movieToolbarContainerView: UIView?
    private var collapsedOffset: CGFloat = 0.0
    
    func animateHidden() {
        UIView.animate(withDuration: Constants.oneEightyRotationTime) {
            self.arrowButton?.transform = CGAffineTransform(rotationAngle: CGFloat(0.999) * CGFloat(Double.pi))
        }
        move(toUp: false)
    }
    
    func animateVisible() {
        UIView.animate(withDuration: Constants.oneEightyRotationTime ) {
            self.arrowButton?.transform = .identity
        }
        move(toUp: true)
    }
    
    func animateGoingBackToMain() {
        UIView.animate(withDuration: Constants.ninetyDegreeRotationTime) {
            self.arrowButton?.transform = .identity
        }
    }
    
    func animateGoingToVideoOptionMenu() {
        UIView.animate(withDuration: Constants.ninetyDegreeRotationTime) {
            self.arrowButton?.transform = CGAffineTransform(rotationAngle: CGFloat(0.999) * CGFloat(Double.pi / 2))
        }
    }
    
    private func move(toUp logicValue: Bool) {
        guard let arrowButton = self.arrowButton, let movieToolbarBackgroundContainerView = self.movieToolbarBackgroundContainerView, let movieToolbarContainerView = self.movieToolbarContainerView else { return }
        let offset = logicValue ? -collapsedOffset : collapsedOffset
        UIView.animate(withDuration: Constants.duration, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
            arrowButton.frame = arrowButton.frame.offsetBy(dx: 0.0, dy: offset)
            movieToolbarContainerView.frame = movieToolbarContainerView.frame.offsetBy(dx: 0.0, dy: offset)
            movieToolbarBackgroundContainerView.frame = movieToolbarBackgroundContainerView.frame.offsetBy(dx: 0.0, dy: offset)
        }, completion: nil)
    }
}
