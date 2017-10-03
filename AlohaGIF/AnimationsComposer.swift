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
    var finishTime: TimeInterval {
        return beginTime + duration
    }
}

struct AnimationsComposer {
    
    var startTime = 0.0
    
    func zeroTimeAnimation(animationDestination: AnimationDestination) -> CFTimeInterval {
        return animationDestination == .preview ? CACurrentMediaTime() : AVCoreAnimationBeginTimeAtZero
    }

    func applyRevealAnimation(animationDestination: AnimationDestination, textLayersArrayToApply textLayers: [CATextLayer], speechModelArray: [SpeechModel], customDuration: TimeInterval? = nil, customSpeed: Float? = nil) {
        let animationModels = self.animationModels(speechModelArray: speechModelArray)
        let zippedArraysWithStartTime = zipped(textLayers: textLayers, animationModelArray: animationModels)
        zip(zippedArraysWithStartTime.0, zippedArraysWithStartTime.1).forEach { textLayer, animationModel in
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
            animation.beginTime = zeroTimeAnimation(animationDestination: animationDestination) + CFTimeInterval(animationModel.finishTime)
            textLayer.add(animation, forKey: "animateOpacityFadeOut")
        }
    }
    
    private func animationModels(speechModelArray: [SpeechModel]) -> [AnimationModel] {
        return speechModelArray.map { AnimationModel(beginTime: $0.timestamp - startTime, duration: $0.duration) }
    }
    
    //Function for applying opacity animation for custom start time.
    private func zipped(textLayers: [CATextLayer], animationModelArray: [AnimationModel]) -> ([CATextLayer], [AnimationModel]) {
        guard textLayers.count == animationModelArray.count else {
            Logger.error("Warning: SpeechModels and TextLayers count don't match.")
            return (textLayers, animationModelArray)
        }
        guard startTime != 0.0 else { return (textLayers, animationModelArray) }
        let animationModelsAfterStartTime = animationModelArray
            .sorted { lhs, rhs in lhs.beginTime < rhs.beginTime }
            .filter { $0.beginTime > startTime }
        let firstAnimationModelAfterStartTime = animationModelsAfterStartTime.first
        guard let first = firstAnimationModelAfterStartTime, let index = animationModelArray.index(where: { $0.beginTime == first.beginTime }), index > 0 else {
            return (textLayers, animationModelArray)
        }
        var safeTextLayers = [CATextLayer]()
        var safeAnimationArray = [AnimationModel]()
        textLayers[0..<index].forEach { $0.opacity = 1.0 }
        for i in index..<animationModelArray.count {
            safeTextLayers.append(textLayers[i])
            safeAnimationArray.append(animationModelArray[i])
        }
        
        return (safeTextLayers, safeAnimationArray)
    }
}
