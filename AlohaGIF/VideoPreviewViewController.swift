//
//  VideoPreviewViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 17/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit
import AVFoundation

final class VideoPreviewViewController: UIViewController {
    
    private enum Constants {
        static let loopCountKeyPath = #keyPath(AVPlayerLooper.loopCount)
        static let isReadyForDisplayKeyPath = #keyPath(AVPlayerLayer.isReadyForDisplay)
        static let increasedTouchInsets = UIEdgeInsets(top: -20.0, left: -20.0, bottom: -10.0, right: -20.0)
    }
    
    @IBOutlet private weak var arrowButton: UIButton!
    @IBOutlet private weak var movieToolbarBackgroundContainerView: UIVisualEffectView!
    @IBOutlet private weak var movieToolbarContainerView: UIView!
    @IBOutlet private weak var playerView: UIView!
    
    var selectedVideo: AVAsset!
    var speechArray = [SpeechModel]()
    fileprivate lazy var videoToolbarCoordinator: VideoToolbarCoordinator = VideoToolbarCoordinator(selectedVideo: self.selectedVideo)
    private var dynamicSubtitlesComposer: DynamicSubtitlesComposer?
    
    private let player = AVQueuePlayer()
    private lazy var playerLayer = AVPlayerLayer(player: self.player)
    private lazy var playerItem = AVPlayerItem(asset: self.selectedVideo)
    private lazy var playerLooper = AVPlayerLooper(player: self.player, templateItem: self.playerItem, timeRange: self.loopingDurationTimeRange())
    private var loopContext = 0
    private var isReadyContext = 0
    
    var dynamicSubtitlesStyle: DynamicSubtitlesStyle = .default
    fileprivate var dynamicSubtitlesView: OverlayView?
    private var subtitlesInitialPointCenter: CGPoint?
    private var shouldShowOverlayText = true
    private var wasAlreadyPlayed = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if wasAlreadyPlayed {
            player.isMuted = false
            player.play()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addObservers()
        setupVideoToolbarCoordinator()
        setupButtons()
        setupPlayer()
        
        guard shouldShowOverlayText else { return }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &loopContext {
            guard let newValue = change?[.newKey] as? Int else { return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context) }
            Logger.verbose("Replayed movie \(selectedVideo.description). Count: \(newValue)")
            presentDynamicSubtitlesOverlay(dynamicSubtitlesStyle, shouldPresentSubtitlesFromBeginning: true)
        } else if context == &isReadyContext {
            playerLayer.removeObserver(self, forKeyPath: Constants.isReadyForDisplayKeyPath)
            prepareForSubtitlesPresentation()
        } else {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationController = segue.destination as? UINavigationController, let videoToolbarViewController = navigationController.topViewController as? VideoToolbarViewController else { return }
        videoToolbarCoordinator.videoToolbarViewController = videoToolbarViewController
    }
    
