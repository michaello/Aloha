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
    
    var cardOnboardingViewController: CardOnboardingViewController {
        return childViewControllers.first as! CardOnboardingViewController
    }
    
    var initialPoint: CGPoint? = nil
    var centerPoint: CGPoint? = nil
    var lastOnboardingPosition: Double?
    var index = 0
    
    @IBOutlet weak var swiftyOnboard: SwiftyOnboard! {
        didSet {
            swiftyOnboard.style = .light
            swiftyOnboard.delegate = self
            swiftyOnboard.dataSource = self
        }
    }
    
    fileprivate struct Constants {
        static let onboardingModels: [OnboardingModel?] = [
            OnboardingModel(text: "Create GIFs and movies easily. Just record a short video or pick one from your Photos.", image: #imageLiteral(resourceName: "OnboardingScreen1")),
            OnboardingModel(text: "Worried about losing what you’re saying? 😟Don’t worry, we got this. We will add subtitles for you! 😎", image: #imageLiteral(resourceName: "OnboardingScreen2")),
            OnboardingModel(text: "Export, save it or send to your friends! 🎉", image: #imageLiteral(resourceName: "OnboardingScreen3")),
            nil
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        centerPoint = CGPoint(x: view.center.x, y: view.center.y - 100)
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
            if let alpha = swiftyOnboard.overlay?.pageControl.alpha, alpha != 0.0 {
                swiftyOnboard.overlay?.pageControl.tintColor = .themeColorForPermissionPageControl(withPosition: position)
            }
        } else {
            moveCardToOnboardingPositionIfNeeded()
            setPageOControlOpaqueTintColorIfNeeded()
        }
    }
    
    private func setPageOControlOpaqueTintColorIfNeeded() {
        if let alpha = swiftyOnboard.overlay?.pageControl.alpha, alpha != 1.0 {
            UIView.animate(withDuration: 0.5) {
                self.swiftyOnboard.overlay?.pageControl.tintColor = .themeColor
            }
        }
    }
    
    private func moveCardToCenterIfNeeded(basedOnPosition position: Double) {
        guard position.isInPermissionsRange else { return }
        let diff = initialPoint!.y - centerPoint!.y
        let acc = diff * CGFloat(position - Double.permissionsPosition)
        let yChange = lastOnboardingPosition! < position ? initialPoint!.y - acc : centerPoint!.y + (cardOnboardingViewController.cardView.frame.size.height / 2) - acc
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
    
    func swiftyOnboardPageForIndex(_ swiftyOnboard: SwiftyOnboard, index: Int) -> SwiftyOnboardPage? {
        guard shouldShowOnboardingOverlayViewController(basedOn: index),
            let overlayOnboardingViewController = storyboard?.instantiateViewController(withIdentifier: String(describing: OverlayOnboardingViewController.self)) as? OverlayOnboardingViewController,
            let overlayView = overlayOnboardingViewController.view else { return nil }
        overlayOnboardingViewController.phoneImageView.image = Constants.onboardingModels[index]?.image
        overlayOnboardingViewController.subtitleLabel.text = Constants.onboardingModels[index]?.text
        let page = SwiftyOnboardPage(frame: overlayView.frame)
        page.addSubview(overlayView)
        
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
    
    static let permissionsPosition = 2.0
    
    var isInPermissionsRange: Bool {
        return self > Double.permissionsPosition
    }
}
