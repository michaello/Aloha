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
    func dynamicSubtitlesStyleDidChange(_ dynamicSubtitlesStyle: DynamicSubtitlesStyle, modification: DynamicSubtitlesModification)
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
    var dynamicSubtitlesStyle = DynamicSubtitlesStyle.default
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
        videoToolbarViewController?.navigationController?.popViewControllerWithFadeAnimation()
        animator.animateGoingBackToMain()
    }
}

extension VideoToolbarCoordinator: VideoToolbarViewControllerDelegate {
    func willEnterToVideoOptionMenu(videoOptionMenu: VideoOptionMenu) {
        guard videoOptionMenu != .complete else { return exportToVideoWithDynamicSubtitles() }
        isInVideoOptionMenu = true
        animator.animateGoingToVideoOptionMenu()
        if let viewController = navigationController?.storyboard?.viewController(forVideoOptionMenu: videoOptionMenu, dynamicSubtitlesStyle: dynamicSubtitlesStyle) {
            viewController.handler = self
            navigationController?.pushViewControllerWithFadeAnimation(viewController)
        }
    }
    
    fileprivate func presentRenderingLoadingView() {
        ALLoadingView.show()
    }
    
    private func exportToVideoWithDynamicSubtitles() {
        guard let dynamicSubtitlesVideo = delegate?.dynamicSubtitlesVideoForRendering() else { return }
        presentRenderingLoadingView()
        muteSoundInVideoPreview()
        let speechController = SpeechController()
        speechController.createVideoWithDynamicSubtitles(from: dynamicSubtitlesVideo, completion: { [unowned self] url in
            self.createGif(from: url)
        })
    }
    
    private func createGif(from URL: URL) {
        Regift.createGif(from: URL, videoDurationInSeconds: selectedVideo.duration.seconds) { url in
            DispatchQueue.main.async {
                guard let presentedViewController = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController else { return }
                    let previewViewController = UIStoryboard.viewController(GIFPreviewViewController.self)
                    previewViewController.gifURL = url
                    presentedViewController.present(previewViewController, animated: true, completion: nil)
            }
        }
    }
    
    //NotificationCenter is meh, but...
    private func muteSoundInVideoPreview() {
        NotificationCenter.default.post(name: .muteNotification, object: nil)
    }
}

extension VideoToolbarCoordinator: ModifiedDynamicSubtitlesHandler {
    func handle(_ modification: DynamicSubtitlesModification) {
        dynamicSubtitlesStyle = {
            switch modification {
            case .effect(let dynamicSubtitlesType):
                return DynamicSubtitlesStyle(effect: dynamicSubtitlesType, font: dynamicSubtitlesStyle.font, color: dynamicSubtitlesStyle.color)
            case .color(let color):
                return DynamicSubtitlesStyle(effect: dynamicSubtitlesStyle.effect, font: dynamicSubtitlesStyle.font, color: color)
            case .font(let font):
                return DynamicSubtitlesStyle(effect: dynamicSubtitlesStyle.effect, font: font, color: dynamicSubtitlesStyle.color)
            }
        }()

        delegate?.dynamicSubtitlesStyleDidChange(dynamicSubtitlesStyle, modification: modification)
    }
}
