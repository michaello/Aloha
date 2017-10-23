//
//  OnboardingViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 15/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

fileprivate struct OnboardingModel {
    let text: String
    let image: UIImage
}

final class OnboardingViewController: UIViewController {
    
    fileprivate enum Constants {
        static let onboardingModels: [OnboardingModel?] = [
            OnboardingModel(text: "Create GIFs easily. Just record a short video or pick one from your Photos.", image: #imageLiteral(resourceName: "OnboardingScreen1")),
            OnboardingModel(text: "Worried about losing what you’re saying? 😟Don’t worry, we got this. We will add subtitles for you! 😎", image: #imageLiteral(resourceName: "OnboardingScreen2")),
            OnboardingModel(text: "Export, save it or send to your friends! 🎉", image: #imageLiteral(resourceName: "OnboardingScreen3")),
            nil
        ]
        static let initialCenterPointYOffset: CGFloat = -100.0
    }
    
    fileprivate var cardOnboardingViewController: CardOnboardingViewController {
        return childViewControllers.first as! CardOnboardingViewController
    }
    @IBOutlet fileprivate weak var swiftyOnboard: SwiftyOnboard! {
        didSet {
            swiftyOnboard.style = .light
            swiftyOnboard.delegate = self
            swiftyOnboard.dataSource = self
        }
    }
    fileprivate var initialPoint: CGPoint?
    fileprivate var centerPoint: CGPoint?
    fileprivate var lastOnboardingPosition: Double?
    fileprivate var index = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        swiftyOnboard.cardOnboardingView = cardOnboardingViewController.view
        centerPoint = CGPoint(x: view.center.x, y: view.center.y + Constants.initialCenterPointYOffset)
    }
}

extension OnboardingViewController: SwiftyOnboardDelegate {
    func swiftyOnboard(_ swiftyOnboard: SwiftyOnboard, currentPage index: Int) {
        self.index = index
    }
    
    func swiftyOnboard(_ swiftyOnboard: SwiftyOnboard, leftEdge position: Double) {
        swiftyOnboard.overlay?.pageControl.progress = position
        lastOnboardingPosition = position
        if initialPoint == nil {
            initialPoint = cardOnboardingViewController.cardView.frame.origin
        }
        animatePermissionsLabel(basedOnPosition: position)
        moveCardToCenterIfNeeded(basedOnPosition: position)
        if position.isInPermissionsRange {
            swiftyOnboard.overlay?.pageControl.tintColor = .themeColorForPermissionPageControl(withPosition: position)
        } else {
            moveCardToOnboardingPositionIfNeeded()
            setPageControlOpaqueTintColor()
        }
    }
    
    private func setPageControlOpaqueTintColor() {
        UIView.animate(withDuration: 0.5) {
            self.swiftyOnboard.overlay?.pageControl.tintColor = .themeColor
        }
    }
    
    private func moveCardToCenterIfNeeded(basedOnPosition position: Double) {
        guard let lastOnboardingPosition = lastOnboardingPosition, let initialPoint = initialPoint, let centerPoint = centerPoint, position.isInPermissionsRange else { return }
        let differenceBetweenInitialAndCenterPoint = initialPoint.y - centerPoint.y
        let acc = differenceBetweenInitialAndCenterPoint * CGFloat(position - Double.permissionsPosition)
        let yChange: CGFloat = {
            if lastOnboardingPosition < position {
                return initialPoint.y
            } else {
                return centerPoint.y + (cardOnboardingViewController.cardView.frame.size.height / 2.0) - acc
            }
        }()
        cardOnboardingViewController.cardView.frame.origin = CGPoint(x: cardOnboardingViewController.cardView.frame.origin.x, y: yChange)
    }
    
    private func moveCardToOnboardingPositionIfNeeded() {
        if let initialPoint = initialPoint, cardOnboardingViewController.cardView.frame.origin != initialPoint {
            UIView.animate(withDuration: 0.5) {
                 self.cardOnboardingViewController.cardView.frame.origin = initialPoint
            }
        }
    }
    
    private func animatePermissionsLabel(basedOnPosition position: Double) {
        guard position > Double.permissionsPosition else { return }
        cardOnboardingViewController.permissionsLabel.alpha = CGFloat(position - Double.permissionsPosition)
    }
}

extension OnboardingViewController: SwiftyOnboardDataSource {
    func swiftyOnboardNumberOfPages(_ swiftyOnboard: SwiftyOnboard) -> Int {
        return Constants.onboardingModels.count
    }
    
    func swiftyOnboardPageForIndex(_ swiftyOnboard: SwiftyOnboard, index: Int) ->
        SwiftyOnboardPage? {
        guard shouldShowOnboardingOverlayViewController(basedOn: index) else { return nil }
        let overlayOnboardingViewController = UIStoryboard.viewController(OverlayOnboardingViewController.self)
        let overlayView = overlayOnboardingViewController.view
        overlayOnboardingViewController.phoneImageView.image = Constants.onboardingModels[index]?.image
        overlayOnboardingViewController.subtitleLabel.text = Constants.onboardingModels[index]?.text
        let page = SwiftyOnboardPage(frame: overlayView?.frame ?? .zero)
        if let overlayView = overlayView {
            page.addSubview(overlayView)
        }
        
        return page
    }

    func swiftyOnboardViewForOverlay(_ swiftyOnboard: SwiftyOnboard) -> SwiftyOnboardOverlay? {
        return SwiftyOnboardOverlay(frame: view.frame)
    }
    
    private func shouldShowOnboardingOverlayViewController(basedOn index: Int) -> Bool {
        return Constants.onboardingModels[index] != nil
    }
}

fileprivate extension Double {
    
    fileprivate static let permissionsPosition = 2.0
    
    fileprivate var isInPermissionsRange: Bool {
        return self > Double.permissionsPosition
    }
}
