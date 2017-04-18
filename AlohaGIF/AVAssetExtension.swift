//
//  AVAssetExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 17/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import AVFoundation

extension AVAsset {
    func writeAudioTrack(to url: URL, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        do {
            let asset = try audioAsset()
            asset.write(to: url, success: success, failure: failure)
        } catch {
            failure(error)
        }
    }
    
    private func write(to url: URL, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        guard let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetAppleM4A) else {
            let error = NSError(domain: "domain", code: 0, userInfo: nil)
            failure(error)
            
            return
        }
        
        exportSession.outputFileType = AVFileTypeAppleM4A
        exportSession.outputURL = url
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                success()
            case .unknown, .failed, .cancelled:
                let error = NSError(domain: "domain", code: 0, userInfo: nil)
                failure(error)
            default: ()
            }
        }
    }
    
    private func audioAsset() throws -> AVAsset {
        let composition = AVMutableComposition()
        let audioTracks = tracks(withMediaType: AVMediaTypeAudio)
        
        for track in audioTracks {
            let compositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try compositionTrack.insertTimeRange(track.timeRange, of: track, at: track.timeRange.start)
            } catch {
                throw error
            }
            compositionTrack.preferredTransform = track.preferredTransform
        }
        
        return composition
    }
}
