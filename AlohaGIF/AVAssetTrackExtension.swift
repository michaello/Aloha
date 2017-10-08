//
//  AVAssetTrackExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 27/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import AVFoundation
import UIKit

extension AVAssetTrack {
    var videoAssetOrientation: (orientation: UIImageOrientation, isPortrait: Bool) {
        let videoTransform = preferredTransform
        var videoAssetOrientation = UIImageOrientation.up
        var isVideoAssetPortrait = false
        if (videoTransform.a == 0.0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0.0) {
            videoAssetOrientation = .right
            isVideoAssetPortrait = true
        }
        if (videoTransform.a == 0.0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0.0) {
            videoAssetOrientation = .left
            isVideoAssetPortrait = true
        }
        if (videoTransform.a == 1.0 && videoTransform.b == 0.0 && videoTransform.c == 0.0 && videoTransform.d == 1.0) {
            videoAssetOrientation =  .up
        }
        if (videoTransform.a == -1.0 && videoTransform.b == 0.0 && videoTransform.c == 0.0 && videoTransform.d == -1.0) {
            videoAssetOrientation = .down
        }
        
        return (videoAssetOrientation, isVideoAssetPortrait)
    }
}
