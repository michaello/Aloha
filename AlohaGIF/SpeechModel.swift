//
//  SpeechModel.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 18/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import Speech

struct SpeechModel {
    
    let duration: TimeInterval
    let timestamp: TimeInterval
    let content: String
}

extension SpeechModel {
    init(segment: SFTranscriptionSegment) {
        self.duration = segment.duration
        self.timestamp = segment.timestamp
        self.content = segment.substring
    }
}
