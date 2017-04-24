//
//  DynamicSubtitlesVideo.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 25/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import AVFoundation

struct DynamicSubtitlesVideo {
    let video: AVAsset
    let speechArray: [SpeechModel]
    let dynamicSubtitlesStyle: DynamicSubtitlesStyle
}
