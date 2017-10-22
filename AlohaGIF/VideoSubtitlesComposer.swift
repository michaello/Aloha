//
//  VideoSubtitlesComposer.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 18/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import AVFoundation

enum VideoCompositionError: Error {
    case noAudio
    case noVideo
}

final class VideoSubtitlesComposer {
    
    private enum Constants {
        static let exportQuality = AVAssetExportPresetHighestQuality
        static let exportedVideoTitle = "finalVideo"
        static let exportedVideoExtension = ".mov"
        static let compositionFrameDuration = CMTime(value: 1, timescale: 30)
    }
    
    private var dynamicSubtitlesComposer: DynamicSubtitlesComposer?
    
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
            
            let mainComposition = self.mainComposition(videoAsset: asset, videoTrack: videoTrack)
            let dynamicSubtitlesContext = DynamicSubtitlesContext.videoComposition(mainComposition)
            self.dynamicSubtitlesComposer = DynamicSubtitlesComposer(dynamicSubtitlesStyle: dynamicSubtitlesVideo.dynamicSubtitlesStyle, dynamicSubtitlesContext: dynamicSubtitlesContext)
            self.dynamicSubtitlesComposer?.applyDynamicSubtitles(speechArray: dynamicSubtitlesVideo.speechArray, size: self.naturalSize(for: videoTrack))
            self.beginExportSession(composition: mixComposition, mainCompositionWithInstructions: mainComposition) { url in
                DispatchQueue.main.async {
                    Logger.debug("Successfully exported video with dynamic subtitles.")
                    fulfill(url)
                }
            }
        })
    }
    
    private func mainComposition(videoAsset: AVAsset, videoTrack: AVMutableCompositionTrack) -> AVMutableVideoComposition {
        let compositionInstruction = self.compositionInstruction(videoAsset: videoAsset, videoTrack: videoTrack)
        let mainComposition = AVMutableVideoComposition()
        
        mainComposition.renderSize = naturalSize(for: videoTrack)
        mainComposition.instructions = [compositionInstruction]
        mainComposition.frameDuration = Constants.compositionFrameDuration
        
        return mainComposition
    }
    
    private func compositionInstruction(videoAsset: AVAsset, videoTrack: AVMutableCompositionTrack) -> AVMutableVideoCompositionInstruction {
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        videoLayerInstruction.setOpacity(0.0, at: videoAsset.duration)
        instruction.layerInstructions = [videoLayerInstruction]
        if let video = videoAsset.tracks(withMediaType: AVMediaTypeVideo).first {
            videoLayerInstruction.setTransform(video.preferredTransform, at: kCMTimeZero)
        }
        
        return instruction
    }
    
    private func naturalSize(for video: AVAssetTrack) -> CGSize {
        if video.videoAssetOrientation.isPortrait {
            return CGSize(width: video.naturalSize.height, height: video.naturalSize.width)
        } else {
            return video.naturalSize
        }
    }
    
    private func beginExportSession(composition: AVMutableComposition, mainCompositionWithInstructions: AVMutableVideoComposition, completion: @escaping (URL) -> ()) {
        let videoURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(Constants.exportedVideoTitle)\(UUID().uuidString)\(Constants.exportedVideoExtension)")
        let exportSession = AVAssetExportSession(asset: composition, presetName: Constants.exportQuality)
        exportSession?.outputURL = videoURL
        exportSession?.outputFileType = AVFileTypeQuickTimeMovie
        exportSession?.videoComposition = mainCompositionWithInstructions
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.exportAsynchronously(completionHandler: {
            completion(videoURL)
        })
    }
}
