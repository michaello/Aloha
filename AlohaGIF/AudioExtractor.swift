//
//  AudioExtractor.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 18/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import Foundation
import AVFoundation

struct AudioExtractor {
    
    func temporaryAudioFromVideoURL() -> Promise<URL> {
        return Promise<URL>(work: { fulfill, reject in
            let audioFromVideoURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("audio.m4a")
            
            if FileManager.default.fileExists(atPath: audioFromVideoURL.path) {
                do {
                    try FileManager.default.removeItem(atPath: audioFromVideoURL.path)
                    fulfill(audioFromVideoURL)
                }
                catch {
                    reject(error)
                }
            } else {
                fulfill(audioFromVideoURL)
            }
        })
    }
    
    func writeAudioPromise(with asset: AVAsset, to url: URL) -> Promise<URL> {
        return Promise<URL>(work: { fulfill, reject in
            asset.writeAudioTrack(to: url, success: {
                fulfill(url)
            }) { error in
                reject(error)
            }
        })
    }
}
