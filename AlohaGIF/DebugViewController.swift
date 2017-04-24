//
//  DebugViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 24/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class DebugViewController: UIViewController {

    var exportedVideo: AVAsset!
    private let player = AVQueuePlayer()
    private lazy var playerLayer: AVPlayerLayer = AVPlayerLayer(player: self.player)
    private lazy var playerItem: AVPlayerItem = AVPlayerItem(asset: self.exportedVideo)
    private lazy var playerLooper: AVPlayerLooper = AVPlayerLooper(player: self.player, templateItem: self.playerItem)
    private var observerContext = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
            let container = UIView(frame: self.view.frame)
            self.view.addSubview(container)
            self.playerLayer.frame = CGRect(origin: .zero, size: view.frame.size)
            container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(DebugViewController.dismis)))
            container.layer.addSublayer(self.playerLayer)
            self.player.play()
        _ = playerLooper
    }
    
    func dismis() {
        dismiss(animated: true, completion: nil)
    }
}
