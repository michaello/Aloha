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
    
    private enum Constants {
        static let detectSpeechRetryCount = 3
        static let detectSpeechTimeout = 20.0
        static let detectSpeechDelay = 0.5
    }
    
    private let audioExtractor = AudioExtractor()
    private let speechRecognizer = SpeechRecognizer()
    private let videoSubtitlesComposer = VideoSubtitlesComposer()
    
    func createVideoWithDynamicSubtitles(from dynamicSubtitlesVideo: DynamicSubtitlesVideo, completion: @escaping (URL) -> ()) {
            videoSubtitlesComposer.composeVideoWithDynamicSubtitlesPromise(dynamicSubtitlesVideo: dynamicSubtitlesVideo)
            .then {
                completion($0)
            }
            .catch { error in
                Logger.error("Creating video with dynamic subtitles has failed, error: \(error.localizedDescription)")
            }
    }
    
    func detectSpeechPromise(from asset: AVAsset) -> Promise<[SpeechModel]> {
        return audioExtractor.temporaryAudioFromVideoURL()
            .then { url in
                self.audioExtractor.writeAudioPromise(with: asset, to: url)
            }
            .then { url in
                Promise<URL>.retry(count: Constants.detectSpeechRetryCount, delay: Constants.detectSpeechDelay) { self.speechRecognizer.detectSpeechPromise(from: url) }
            }
            .addTimeout(Constants.detectSpeechTimeout)
    }
}
