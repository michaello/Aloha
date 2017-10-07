//
//  RegiftExtension.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 07/10/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import Foundation

extension Regift {

    static func createGif(from URL: URL, videoDurationInSeconds: Double, completion: (URL?) -> ()) {
        let frameCount = Int(videoDurationInSeconds * 15.0)
        Regift.createGIFFromSource(URL, frameCount: frameCount, delayTime: 0.08333, completion: completion)
    }
}

