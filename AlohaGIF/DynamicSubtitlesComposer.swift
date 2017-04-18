//
//  DynamicSubtitlesComposer.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 18/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

enum DynamicSubtitlesType {
    case oneAfterAnother
    case oneWordOnly
    
    var font: UIFont {
        let multiplier = self == .oneAfterAnother ? 6.0 : 12.0
        let fontSize: CGFloat = 10.0 * CGFloat(multiplier)
        let font = UIFont.boldSystemFont(ofSize: fontSize)
        
        return font
    }
    
    var textAttributes: [String : Any] {
        return [
            NSStrokeWidthAttributeName : -2.0,
            NSStrokeColorAttributeName : UIColor.black,
            NSFontAttributeName : font,
            NSForegroundColorAttributeName : UIColor.white
        ]
    }
}

struct DynamicSubtitlesComposer {
    
    private let dynamicSubtitlesType = DynamicSubtitlesType.oneWordOnly
    private let animationsComposer = AnimationsComposer()
    
    func applyChangingText(to compostion: AVMutableVideoComposition, speechArray: [SpeechModel?], size: CGSize) {
        Logger.debug("Will begin applying dynamic fonts to movie...")
        let overlayLayer = self.overlayLayer(size: size)
        let array = speechArray.flatMap { $0 }
        textLayers(speechArray: array, size: size).forEach {
            overlayLayer.addSublayer($0)
        }
        
        let layers = parentAndVideoLayer(size: size)
        let parentLayer = layers.0
        let videoLayer = layers.1
        parentLayer.addSublayer(overlayLayer)
        compostion.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
    }
    
    func textLayers(speechArray: [SpeechModel], size: CGSize) -> [CATextLayer] {
        let textArray = speechArray.map { $0.content }
        var textLayersArray = [CATextLayer]()
        var textLayersSizes = [CGFloat]()
        
        var designatedY: CGFloat = size.height - textRect().height
        var designatedX: CGFloat = 0.0
        let layers = textArray.enumerated().map { index, text -> CATextLayer in
            let textLayer = self.textLayer(text: text)
            let currentSize = textRect(for: text)
            var currentOrigin = index == 0 ? CGPoint(x: 0.0, y: size.height) : CGPoint(x: textLayersSizes[index - 1], y: size.height)
            //New line if needed
            if currentOrigin.x + currentSize.width > size.width {
                designatedY = designatedY + (-currentSize.height * 1.2)
                designatedX = 0.0
                currentOrigin.x = designatedX
            }
            currentOrigin.y = designatedY
            if case .oneWordOnly = dynamicSubtitlesType {
                textLayer.frame = centerFrameForTextLayer(textLayerSize: currentSize, movieSize: size)
            } else {
                textLayer.frame = CGRect(origin: currentOrigin, size: currentSize)
            }
            textLayersArray.append(textLayer)
            let space = currentSize.width / CGFloat((text as String).characters.count)
            textLayersSizes.append(currentOrigin.x + currentSize.width + space)
            
            return textLayer
        }
        
        if case .oneAfterAnother = dynamicSubtitlesType {
            animationsComposer.applyRevealAnimation(textLayersArrayToApply: textLayersArray, speechModelArray: speechArray)
        } else {
            animationsComposer.applyShowAndHideAnimation(textLayersArrayToApply: textLayersArray, speechModelArray: speechArray)
        }
        
        return layers
    }
    
    private func centerFrameForTextLayer(textLayerSize: CGSize, movieSize: CGSize) -> CGRect {
        let halfWidth = movieSize.width / 2
        let halfHeight = movieSize.height / 2
        let halfTextWidth = textLayerSize.width / 2
        let halfTextHeight = textLayerSize.height / 2

        return CGRect(origin: CGPoint(x: halfWidth - halfTextWidth, y: halfHeight - halfTextHeight), size: textLayerSize)
    }
    
    private func textRect(for text: String = "Whatever") -> CGSize {
        return (text as NSString).size(attributes: dynamicSubtitlesType.textAttributes)
    }
    
    private func textLayer(text: String) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.opacity = 0.0
        textLayer.alignmentMode = kCAAlignmentLeft
        textLayer.string = NSAttributedString(string: text, attributes: dynamicSubtitlesType.textAttributes)
        
        return textLayer
    }
    
    private func parentAndVideoLayer(size: CGSize) -> (CALayer, CALayer) {
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: size)
        videoLayer.frame = CGRect(origin: .zero, size: size)
        parentLayer.addSublayer(videoLayer)
        
        return (parentLayer, videoLayer)
    }
    
    private func overlayLayer(size: CGSize) -> CALayer {
        let layer = CALayer()
        layer.frame = CGRect(origin: .zero, size: size)
        layer.masksToBounds = true
        
        return layer
    }
}
