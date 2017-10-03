//
//  DynamicSubtitlesComposer.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 18/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import AVFoundation
import UIKit

//TODO: Clear global flags
var isRenderingVideo = false
var aScale: CGFloat = 1.0
var aOffsetX: CGFloat = 0.0
var aOffsetY: CGFloat = 0.0
var shouldAlwaysShowSubtitles = false

enum DynamicSubtitlesType {
    case oneAfterAnother
    case oneWordOnly
}

enum AnimationDestination {
    case preview
    case movie
}

enum DynamicSubtitlesContext {
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
}


final class DynamicSubtitlesComposer {
    
    private var animationsComposer = AnimationsComposer()
    private var dynamicSubtitlesStyle = DynamicSubtitlesStyle.default
    
    func applyDynamicSubtitles(to dynamicSubtitlesContext: DynamicSubtitlesContext, speechArray: [SpeechModel?], dynamicSubtitlesStyle: DynamicSubtitlesStyle? = nil, size: CGSize, startTime: Double = 0.0) {
        Logger.debug("Will begin applying dynamic subtitles to movie...")
        if let style = dynamicSubtitlesStyle {
            self.dynamicSubtitlesStyle = style
        }
        if case .videoComposition = dynamicSubtitlesContext {
            isRenderingVideo = true
        } else {
            isRenderingVideo = false
        }
        let overlayLayer = self.overlayLayer(size: size)
        let array = speechArray.flatMap { $0 }
        let textLayers = self.textLayers(speechArray: array, size: size, dynamicSubtitlesContext: dynamicSubtitlesContext)
        textLayers.forEach { overlayLayer.addSublayer($0) }
        applyAnimations(animationDestination: dynamicSubtitlesContext.destination, textLayersArray: textLayers, speechModelArray: array, dynamicSubtitlesType: self.dynamicSubtitlesStyle.effect, startTime: startTime)
        
        let layers = parentAndVideoLayer(size: size)
        let parentLayer = layers.0
        let videoLayer = layers.1
        parentLayer.addSublayer(overlayLayer)
        switch dynamicSubtitlesContext {
        case .view(let view):
            view.layer.addSublayer(overlayLayer)
        case .videoComposition(let composition):
            composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        }
    }
    
    func textLayers(speechArray: [SpeechModel], size: CGSize, dynamicSubtitlesContext: DynamicSubtitlesContext) -> [CATextLayer] {
        let textArray = speechArray.map { $0.content }
        var textLayersArray = [CATextLayer]()
        var textLayersSizes = [CGFloat]()
        let offsetX: CGFloat
        let offsetY: CGFloat
        if case .videoComposition = dynamicSubtitlesContext {
            offsetX = aOffsetX
            offsetY = aOffsetY
        } else {
            offsetX = 0.0
            offsetY = 0.0
        }
        
        //TODO: Refactor it, big pile of mess
        var designatedY: CGFloat
        var designatedX: CGFloat = 0.0
        let wholeTextContent = speechArray.reduce("") { $0 + " " + $1.content }
        let estimatedNumberOfLines = round(textRect(for: wholeTextContent).width / size.width) + 1.0
        let multiplierForNewlineWithSomeSpace: CGFloat = 1.2
        
        if isRenderingVideo {
            designatedY = (textRect(for: wholeTextContent).height * (estimatedNumberOfLines - 1.0) * multiplierForNewlineWithSomeSpace) + offsetY
        } else {
            designatedY = size.height - (textRect(for: wholeTextContent).height * estimatedNumberOfLines * multiplierForNewlineWithSomeSpace) + offsetY
        }
        let layers = textArray.enumerated().map { index, text -> CATextLayer in
            let textLayer = self.textLayer(text: text)
            let currentSize = textRect(for: text)
            var currentOrigin = index == 0 ? CGPoint(x: 0.0 - offsetX, y: size.height / 2) : CGPoint(x: textLayersSizes[index - 1], y: size.height / 2)
            //New line if needed
            if currentOrigin.x + currentSize.width > size.width {
                if isRenderingVideo {
                    designatedY = designatedY + (-currentSize.height * multiplierForNewlineWithSomeSpace)
                } else {
                    designatedY = designatedY - (-currentSize.height * multiplierForNewlineWithSomeSpace)
                }
                designatedX = 0.0
                currentOrigin.x = designatedX
            }
            currentOrigin.y = designatedY
            if case .oneWordOnly = dynamicSubtitlesStyle.effect {
                textLayer.frame = centerFrameForTextLayer(textLayerSize: currentSize, movieSize: size)
                textLayer.frame = textLayer.frame.offsetBy(dx: -offsetX, dy: offsetY)
            } else {
                let centerFrame = centerFrameForTextLayer(textLayerSize: currentSize, movieSize: size)
                let centerHeight = centerFrame.size.height
                var offset = -centerFrame.origin.y + centerHeight
                offset = isRenderingVideo ? -offset : offset
                textLayer.frame = CGRect(origin: currentOrigin, size: currentSize).offsetBy(dx: 0.0, dy: offset)
            }
            textLayersArray.append(textLayer)
            let space = currentSize.width / CGFloat((text as String).characters.count)
            textLayersSizes.append(currentOrigin.x + currentSize.width + space)
            
            return textLayer
        }
        return layers
    }
    
    private func applyAnimations(animationDestination: AnimationDestination, textLayersArray: [CATextLayer], speechModelArray: [SpeechModel], dynamicSubtitlesType: DynamicSubtitlesType, startTime: Double) {
        animationsComposer.startTime = startTime
        if case .oneAfterAnother = dynamicSubtitlesType {
            animationsComposer.applyRevealAnimation(animationDestination: animationDestination, textLayersArrayToApply: textLayersArray, speechModelArray: speechModelArray)
        } else {
            animationsComposer.applyShowAndHideAnimation(animationDestination: animationDestination, textLayersArrayToApply: textLayersArray, speechModelArray: speechModelArray)
        }
    }
    
    private func centerFrameForTextLayer(textLayerSize: CGSize, movieSize: CGSize) -> CGRect {
        let halfWidth = movieSize.width / 2.0
        let halfHeight = movieSize.height / 2.0
        let halfTextWidth = textLayerSize.width / 2.0
        let halfTextHeight = textLayerSize.height / 2.0

        return CGRect(origin: CGPoint(x: halfWidth - halfTextWidth, y: halfHeight - halfTextHeight), size: textLayerSize)
    }
    
    private func textRect(for text: String = "Whatever") -> CGSize {
        return (text as NSString).size(attributes: dynamicSubtitlesStyle.textAttributes)
    }
    
    private func textLayer(text: String) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.opacity = shouldAlwaysShowSubtitles ? 1.0 : 0.0
        textLayer.alignmentMode = kCAAlignmentLeft
        textLayer.string = NSAttributedString(string: text, attributes: dynamicSubtitlesStyle.textAttributes)
        
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
        layer.masksToBounds = false
        
        return layer
    }
}
