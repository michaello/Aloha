//
//  UIVideoEditorController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 08/10/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

extension UIVideoEditorController {
    static func defaultController(maximumDuration: TimeInterval, delegate: UIVideoEditorControllerDelegate & UINavigationControllerDelegate, videoPath: String) -> UIVideoEditorController {
        let videoEditorController = UIVideoEditorController()
        videoEditorController.videoMaximumDuration = maximumDuration
        videoEditorController.videoQuality = .typeMedium
        videoEditorController.delegate = delegate
        videoEditorController.videoPath = videoPath
        
        return videoEditorController
    }
}

