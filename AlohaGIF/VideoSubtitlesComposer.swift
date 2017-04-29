//
//  VideoSubtitlesComposer.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 18/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit
import AVFoundation

enum VideoCompositionError: Error {
    case noAudio
    case noVideo
}

struct VideoSubtitlesComposer {
    
    let exportQuality = AVAssetExportPresetHighestQuality
    
    func composeVideoWithDynamicSubtitlesPromise(dynamicSubtitlesVideo: DynamicSubtitlesVideo) -> Promise<URL> {
        return Promise<URL>(work: { fulfill, reject in
            let asset = dynamicSubtitlesVideo.video
            let mixComposition = AVMutableComposition()
            let videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
            let audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
            let clipAudioTrack = asset.tracks(withMediaType: AVMediaTypeAudio).first
            let assetDuration = CMTimeRangeMake(kCMTimeZero, asset.duration)
            guard let clip = clipAudioTrack else {
                Logger.error("No audio during video/audio composition.")
                reject(VideoCompositionError.noAudio)
                return
            }
            guard let video = asset.tracks(withMediaType: AVMediaTypeVideo).first else {
                Logger.error("No video during video/audio composition.")
                reject(VideoCompositionError.noVideo)
                return
            }
            do {
                try audioTrack.insertTimeRange(assetDuration, of: clip, at: kCMTimeZero)
            } catch {
                Logger.error("No audio during video/audio composition.")
                reject(VideoCompositionError.noAudio)
                return
            }
            do {
                try videoTrack.insertTimeRange(assetDuration, of: video, at: kCMTimeZero)
            } catch {
                Logger.error("No video during video/audio composition.")
                reject(VideoCompositionError.noVideo)
                return
            }
            
            let mainInstruction = AVMutableVideoCompositionInstruction()
            mainInstruction.timeRange = assetDuration
            let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            videoLayerInstruction.setTransform(video.preferredTransform, at: kCMTimeZero)
            videoLayerInstruction.setOpacity(0.0, at: asset.duration)
            mainInstruction.layerInstructions = [videoLayerInstruction]
            let mainCompositionInst = AVMutableVideoComposition()
            
            var naturalSize = CGSize.zero
            if video.videoAssetOrientation.isPortrait {
                naturalSize = CGSize(width: video.naturalSize.height, height: video.naturalSize.width)
            } else {
                naturalSize = video.naturalSize
            }
            
            mainCompositionInst.renderSize = CGSize(width: naturalSize.width, height: naturalSize.height)
            mainCompositionInst.instructions = [mainInstruction]
            mainCompositionInst.frameDuration = CMTime(value: 1, timescale: 30)
            let dynamicSubtitlesContext = DynamicSubtitlesContext.videoComposition(mainCompositionInst)
            DynamicSubtitlesComposer().applyDynamicSubtitles(to: dynamicSubtitlesContext, speechArray: dynamicSubtitlesVideo.speechArray, dynamicSubtitlesStyle: dynamicSubtitlesVideo.dynamicSubtitlesStyle, size: naturalSize)
            //TODO: name collision?
            self.beginExportSession(composition: mixComposition, mainCompositionWithInstructions: mainCompositionInst) { url in
                DispatchQueue.main.async {
                    Logger.debug("Successfully exported video with dynamic subtitles.")
                    fulfill(url)
                }
            }
        })
    }
    
    private func beginExportSession(composition: AVMutableComposition, mainCompositionWithInstructions: AVMutableVideoComposition, completion: @escaping (URL) -> ()) {
        let videoURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("finalVideo\(arc4random() % 100000).mov")
        let exportSession = AVAssetExportSession(asset: composition, presetName: self.exportQuality)
        exportSession?.outputURL = videoURL
        exportSession?.outputFileType = AVFileTypeQuickTimeMovie
        exportSession?.videoComposition = mainCompositionWithInstructions
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.exportAsynchronously(completionHandler: {
            completion(videoURL)
        })
    }
}
