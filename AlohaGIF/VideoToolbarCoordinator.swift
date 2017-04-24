//
//  VideoToolbarCoordinator.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

struct DynamicSubtitlesStyle {
    static let `default` = DynamicSubtitlesStyle(effect: DynamicSubtitlesType.oneAfterAnother, font: UIFont.boldSystemFont(ofSize: 16.0), color: .white)
    let effect: DynamicSubtitlesType
    let font: UIFont
    let color: UIColor
    
    func font(forRenderingVideo logicValue: Bool) -> UIFont {
        var multiplier = effect == .oneAfterAnother ? 6.0 : 12.0
        multiplier = logicValue ? multiplier : (multiplier / Double(aScale))
        let fontSize: CGFloat = 10.0 * CGFloat(multiplier)
        
        return font.withSize(fontSize)
    }
    
    var textAttributes: [String : Any] {
        return [
            NSStrokeWidthAttributeName : -2.0,
            NSStrokeColorAttributeName : UIColor.black,
            NSFontAttributeName : font,
            NSForegroundColorAttributeName : color
        ]
    }
}

protocol VideoToolbarCoordinatorDelegate: class {
    func dynamicSubtitlesStyleDidChange(_ dynamicSubtitlesStyle: DynamicSubtitlesStyle)
}

final class VideoToolbarCoordinator {
    
    weak var navigationController: UINavigationController?
    weak var delegate: VideoToolbarCoordinatorDelegate?
    fileprivate var isInVideoOptionMenu = false
    var dynamicSubtitlesStyle = DynamicSubtitlesStyle.default {
        didSet {
            delegate?.dynamicSubtitlesStyleDidChange(dynamicSubtitlesStyle)
        }
    }
    fileprivate var animator = VideoToolbarAnimator()
    private var isCollapsed = false {
        didSet {
            isCollapsed ? animator.animateHidden() : animator.animateVisible()
        }
    }
    weak var videoToolbarViewController: VideoToolbarViewController? {
        didSet {
            videoToolbarViewController?.delegate = self
            navigationController = videoToolbarViewController?.navigationController
        }
    }
    
    func passViewsToAnimate(arrowButton: UIButton, movieToolbarBackgroundContainerView: UIView, movieToolbarContainerView: UIView) {
        animator.arrowButton = arrowButton
        animator.movieToolbarBackgroundContainerView = movieToolbarBackgroundContainerView
        animator.movieToolbarContainerView = movieToolbarContainerView
    }
    
    @objc func arrowButtonAction(_ sender: UIButton) {
        guard isInVideoOptionMenu else {
            isCollapsed = !isCollapsed
            return
        }
        isInVideoOptionMenu = false
        collectSelectedVideoOptionForDynamicSubtitles()
        videoToolbarViewController?.navigationController?.popViewControllerWithFadeAnimation()
        animator.animateGoingBackToMain()
    }
    
    //TODO: Remove it
    fileprivate func collectSelectedVideoOptionForDynamicSubtitles() {
        guard let viewController = navigationController?.topViewController else { return }
        switch viewController {
        case let vc as EffectsViewController:
            dynamicSubtitlesStyle = DynamicSubtitlesStyle(effect: vc.selectedEffect, font: dynamicSubtitlesStyle.font, color: dynamicSubtitlesStyle.color)
        case let vc as FontsViewController:
            dynamicSubtitlesStyle = DynamicSubtitlesStyle(effect: dynamicSubtitlesStyle.effect, font: vc.selectedFont, color: dynamicSubtitlesStyle.color)
        case let vc as ColorsViewController:
            dynamicSubtitlesStyle = DynamicSubtitlesStyle(effect: dynamicSubtitlesStyle.effect, font: dynamicSubtitlesStyle.font, color: vc.selectedColor)
        default: ()
        }
    }
}

extension VideoToolbarCoordinator: VideoToolbarViewControllerDelegate {
    func willEnterToVideoOptionMenu(videoOptionMenu: VideoOptionMenu) {
        isInVideoOptionMenu = true
        animator.animateGoingToVideoOptionMenu()
        if let viewController = navigationController?.storyboard?.viewController(forVideoOptionMenu: videoOptionMenu) {
            viewController.handler = self
            navigationController?.pushViewControllerWithFadeAnimation(viewController)
        }
    }
}

extension VideoToolbarCoordinator: ModifiedDynamicSubtitlesHandler {
    func handle(_ modification: DynamicSubtitlesModification) {
        switch modification {
        case .effect(let dynamicSubtitlesType):
            dynamicSubtitlesStyle = DynamicSubtitlesStyle(effect: dynamicSubtitlesType, font: dynamicSubtitlesStyle.font, color: dynamicSubtitlesStyle.color)
        case .color(let color):
            dynamicSubtitlesStyle = DynamicSubtitlesStyle(effect: dynamicSubtitlesStyle.effect, font: dynamicSubtitlesStyle.font, color: color)
        case .font(let font):
            dynamicSubtitlesStyle = DynamicSubtitlesStyle(effect: dynamicSubtitlesStyle.effect, font: font, color: dynamicSubtitlesStyle.color)
        }
    }
}
