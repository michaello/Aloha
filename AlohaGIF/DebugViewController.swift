//
//  DebugViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 24/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit
import AVFoundation
import FLAnimatedImage
import AVKit
import FBSDKMessengerShareKit

class DebugViewController: UIViewController {

    var gifURL: URL!
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
//        [self.webView loadRequest:[NSURLRequest requestWithURL:GifURL]];

//        let webView = UIWebView(frame: view.frame)
//        webView.scalesPageToFit = true
        /*
        let image = try! Data(contentsOf: gifURL)
        let gifImageView = FLAnimatedImageView()
        gifImageView.animatedImage = FLAnimatedImage(animatedGIFData: image)
        gifImageView.frame = view.frame
        container.addSubview(gifImageView)
//        webView.loadRequest(URLRequest.init(url: gifURL))
        
        let rec = UITapGestureRecognizer(target: self, action: #selector(DebugViewController.dismis))
//        rec.cancelsTouchesInView = true
//            self.playerLayer.frame = CGRect(origin: .zero, size: view.frame.size)
        gifImageView.addGestureRecognizer(rec)
//            container.layer.addSublayer(self.playerLayer)
//            self.player.play()
//        _ = playerLooper
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) { 
            let data = NSData(contentsOf: self.gifURL)
//            [FBSDKMessageDialog showWithContent:content delegate:nil];

            if let gif = data {
                FBSDKMessengerSharer.shareAnimatedGIF(gif as Data!, with: FBSDKMessengerShareOptions.init())
//                let shareActivityVC = UIActivityViewController(activityItems: [gif], applicationActivities: nil)
//                self.present(shareActivityVC, animated: true, completion: nil)
//
            }
        }
 */
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) { 
            self.dismis()
        }
    }
    
    func dismis() {
        dismiss(animated: true, completion: nil)
    }
}
