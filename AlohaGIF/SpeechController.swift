//
//  SpeechController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 18/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import Foundation
import AVFoundation

struct SpeechController {
    
    private let audioExtractor = AudioExtractor()
    private let speechRecognizer = SpeechRecognizer()
    private let videoSubtitlesComposer = VideoSubtitlesComposer()
    
    func detectSpeech(from asset: AVAsset, completion: @escaping (URL) -> ()) {
        audioExtractor.temporaryAudioFromVideoURL()
            .then { url in
                self.audioExtractor.writeAudioPromise(with: asset, to: url)
            }
            .then { url in
                self.speechRecognizer.detectSpeechPromise(from: url)
            }
            .then { speechModelArray in
                self.videoSubtitlesComposer.composeVideoWithDynamicSubtitlesPromise(asset: asset, speechArray: speechModelArray)
            }
            .then {
                completion($0)
            }
            .catch { error in
            }
    }
}
