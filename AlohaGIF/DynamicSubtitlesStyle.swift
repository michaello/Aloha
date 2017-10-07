//
//  DynamicSubtitlesStyle.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 24/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit

struct DynamicSubtitlesStyle {
    
    private enum Constants {
        static let fontMultiplierForOneAfterAnotherStyle: CGFloat = 24.0
        static let fontMultiplierForOneWordOnlyStyle: CGFloat = 48.0
        static let multiplierForRenderingVideo: CGFloat = 1.5
    }
    
    let effect: DynamicSubtitlesType
    let font: UIFont
    let color: UIColor
    
    func font(forRenderingVideo logicValue: Bool) -> UIFont {
        var fontSize = effect == .oneAfterAnother ? Constants.fontMultiplierForOneAfterAnotherStyle : Constants.fontMultiplierForOneWordOnlyStyle
        fontSize = logicValue ? (fontSize * Constants.multiplierForRenderingVideo) : (fontSize / aScale)
        
        return font.withSize(fontSize)
    }
    
    var textAttributes: [String : Any] {
        return [
            NSStrokeWidthAttributeName : -2.0,
            NSStrokeColorAttributeName : UIColor.black,
            NSFontAttributeName : font(forRenderingVideo: isRenderingVideo),
            NSForegroundColorAttributeName : color
        ]
    }
}

extension DynamicSubtitlesStyle {
    static let `default` = DynamicSubtitlesStyle(effect: DynamicSubtitlesType.oneAfterAnother, font: UIFont.boldSystemFont(ofSize: 16.0), color: .white)
}
