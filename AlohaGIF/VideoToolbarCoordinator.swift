//
//  VideoToolbarCoordinator.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

final class VideoToolbarCoordinator {
    
    weak var navigationController: UINavigationController?
    fileprivate var isInVideoOptionMenu = false
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
        videoToolbarViewController?.navigationController?.popViewControllerWithFadeAnimation()
        animator.animateGoingBackToMain()
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