    func addDynamicSubtitlesViewAndApplySubtitles() {
        let subtitlesView = OverlayView(frame: view.frame)
        subtitlesView.videoToolbarView = movieToolbarContainerView
        subtitlesView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(VideoPreviewViewController.dynamicSubtitlesViewDidMove)))
        subtitlesInitialPointCenter = subtitlesView.center
        view.addSubview(subtitlesView)
        dynamicSubtitlesView = subtitlesView
        dynamicSubtitlesComposer = DynamicSubtitlesComposer(dynamicSubtitlesStyle: dynamicSubtitlesStyle, dynamicSubtitlesContext: DynamicSubtitlesContext.view(subtitlesView))
        dynamicSubtitlesComposer?.applyDynamicSubtitles(speechArray: speechArray, size: subtitlesView.bounds.size)
    }
    
    @IBAction func exportAction(_ sender: UIButton) {
        ALLoadingView.show()
        exportVideoToDynamicSubtitlesVideo()
    }
    
    @IBAction func debugAction(_ sender: UIButton) {
        player.remove(playerItem)
        playerLooper.disableLooping()
        dismiss(animated: true)
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        player.remove(playerItem)
        playerLooper.disableLooping()
        dynamicSubtitlesView?.isHidden = true
        dismiss(animated: true)
    }
    
    @objc private func muteSound() {
        player.isMuted = true
    }
    
    @objc private func unmuteSound() {
        player.isMuted = false
    }
    
    @objc private func dynamicSubtitlesViewDidMove(sender: UIPanGestureRecognizer) {
        guard let subtitlesInitialPointCenter = subtitlesInitialPointCenter, let dynamicSubtitlesView = dynamicSubtitlesView else { return }
        switch sender.state {
        case .began, .changed:
            SharedVariables.xOffset = -(-subtitlesInitialPointCenter.x + dynamicSubtitlesView.center.x) * SharedVariables.videoScale
            SharedVariables.yOffset = -(-subtitlesInitialPointCenter.y + dynamicSubtitlesView.center.y) * SharedVariables.videoScale
            
            let center = dynamicSubtitlesView.center
            let translation = sender.translation(in: dynamicSubtitlesView)
            dynamicSubtitlesView.center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            sender.setTranslation(.zero, in: dynamicSubtitlesView)
        default: ()
        }
    }
    
    @objc private func pausePreviewWhenInBackground() {
        player.pause()
    }
    
    @objc private func resumePreviewWhenInForeground() {
        playerLayer = AVPlayerLayer(player: player)
        player.play()
    }
    
    //TODO: For debug purposes only to check whether dynamic subtitles on video have correct position like in preview
    fileprivate func presentVideoPreviewViewController(with asset: AVAsset, speechArray: [SpeechModel]? = nil) {
        let videoPreviewViewController = UIStoryboard.viewController(VideoPreviewViewController.self)
        videoPreviewViewController.shouldShowOverlayText = false
        videoPreviewViewController.selectedVideo = asset
        if let speechArray = speechArray {
            videoPreviewViewController.speechArray = speechArray
        }
        present(videoPreviewViewController, animated: true)
    }
    
    fileprivate func presentDynamicSubtitlesOverlay(_ dynamicSubtitlesStyle: DynamicSubtitlesStyle, shouldPresentSubtitlesFromBeginning: Bool = false) {
        guard let dynamicSubtitlesView = dynamicSubtitlesView, UIDevice.isNotSimulator else { return }
            self.dynamicSubtitlesStyle = dynamicSubtitlesStyle
        dynamicSubtitlesView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let startTime = shouldPresentSubtitlesFromBeginning ? 0.0 : currentTimeOfPreviewMovie()
        dynamicSubtitlesComposer = DynamicSubtitlesComposer(dynamicSubtitlesStyle: dynamicSubtitlesStyle, dynamicSubtitlesContext: DynamicSubtitlesContext.view(dynamicSubtitlesView))
        dynamicSubtitlesComposer?.applyDynamicSubtitles(speechArray: speechArray, size: dynamicSubtitlesView.bounds.size, startTime: startTime)
    }
    
    private func prepareForSubtitlesPresentation() {
        setupVideoScale()
        addDynamicSubtitlesViewAndApplySubtitles()
        wasAlreadyPlayed = true
    }
    
    private func setupButtons() {
        arrowButton.addTarget(videoToolbarCoordinator, action: #selector(VideoToolbarCoordinator.arrowButtonAction(_:)), for: .touchUpInside)
        view.subviews.forEach { ($0 as? UIButton)?.touchAreaEdgeInsets = Constants.increasedTouchInsets }
    }
    
    private func setupPlayer() {
        playerLayer.frame = CGRect(origin: .zero, size: playerView.frame.size)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        playerView.layer.addSublayer(playerLayer)
        player.play()
        playerLooper.addObserver(self, forKeyPath: Constants.loopCountKeyPath, options: [.new, .old], context: &loopContext)
        playerLayer.addObserver(self, forKeyPath: Constants.isReadyForDisplayKeyPath, options: [.new, .old], context: &isReadyContext)
    }
    
    private func setupVideoToolbarCoordinator() {
        videoToolbarCoordinator.delegate = self
        videoToolbarCoordinator.passViewsToAnimate(arrowButton: arrowButton, movieToolbarBackgroundContainerView: movieToolbarBackgroundContainerView, movieToolbarContainerView: movieToolbarContainerView)
    }
    
    //TODO: It makes analysis once again, and we already know about speech, so later is should just apply subtitles into AVAsset.
    private func exportVideoToDynamicSubtitlesVideo() {
        let speechController = SpeechController()
        let dynamicSubtitlesVideo = DynamicSubtitlesVideo(video: selectedVideo, speechArray: speechArray, dynamicSubtitlesStyle: videoToolbarCoordinator.dynamicSubtitlesStyle)
        speechController.createVideoWithDynamicSubtitles(from: dynamicSubtitlesVideo, completion: { url in
            DispatchQueue.main.async {
                self.prepareForVideoPreviewPresentation()
                self.presentVideoPreviewViewController(with: AVURLAsset(url: url))
            }
        })
    }
    
    private func loopingDurationTimeRange() -> CMTimeRange {
        let oneHundrethOfSecond = CMTime(value: 1, timescale: 100) //subtract 1/100 of second to avoid flickering of AVPlayerLooper
        return CMTimeRange(start: kCMTimeZero, duration: selectedVideo.duration - oneHundrethOfSecond)
    }
    
    
    private func setupVideoScale() {
        guard let videoTrack = selectedVideo.tracks(withMediaType: AVMediaTypeVideo).first else { return }
        let videoSize = videoTrack.naturalSize
        if videoTrack.videoAssetOrientation.isPortrait {
            SharedVariables.videoScale = videoSize.width / playerLayer.videoRect.height
        } else {
            SharedVariables.videoScale = videoSize.height / playerLayer.videoRect.height
        }
    }
    
    private func prepareForVideoPreviewPresentation() {
        player.remove(playerItem)
        playerLooper.disableLooping()
        ALLoadingView.manager.hideLoadingView()
    }
    
    private func currentTimeOfPreviewMovie() -> Double {
        return playerLooper.loopingPlayerItems
            .map { $0.currentTime().seconds }
            .filter { $0 > 0.0 }
            .sorted()
            .first ?? 0.0
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(VideoPreviewViewController.muteSound), name: .muteNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VideoPreviewViewController.pausePreviewWhenInBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VideoPreviewViewController.resumePreviewWhenInForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VideoPreviewViewController.unmuteSound), name: .unmuteNotification, object: nil)
    }
    
    deinit {
        playerLooper.removeObserver(self, forKeyPath: Constants.loopCountKeyPath)
    }
}

extension VideoPreviewViewController: VideoToolbarCoordinatorDelegate {
    func dynamicSubtitlesStyleDidChange(_ dynamicSubtitlesStyle: DynamicSubtitlesStyle, modification: DynamicSubtitlesModification) {
        if case .effect = modification {
            revertToInitialDynamicSubtitlesViewPosition()
        }
        presentDynamicSubtitlesOverlay(dynamicSubtitlesStyle)
    }
    
    func dynamicSubtitlesVideoForRendering() -> DynamicSubtitlesVideo {
        return DynamicSubtitlesVideo(video: selectedVideo, speechArray: speechArray, dynamicSubtitlesStyle: videoToolbarCoordinator.dynamicSubtitlesStyle)
    }
    
    private func revertToInitialDynamicSubtitlesViewPosition() {
        dynamicSubtitlesView?.frame = view.frame
        SharedVariables.xOffset = 0.0
        SharedVariables.yOffset = 0.0
    }
}
