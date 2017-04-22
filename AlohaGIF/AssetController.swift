//
//  AssetController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 22/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import Photos
import AVFoundation

enum AssetControllerError: Error {
    case noVideo
}

struct AssetController {
    func AVAssetPromise(from video: PHAsset) -> Promise<AVAsset> {
        return Promise<AVAsset>(work: { fulfill, reject in
            PHImageManager.default().requestAVAsset(forVideo: video, options: nil) { asset, _, _ in
                DispatchQueue.main.async {
                    if let asset = asset {
                        fulfill(asset)
                    } else {
                        reject(AssetControllerError.noVideo)
                    }
                }
            }
        })
    }
}

