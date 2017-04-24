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
    
    func createVideoWithDynamicSubtitles(from dynamicSubtitlesVideo: DynamicSubtitlesVideo, completion: @escaping (URL) -> ()) {
            videoSubtitlesComposer.composeVideoWithDynamicSubtitlesPromise(dynamicSubtitlesVideo: dynamicSubtitlesVideo)
            .then {
                completion($0)
            }
            .catch { error in
        }
    }
    
    func detectSpeechPromise(from asset: AVAsset) -> Promise<[SpeechModel]> {
        return audioExtractor.temporaryAudioFromVideoURL()
            .then { url in
                self.audioExtractor.writeAudioPromise(with: asset, to: url)
            }
            .then { url in
                Promise<URL>.retry(count: 3, delay: 0.5) { self.speechRecognizer.detectSpeechPromise(from: url) }
            }
    }
}
