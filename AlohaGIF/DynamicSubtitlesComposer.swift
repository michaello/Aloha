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
var aScale: CGFloat = 1.0
var xOffset: CGFloat = 0.0
var yOffset: CGFloat = 0.0
var isRenderingVideo = false
var shouldAlwaysShowSubtitles = false

enum DynamicSubtitlesType {
    case oneAfterAnother
    case oneWordOnly
}

final class DynamicSubtitlesComposer {
    
    private enum Constants {
        static let multiplierForNewlineWithSomeSpace: CGFloat = 1.2
    }
    
    private var animationsComposer = AnimationsComposer()
    private let dynamicSubtitlesStyle: DynamicSubtitlesStyle
    private let dynamicSubtitlesContext: DynamicSubtitlesContext
    
    init(dynamicSubtitlesStyle: DynamicSubtitlesStyle = DynamicSubtitlesStyle.default, dynamicSubtitlesContext: DynamicSubtitlesContext) {
        self.dynamicSubtitlesStyle = dynamicSubtitlesStyle
        self.dynamicSubtitlesContext = dynamicSubtitlesContext
    }
    
    func applyDynamicSubtitles(speechArray: [SpeechModel], size: CGSize, startTime: Double = 0.0) {
        isRenderingVideo = dynamicSubtitlesContext.destination == .movie
        let overlayLayer = self.overlayLayer(size: size)
        let textLayers = self.textLayers(speechArray: speechArray, size: size, dynamicSubtitlesContext: dynamicSubtitlesContext)
        textLayers.forEach(overlayLayer.addSublayer)
        applyAnimations(animationDestination: dynamicSubtitlesContext.destination, textLayersArray: textLayers, speechModelArray: speechArray, dynamicSubtitlesType: self.dynamicSubtitlesStyle.effect, startTime: startTime)
        
        let (parentLayer, videoLayer) = parentAndVideoLayer(size: size)
        parentLayer.addSublayer(overlayLayer)
        switch dynamicSubtitlesContext {
        case .view(let view):
            view.layer.addSublayer(overlayLayer)
        case .videoComposition(let composition):
            composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        }
    }
    
    func textLayers(speechArray: [SpeechModel], size: CGSize, dynamicSubtitlesContext: DynamicSubtitlesContext) -> [CATextLayer] {
        var textLayersSizes = [CGFloat]()
        let offsetX = dynamicSubtitlesContext.destination == .movie ? xOffset : 0.0
        let offsetY = dynamicSubtitlesContext.destination == .movie ? yOffset : 0.0
        var designatedY = initialYPositionForTextLayers(speechArray: speechArray, size: size, dynamicSubtitlesContext: dynamicSubtitlesContext)
        return speechArray.map({ $0.content }).enumerated().map { index, text -> CATextLayer in
            let textLayer = self.textLayer(text: text)
            let currentSize = textRect(for: text)
            let xPosition = index == 0 ? (0.0 - offsetX) : textLayersSizes[index - 1]
            var currentOrigin = CGPoint(x: xPosition, y: size.height / 2.0)
            let isRequiringNewlineBreak = currentOrigin.x + currentSize.width > size.width
            currentOrigin.x = isRequiringNewlineBreak ? 0.0 : xPosition
            if isRequiringNewlineBreak {
                let heightWithSomeSpace = (-currentSize.height * Constants.multiplierForNewlineWithSomeSpace)
                let reversedHeightIfVideoRender = heightWithSomeSpace * (isRenderingVideo ? 1 : -1)
                designatedY = designatedY + reversedHeightIfVideoRender
            }
            currentOrigin.y = designatedY
            textLayer.frame = textLayerFrame(for: text, origin: currentOrigin, size: size, customOffsetPoint: CGPoint(x: offsetX, y: offsetY))
            let space = currentSize.width / CGFloat((text as String).characters.count)
            textLayersSizes.append(currentOrigin.x + currentSize.width + space)
            return textLayer
        }
    }
    
    private func textLayerFrame(for text: String, origin: CGPoint, size: CGSize, customOffsetPoint: CGPoint) -> CGRect {
        let textTect = textRect(for: text)
        switch dynamicSubtitlesStyle.effect {
        case .oneWordOnly:
            return centerFrameForTextLayer(textLayerSize: textTect, movieSize: size).offsetBy(dx: -customOffsetPoint.x, dy: customOffsetPoint.y)
        case .oneAfterAnother:
            let centerFrame = centerFrameForTextLayer(textLayerSize: textTect, movieSize: size)
            let centerHeight = centerFrame.size.height
            var offset = -centerFrame.origin.y + centerHeight
            offset = isRenderingVideo ? -offset : offset
            return CGRect(origin: origin, size: textTect).offsetBy(dx: 0.0, dy: offset)
        }
    }
    
    private func initialYPositionForTextLayers(speechArray: [SpeechModel], size: CGSize, dynamicSubtitlesContext: DynamicSubtitlesContext) -> CGFloat {
        let offsetY = dynamicSubtitlesContext != .view(UIView()) ? xOffset : 0.0
        let wholeTextContent = speechArray.asSentence
        let estimatedNumberOfLines = round(textRect(for: wholeTextContent).width / size.width) + 1.0
        let textRectHeight = textRect(for: wholeTextContent).height
        
        switch dynamicSubtitlesContext {
        case .videoComposition:
            return (textRectHeight * (estimatedNumberOfLines - 1.0) * Constants.multiplierForNewlineWithSomeSpace) + offsetY
        case .view:
            return size.height - (textRectHeight * estimatedNumberOfLines * Constants.multiplierForNewlineWithSomeSpace) + offsetY
        }
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

extension Array where Element == SpeechModel {
    
    var asSentence: String {
        return reduce("") { $0 + " " + $1.content }
    }
}
