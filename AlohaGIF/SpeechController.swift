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
    
    func detectSpeech(from asset: AVAsset) {
        audioExtractor.temporaryAudioFromVideoURL()
            .then { url in
                self.audioExtractor.writeAudioPromise(with: asset, to: url)
            }
            .then { url in
                self.speechRecognizer.detectSpeechPromise(from: url)
            }
            .then { speechInfo in
                print(speechInfo)
            }
            .catch { error in
                print(error)
            }
    }
}
