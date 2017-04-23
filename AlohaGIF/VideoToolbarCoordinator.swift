//
//  VideoToolbarCoordinator.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

struct DynamicSubtitlesStyle {
    let effect: DynamicSubtitlesType
    let font: UIFont
    let color: UIColor
}

final class VideoToolbarCoordinator {
    
    weak var navigationController: UINavigationController?
    fileprivate var isInVideoOptionMenu = false
    var dynamicSubtitlesStyle = DynamicSubtitlesStyle(effect: DynamicSubtitlesType.oneAfterAnother, font: UIFont.boldSystemFont(ofSize: 16.0), color: .white)
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
    
    private func collectSelectedVideoOptionForDynamicSubtitles() {
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
            navigationController?.pushViewControllerWithFadeAnimation(viewController)
        }
    }
}
