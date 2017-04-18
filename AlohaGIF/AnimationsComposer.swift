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

struct AnimationsComposer {
    func applyRevealAnimation(textLayersArrayToApply textLayers: [CATextLayer], speechModelArray: [SpeechModel]) {
        let animationModels = self.animationModels(speechModelArray: speechModelArray)
        zip(textLayers, animationModels).forEach { textLayer, animationModel in
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.toValue = 1.0
            animation.autoreverses = false
            animation.fillMode = kCAFillModeForwards
            animation.isRemovedOnCompletion = false
            animation.duration = animationModel.duration
            animation.repeatCount = 1
            //IMPORTANT - Set animations’ beginTime property to AVCoreAnimationBeginTimeAtZero rather than 0 (which CoreAnimation replaces with CACurrentMediaTime)
            animation.beginTime = AVCoreAnimationBeginTimeAtZero + animationModel.beginTime
            textLayer.add(animation, forKey: "animateOpacity")
        }
    }
    
    func applyShowAndHideAnimation(textLayersArrayToApply textLayers: [CATextLayer]) {
    }
    
    private func animationModels(speechModelArray: [SpeechModel]) -> [AnimationModel] {
        return speechModelArray.map { AnimationModel(beginTime: $0.timestamp, duration: $0.duration) }
    }
}
