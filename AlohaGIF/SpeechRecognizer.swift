//
//  SpeechRecognizer.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 17/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import Speech

final class SpeechRecognizer {
    
    private lazy var recognizer: SFSpeechRecognizer = SFSpeechRecognizer(locale: Locale.current)!
    
    
    //Sometimes error [AFAggregator logDictationFailedWithError:] Error Domain=kAFAssistantErrorDomain Code=203 "Retry" is returned, so it should be retried
    func detectSpeechPromise(from audioURL: URL) -> Promise<[SpeechModel?]> {
        return Promise<[SpeechModel?]>(work: { fulfill, reject in
            self.recognizer.recognitionTask(with: self.request(url: audioURL), resultHandler: { result, recognizerError in
                if let recognizerError = recognizerError {
                    reject(recognizerError)
                }
                if let bestTranscription = result?.bestTranscription {
                    fulfill(self.transform(result: bestTranscription))
                }
            })
        })
    }
    
    private func transform(result: SFTranscription) -> [SpeechModel?] {
        return result.segments
            .flatMap { $0 }
            .map { SpeechModel(duration: $0.duration, timestamp: $0.timestamp, content: $0.substring)
            }
    }
    
    private func request(url: URL) -> SFSpeechURLRecognitionRequest {
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        return request
    }
}
