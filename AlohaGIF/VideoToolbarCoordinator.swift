//
//  VideoToolbarCoordinator.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 23/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit
import AVFoundation

protocol VideoToolbarCoordinatorDelegate: class {
    func dynamicSubtitlesStyleDidChange(_ dynamicSubtitlesStyle: DynamicSubtitlesStyle)
    func dynamicSubtitlesVideoForRendering() -> DynamicSubtitlesVideo
}

final class VideoToolbarCoordinator {
    
    weak var navigationController: UINavigationController?
    weak var delegate: VideoToolbarCoordinatorDelegate?
    weak var videoToolbarViewController: VideoToolbarViewController? {
        didSet {
            videoToolbarViewController?.delegate = self
            navigationController = videoToolbarViewController?.navigationController
        }
    }
    var dynamicSubtitlesStyle = DynamicSubtitlesStyle.default {
        didSet {
            delegate?.dynamicSubtitlesStyleDidChange(dynamicSubtitlesStyle)
        }
    }
    fileprivate let selectedVideo: AVAsset
    fileprivate var isInVideoOptionMenu = false
    fileprivate var animator = VideoToolbarAnimator()
    private var isCollapsed = false {
        didSet {
            isCollapsed ? animator.animateHidden() : animator.animateVisible()
        }
    }
    
    init(selectedVideo: AVAsset) {
        self.selectedVideo = selectedVideo
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
        guard videoOptionMenu != .complete else { return exportToVideoWithDynamicSubtitles() }
        isInVideoOptionMenu = true
        animator.animateGoingToVideoOptionMenu()
        if let viewController = navigationController?.storyboard?.viewController(forVideoOptionMenu: videoOptionMenu) {
            viewController.handler = self
            navigationController?.pushViewControllerWithFadeAnimation(viewController)
        }
    }
    
    private func presentRenderingLoadingView() {
        ALLoadingView.manager.blurredBackground = true
        ALLoadingView.manager.messageText = "👽👽👽 ayy lmao"
        ALLoadingView.manager.showLoadingView(ofType: .messageWithIndicator, windowMode: .fullscreen)
    }
    
    private func exportToVideoWithDynamicSubtitles() {
        guard let dynamicSubtitlesVideo = delegate?.dynamicSubtitlesVideoForRendering() else { return }
        presentRenderingLoadingView()
        let speechController = SpeechController()
        speechController.createVideoWithDynamicSubtitles(from: dynamicSubtitlesVideo, completion: { url in
            DispatchQueue.main.async {
                ALLoadingView.manager.hideLoadingView()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
                    if let foo = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController as? VideoPreviewViewController {
                        let debug = foo.storyboard!.instantiateViewController(withIdentifier: "DebugViewController") as! DebugViewController
                        debug.exportedVideo = AVURLAsset(url: url)
                        foo.present(debug, animated: true, completion: nil)
                    }
                })
            }
        })
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
