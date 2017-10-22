//
//  DynamicSubtitlesComposer.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 18/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import AVFoundation
import UIKit

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
        SharedVariables.isRenderingVideo = dynamicSubtitlesContext.destination == .movie
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
        let offsetX = dynamicSubtitlesContext.destination == .movie ? SharedVariables.xOffset : 0.0
        let offsetY = dynamicSubtitlesContext.destination == .movie ? SharedVariables.yOffset : 0.0
        var designatedY = initialYPositionForTextLayers(speechArray: speechArray, size: size, dynamicSubtitlesContext: dynamicSubtitlesContext)
        let enumeratedSpeechToText = speechArray.map({ $0.content }).enumerated()
        return enumeratedSpeechToText.map { index, text -> CATextLayer in
            let currentSize = textRect(for: text)
            let xPosition = index == 0 ? (0.0 - offsetX) : textLayersSizes[index - 1]
            var currentOrigin = CGPoint(x: xPosition, y: size.height / 2.0)
            let isRequiringNewlineBreak = currentOrigin.x + currentSize.width > size.width
            currentOrigin.x = isRequiringNewlineBreak ? 0.0 : xPosition
            if isRequiringNewlineBreak {
                let heightWithSomeSpace = (-currentSize.height * Constants.multiplierForNewlineWithSomeSpace)
                let reversedHeightIfVideoRender = heightWithSomeSpace * (SharedVariables.isRenderingVideo ? 1 : -1)
                designatedY = designatedY + reversedHeightIfVideoRender
            }
            currentOrigin.y = designatedY
            let space = currentSize.width / CGFloat(text.characters.count)
            textLayersSizes.append(currentOrigin.x + currentSize.width + space)
            let finalTextLayerFrame = textLayerFrame(for: text, origin: currentOrigin, size: size, customOffsetPoint: CGPoint(x: offsetX, y: offsetY))
            return self.textLayer(text: text, frame: finalTextLayerFrame)
        }
    }
    
    private func textLayerFrame(for text: String, origin: CGPoint, size: CGSize, customOffsetPoint: CGPoint) -> CGRect {
        let textRect = self.textRect(for: text)
        switch dynamicSubtitlesStyle.effect {
        case .oneWordOnly:
            return centerFrameForTextLayer(textLayerSize: textRect, movieSize: size).offsetBy(dx: -customOffsetPoint.x, dy: customOffsetPoint.y)
        case .oneAfterAnother:
            let centerFrame = centerFrameForTextLayer(textLayerSize: textRect, movieSize: size)
            let centerHeight = centerFrame.size.height
            var offset = -centerFrame.origin.y + centerHeight
            offset = SharedVariables.isRenderingVideo ? -offset : offset
            return CGRect(origin: origin, size: textRect).offsetBy(dx: 0.0, dy: offset)
        }
    }
    
    private func initialYPositionForTextLayers(speechArray: [SpeechModel], size: CGSize, dynamicSubtitlesContext: DynamicSubtitlesContext) -> CGFloat {
        let offsetY = dynamicSubtitlesContext != .view(UIView()) ? SharedVariables.xOffset : 0.0
        let wholeTextContent = speechArray.asSentence
        
        let estimatedNumberOfLines = (textRect(for: wholeTextContent).width / size.width).rounded(.up)
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
        let centerPoint = CGPoint(x: halfWidth - halfTextWidth, y: halfHeight - halfTextHeight)

        return CGRect(origin: centerPoint, size: textLayerSize)
    }
    
    private func textRect(for text: String = "Whatever") -> CGSize {
        return (text as NSString).size(attributes: dynamicSubtitlesStyle.textAttributes)
    }
    
    private func textLayer(text: String, frame: CGRect) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.opacity = SharedVariables.shouldAlwaysShowSubtitles ? 1.0 : 0.0
        textLayer.alignmentMode = kCAAlignmentLeft
        textLayer.string = NSAttributedString(string: text, attributes: dynamicSubtitlesStyle.textAttributes)
        textLayer.frame = frame
        
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
