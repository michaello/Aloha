//
//  DynamicSubtitlesContext.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 16/10/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import AVFoundation
import UIKit.UIView

enum AnimationDestination {
    case preview
    case movie
}

enum DynamicSubtitlesContext: Equatable {
    case view(UIView)
    case videoComposition(AVMutableVideoComposition)
    
    var destination: AnimationDestination {
        switch self {
        case .view:
            return .preview
        default:
            return .movie
        }
    }
    
    public static func ==(lhs: DynamicSubtitlesContext, rhs: DynamicSubtitlesContext) -> Bool {
        switch (lhs, rhs) {
        case (.view, .view), (.videoComposition, .videoComposition):
            return true
        default:
            return false
        }
    }
}
