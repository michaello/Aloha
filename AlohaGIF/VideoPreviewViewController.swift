//
//  VideoPreviewViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 17/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPreviewViewController: UIViewController {
    
    var selectedVideo: AVAsset!
    private let player = AVQueuePlayer()
    private lazy var playerLayer: AVPlayerLayer = AVPlayerLayer(player: self.player)
    private lazy var playerItem: AVPlayerItem = AVPlayerItem(asset: self.selectedVideo)
    private lazy var playerLooper: AVPlayerLooper = AVPlayerLooper(player: self.player, templateItem: self.playerItem)
    private var observerContext = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        playerLayer.frame = CGRect(origin: .zero, size: view.frame.size)
        self.view.layer.addSublayer(playerLayer)
        player.play()
        playerLooper.addObserver(self, forKeyPath: "loopCount", options: [.new, .old], context: &observerContext)
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
}
