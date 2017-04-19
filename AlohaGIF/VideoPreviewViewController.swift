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
    
    var selectedVideo: AVAsset! = AVURLAsset(url: Bundle.main.url(forResource: resourceName, withExtension: "MOV")!)
    private let player = AVQueuePlayer()
    private lazy var playerLayer: AVPlayerLayer = AVPlayerLayer(player: self.player)
    private lazy var playerItem: AVPlayerItem = AVPlayerItem(asset: self.selectedVideo)
    private lazy var playerLooper: AVPlayerLooper = AVPlayerLooper(player: self.player, templateItem: self.playerItem)
    private var observerContext = 0
    var shouldShowOverlayText = true
    var redView: UIView!
    var subtitlesRedView: UIView!
    var blueView: UIView!
    var subtitlesInitialPointCenter: CGPoint!

    override func viewDidLoad() {
        super.viewDidLoad()
        playerLayer.frame = CGRect(origin: .zero, size: view.frame.size)
        self.view.layer.addSublayer(playerLayer)
        player.play()
        playerLooper.addObserver(self, forKeyPath: "loopCount", options: [.new, .old], context: &observerContext)
        if shouldShowOverlayText {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.5) {
                self.debugAction(UIButton())
            }
        }
        guard shouldShowOverlayText else { return }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            let baz = self.selectedVideo.tracks(withMediaType: AVMediaTypeVideo).first?.naturalSize
            var isVerticalVideo = true
            if isVerticalVideo {
                aScale = baz!.width / self.playerLayer.videoRect.height
            } else {
                aScale = baz!.height / self.playerLayer.videoRect.height
            }
            self.baz(frame: self.playerLayer.videoRect)
        }
    }
    
    func baz(frame: CGRect) {
            redView = UIView(frame: view.frame)
            redView.backgroundColor = .clear
            subtitlesRedView = UIView(frame: view.frame)
            subtitlesRedView.frame = subtitlesRedView.frame
            let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(VideoPreviewViewController.foo))
            subtitlesRedView.addGestureRecognizer(panRecognizer)
            redView.addSubview(subtitlesRedView)
            subtitlesInitialPointCenter = subtitlesRedView.center
            let scrollView = UIScrollView(frame: view.frame)
            scrollView.isPagingEnabled = true
            scrollView.bounces = false
            var array = [SpeechModel]()
            "TSA is it turning phone and are plenty of awesome new things about it but one thing that kind of went on the radar I need to know if it was Ashley said during the announcement".components(separatedBy: " ").enumerated().forEach {
                index, text in
                var time = Double(index) * 0.1
                array.append(SpeechModel(duration: 0.2, timestamp: TimeInterval(time), content: text))
            }
    
        DynamicSubtitlesComposer().applyDynamicSubtitles(to: DynamicSubtitlesContext.view(subtitlesRedView), speechArray: array, size: frame.size, delegate: self)
            blueView = UIView(frame: CGRect(x: view.frame.size.width, y: 0.0, width: scrollView.frame.size.width, height: scrollView.frame.height))
            blueView.backgroundColor = .blue
            scrollView.addSubview(redView)
            scrollView.contentSize = CGSize(width: scrollView.frame.size.width * 2, height: scrollView.frame.height)
            view.addSubview(scrollView)
    }
    
    @objc func foo(sender: UIPanGestureRecognizer) {
        if sender.state == .began || sender.state == .changed {
            let translation = sender.translation(in: subtitlesRedView)
            if let contains = subtitlesRedView.layer.sublayers?.first!.frame.contains(translation) {
            }
            aOffsetX = -(-subtitlesInitialPointCenter.x + subtitlesRedView.center.x) * aScale
            aOffsetY = -(-subtitlesInitialPointCenter.y + subtitlesRedView.center.y) * aScale

            sender.view!.center = CGPoint(x: sender.view!.center.x + translation.x, y: sender.view!.center.y + translation.y)
            sender.setTranslation(CGPoint.zero, in: subtitlesRedView)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if let newValue = change?[.newKey] as? Int {
            Logger.verbose("Replayed movie \(selectedVideo.description). Count: \(newValue)")
        }
    }
    
    
    @IBAction func debugAction(_ sender: UIButton) {
        let videoPreviewViewController = self.storyboard?.instantiateViewController(withIdentifier: String(describing: CameraViewController.self)) as! CameraViewController
        present(videoPreviewViewController, animated: true, completion: nil)
    }
}

extension VideoPreviewViewController: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        var array = [SpeechModel]()
        "TSA is it turning phone and are plenty of awesome new things about it but one thing that kind of went on the radar I need to know if it was Ashley said during the announcement".components(separatedBy: " ").enumerated().forEach {
            index, text in
            var time = Double(index) * 0.1
            array.append(SpeechModel(duration: 0.2, timestamp: TimeInterval(time), content: text))
        }
        subtitlesRedView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        DynamicSubtitlesComposer().applyDynamicSubtitles(to: DynamicSubtitlesContext.view(subtitlesRedView), speechArray: array, size: subtitlesRedView.bounds.size, delegate: self)
    }
}
