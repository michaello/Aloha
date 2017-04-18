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
    
    func foo(asset: AVAsset, completion: @escaping (URL) -> ()) throws {
        let mixComposition = AVMutableComposition()
        let videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let clipAudioTrack = asset.tracks(withMediaType: AVMediaTypeAudio).first
        let assetDuration = CMTimeRangeMake(kCMTimeZero, asset.duration)
        guard let clip = clipAudioTrack else { throw VideoCompositionError.noAudio }
        guard let video = asset.tracks(withMediaType: AVMediaTypeVideo).first else { throw VideoCompositionError.noVideo }
        do {
            try audioTrack.insertTimeRange(assetDuration, of: clip, at: kCMTimeZero)
        } catch {
            throw VideoCompositionError.noAudio
        }
        do {
            try videoTrack.insertTimeRange(assetDuration, of: video, at: kCMTimeZero)
        } catch {
            throw VideoCompositionError.noVideo
        }
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = assetDuration
        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let videoAssetOrientation = UIImageOrientation.up
        var isVideoAssetPortrait = false
        let videoTransform = video.preferredTransform
        videoLayerInstruction.setTransform(video.preferredTransform, at: kCMTimeZero)
        videoLayerInstruction.setOpacity(0.0, at: asset.duration)
        mainInstruction.layerInstructions = [videoLayerInstruction]
        let mainCompositionInst = AVMutableVideoComposition()
        var naturalSize = CGSize.zero
        isVideoAssetPortrait = self.videoAssetOrientation(assetTrack: video).isPortrait
        if isVideoAssetPortrait {
            naturalSize = CGSize(width: video.naturalSize.height, height: video.naturalSize.width)
        } else {
            naturalSize = video.naturalSize
        }
        mainCompositionInst.renderSize = CGSize(width: naturalSize.width, height: naturalSize.height)
        mainCompositionInst.instructions = [mainInstruction]
        mainCompositionInst.frameDuration = CMTime(value: 1, timescale: 30)
        //APPLY FONTS AND STUFF
        let videoURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("finalVideo\(arc4random() % 10000).mov")
        let exportSession = AVAssetExportSession(asset: mixComposition, presetName: exportQuality)
        exportSession?.outputURL = videoURL
        exportSession?.outputFileType = AVFileTypeQuickTimeMovie
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                completion(videoURL)
            }
        })
    }
    
    private func videoAssetOrientation(assetTrack: AVAssetTrack) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        let videoTransform = assetTrack.preferredTransform
        var videoAssetOrientation = UIImageOrientation.up
        var isVideoAssetPortrait = false
        if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
            videoAssetOrientation = .right
            isVideoAssetPortrait = true
        }
        if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
            videoAssetOrientation = .left
            isVideoAssetPortrait = true
        }
        if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
            videoAssetOrientation =  .up
        }
        if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
            videoAssetOrientation = .down
        }
        
        return (videoAssetOrientation, isVideoAssetPortrait)
    }
}
