//
//  AnimationsComposer.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 18/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit
import AVFoundation

struct AnimationModel {
    let beginTime: TimeInterval
    let duration: TimeInterval
}

var shouldAlwaysShowSubtitles = false

struct AnimationsComposer {
    
    func zeroTimeAnimation(animationDestination: AnimationDestination) -> CFTimeInterval {
        return animationDestination == .preview ? CACurrentMediaTime() : AVCoreAnimationBeginTimeAtZero
    }

    func applyRevealAnimation(animationDestination: AnimationDestination, textLayersArrayToApply textLayers: [CATextLayer], speechModelArray: [SpeechModel], customDuration: TimeInterval? = nil, customSpeed: Float? = nil, lastTextLayerDelegate: CAAnimationDelegate? = nil) {
        let animationModels = self.animationModels(speechModelArray: speechModelArray)
        zip(textLayers, animationModels).forEach { textLayer, animationModel in
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.toValue = 1.0
            animation.autoreverses = false
            animation.fillMode = kCAFillModeForwards
            if let customSpeed = customSpeed {
                animation.speed = customSpeed
            }
            animation.isRemovedOnCompletion = false
            animation.duration = customDuration ?? animationModel.duration
            animation.repeatCount = 1
            if textLayers.last == textLayer {
                animation.delegate = lastTextLayerDelegate
            }
            animation.beginTime = zeroTimeAnimation(animationDestination: animationDestination) + animationModel.beginTime
            textLayer.add(animation, forKey: "animateOpacity")
        }
    }
    
    func applyShowAndHideAnimation(animationDestination: AnimationDestination, textLayersArrayToApply textLayers: [CATextLayer], speechModelArray: [SpeechModel], lastTextLayerDelegate: CAAnimationDelegate? = nil) {
        applyRevealAnimation(animationDestination: animationDestination, textLayersArrayToApply: textLayers, speechModelArray: speechModelArray, customDuration: 0.0, customSpeed: 4.0)
        let animationModels = self.animationModels(speechModelArray: speechModelArray)
        zip(textLayers, animationModels).forEach { textLayer, animationModel in
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.toValue = 0.0
            animation.speed = 4.0
            animation.autoreverses = false
            animation.fillMode = kCAFillModeForwards
            animation.isRemovedOnCompletion = false
            animation.duration = 0.0
            animation.repeatCount = 1
            if textLayers.last == textLayer {
                animation.delegate = lastTextLayerDelegate
            }
            animation.beginTime = zeroTimeAnimation(animationDestination: animationDestination) + CFTimeInterval(animationModel.duration + animationModel.beginTime)
            textLayer.add(animation, forKey: "animateOpacityFadeOut")
        }
    }
    
    private func animationModels(speechModelArray: [SpeechModel]) -> [AnimationModel] {
        return speechModelArray.map { AnimationModel(beginTime: $0.timestamp, duration: $0.duration) }
    }
}
