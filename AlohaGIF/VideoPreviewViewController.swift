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
    
    private struct Constants {
        static let loopCountPath = "loopCount"
    }
    
    @IBOutlet private weak var arrowButton: UIButton!
    @IBOutlet private weak var movieToolbarBackgroundContainerView: UIVisualEffectView!
    @IBOutlet private weak var movieToolbarContainerView: UIView!
    @IBOutlet private weak var playerView: UIView!
    
    var selectedVideo: AVAsset!
    var speechArray = [SpeechModel]()
    private lazy var videoToolbarCoordinator: VideoToolbarCoordinator = VideoToolbarCoordinator(selectedVideo: self.selectedVideo)
    private let dynamicSubtitlesComposer = DynamicSubtitlesComposer()
    private let player = AVQueuePlayer()
    private lazy var playerLayer: AVPlayerLayer = AVPlayerLayer(player: self.player)
    private lazy var playerItem: AVPlayerItem = AVPlayerItem(asset: self.selectedVideo)
    private lazy var playerLooper: AVPlayerLooper = AVPlayerLooper(player: self.player, templateItem: self.playerItem, timeRange: CMTimeRange(start: kCMTimeZero, duration: self.selectedVideo.duration - CMTimeMake(1, 100))) //subtract 1/100 of second to avoid flickering of AVPlayerLooper
    private var observerContext = 0
    private var shouldShowOverlayText = true
    fileprivate var dynamicSubtitlesView: OverlayView!
    private var subtitlesInitialPointCenter: CGPoint!
    var dynamicSubtitlesStyle: DynamicSubtitlesStyle = .default
    var wasAlreadyPlayed = false
    var currentTimeOfPreviewMovie: Double {
        return playerLooper.loopingPlayerItems
            .map { $0.currentTime().seconds }
            .filter { $0 > 0.0 }
            .sorted()
            .first ?? 0.0
    }
    var dynamicSubtitlesVideo: DynamicSubtitlesVideo {
        return DynamicSubtitlesVideo(video: selectedVideo, speechArray: speechArray, dynamicSubtitlesStyle: videoToolbarCoordinator.dynamicSubtitlesStyle)
    }

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
        view.backgroundColor = .red
        addObservers()
        videoToolbarCoordinator.delegate = self
        arrowButton.addTarget(videoToolbarCoordinator, action: #selector(VideoToolbarCoordinator.arrowButtonAction(_:)), for: .touchUpInside)
        view.subviews.flatMap { $0 as? UIButton }.forEach {
            $0.touchAreaEdgeInsets = UIEdgeInsets(top: -20, left: -20, bottom: -10, right: -20)
        }
        videoToolbarCoordinator.passViewsToAnimate(arrowButton: arrowButton, movieToolbarBackgroundContainerView: movieToolbarBackgroundContainerView, movieToolbarContainerView: movieToolbarContainerView)
        playerLayer.frame = CGRect(origin: .zero, size: playerView.frame.size)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        playerView.layer.addSublayer(playerLayer)
        player.play()
        playerLooper.addObserver(self, forKeyPath: Constants.loopCountPath, options: [.new, .old], context: &observerContext)
        guard shouldShowOverlayText else { return }
        //TODO: Refactor
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            guard let videoTrack = self.selectedVideo.tracks(withMediaType: AVMediaTypeVideo).first else { return }
            let videoSize = videoTrack.naturalSize
            if videoTrack.videoAssetOrientation.isPortrait {
                aScale = videoSize.width / self.playerLayer.videoRect.height
            } else {
                aScale = videoSize.height / self.playerLayer.videoRect.height
            }
            self.addDynamicSubtitlesViewAndApplySubtitles()
            self.wasAlreadyPlayed = true
        }
    }
    
    func addDynamicSubtitlesViewAndApplySubtitles() {
        dynamicSubtitlesView = OverlayView(frame: view.frame)
        dynamicSubtitlesView.videoToolbarView = movieToolbarContainerView
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(VideoPreviewViewController.dynamicSubtitlesViewDidMove))
        dynamicSubtitlesView.addGestureRecognizer(panRecognizer)
        view.addSubview(dynamicSubtitlesView)
        subtitlesInitialPointCenter = dynamicSubtitlesView.center
        
        dynamicSubtitlesComposer.applyDynamicSubtitles(to: DynamicSubtitlesContext.view(dynamicSubtitlesView), speechArray: speechArray, dynamicSubtitlesStyle: self.dynamicSubtitlesStyle, size: dynamicSubtitlesView.bounds.size)
    }
    
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        player.remove(playerItem)
        playerLooper.disableLooping()
        dynamicSubtitlesView.isHidden = true
        dismiss(animated: true)
    }
    
    @objc private func muteSound() {
        player.isMuted = true
    }
    
    @objc private func unmuteSound() {
        player.isMuted = false
    }
    
    @objc private func dynamicSubtitlesViewDidMove(sender: UIPanGestureRecognizer) {
        if sender.state == .began || sender.state == .changed {
            let translation = sender.translation(in: dynamicSubtitlesView)
            aOffsetX = -(-subtitlesInitialPointCenter.x + dynamicSubtitlesView.center.x) * aScale
            aOffsetY = -(-subtitlesInitialPointCenter.y + dynamicSubtitlesView.center.y) * aScale

            sender.view!.center = CGPoint(x: sender.view!.center.x + translation.x, y: sender.view!.center.y + translation.y)
            sender.setTranslation(.zero, in: dynamicSubtitlesView)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if let newValue = change?[.newKey] as? Int {
            Logger.verbose("Replayed movie \(selectedVideo.description). Count: \(newValue)")
            presentDynamicSubtitlesOverlay(dynamicSubtitlesStyle, shouldPresentSubtitlesFromBeginning: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationController = segue.destination as? UINavigationController, let videoToolbarViewController = navigationController.topViewController as? VideoToolbarViewController else { return }
        videoToolbarCoordinator.videoToolbarViewController = videoToolbarViewController
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
    
    //TODO: For debug purposes only to check whether dynamic subtitles on video have correct position like in preview
    fileprivate func presentVideoPreviewViewController(with asset: AVAsset, speechArray: [SpeechModel]? = nil) {
        let videoPreviewViewController = self.storyboard?.instantiateViewController(withIdentifier: String(describing: VideoPreviewViewController.self)) as! VideoPreviewViewController
        videoPreviewViewController.shouldShowOverlayText = false
        videoPreviewViewController.selectedVideo = asset
        if let speechArray = speechArray {
            videoPreviewViewController.speechArray = speechArray
        }
        present(videoPreviewViewController, animated: true)
    }
    
    fileprivate func presentDynamicSubtitlesOverlay(_ dynamicSubtitlesStyle: DynamicSubtitlesStyle, shouldPresentSubtitlesFromBeginning: Bool = false) {
        guard UIDevice.isNotSimulator else { return }
            self.dynamicSubtitlesStyle = dynamicSubtitlesStyle
        dynamicSubtitlesView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let startTime = shouldPresentSubtitlesFromBeginning ? 0.0 : currentTimeOfPreviewMovie
        dynamicSubtitlesComposer.applyDynamicSubtitles(to: DynamicSubtitlesContext.view(dynamicSubtitlesView), speechArray: speechArray, dynamicSubtitlesStyle: self.dynamicSubtitlesStyle, size: dynamicSubtitlesView.bounds.size, startTime: startTime)
    }
    
    //TODO: It makes analysis once again, and we already know about speech, so later is should just apply subtitles into AVAsset.
    private func exportVideoToDynamicSubtitlesVideo() {
        let speechController = SpeechController()
        speechController.createVideoWithDynamicSubtitles(from: dynamicSubtitlesVideo, completion: { url in
            DispatchQueue.main.async {
                self.player.remove(self.playerItem)
                self.playerLooper.disableLooping()
                ALLoadingView.manager.hideLoadingView()
                self.presentVideoPreviewViewController(with: AVURLAsset(url: url))
            }
        })
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(VideoPreviewViewController.muteSound), name: .muteNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VideoPreviewViewController.pausePreviewWhenInBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VideoPreviewViewController.resumePreviewWhenInForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VideoPreviewViewController.unmuteSound), name: .unmuteNotification, object: nil)
    }
    
    @objc private func pausePreviewWhenInBackground() {
        player.pause()
    }

    @objc private func resumePreviewWhenInForeground() {
        playerLayer = AVPlayerLayer(player: player)
        player.play()
    }
    
    deinit {
        playerLooper.removeObserver(self, forKeyPath: Constants.loopCountPath, context: &observerContext)
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
        return dynamicSubtitlesVideo
    }
    
    private func revertToInitialDynamicSubtitlesViewPosition() {
        dynamicSubtitlesView.frame = view.frame
        aOffsetX = 0.0
        aOffsetY = 0.0
    }
}
